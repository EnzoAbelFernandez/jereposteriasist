-- =============================================================================
-- 0100 BASE: utilidades, configuración, perfiles, permisos y funciones de acceso
-- =============================================================================
-- Convenciones (ver docs/modelo-de-datos.md):
--   * Todas las tablas sincronizadas tienen `id uuid` generado por el cliente.
--   * Valores tipo "enum" = text + CHECK (más fácil de evolucionar y PowerSync los ve como texto).
--   * Dinero = bigint en CENTAVOS. Cantidades de insumos = bigint en unidad base (g, ml, u).
--   * Sin booleanos escritos por el cliente (SQLite los guarda como 0/1). Se usan fechas
--     nulables (`archivado_en`) o text.
--   * Sin UNIQUE sobre datos que escribe el usuario: un conflicto offline haría perder el registro.
-- =============================================================================

-- ---------- Utilidades ----------

create or replace function public.hoy_ar()
returns date language sql stable as $$
  select (now() at time zone 'America/Argentina/Buenos_Aires')::date
$$;

create or replace function public.nivel_a_numero(p_nivel text)
returns int language sql immutable as $$
  select case p_nivel when 'ver' then 1 when 'cargar' then 2 when 'editar' then 3 else 0 end
$$;

-- Mantiene actualizado_en.
create or replace function public.tg_actualizado_en()
returns trigger language plpgsql as $$
begin
  new.actualizado_en := now();
  return new;
end $$;

-- Fija creado_por (no falsificable) y protege creado_en/creado_por en updates.
create or replace function public.tg_campos_control()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null then
      new.creado_por := auth.uid();
    end if;
    if new.creado_en is null then
      new.creado_en := now();
    end if;
  else
    new.creado_por := old.creado_por;
    new.creado_en := old.creado_en;
  end if;
  return new;
end $$;

-- ---------- Configuración (fila única) ----------

create table public.configuracion (
  id uuid primary key default gen_random_uuid(),
  unica text not null default 'si' unique check (unica = 'si'),
  nombre_negocio text not null default 'Mi repostería',
  dias_aviso_cumple int not null default 7 check (dias_aviso_cumple between 1 and 60),
  -- 'todos' = avisa cumpleaños de todos los clientes; 'habituales' = solo habituales
  aviso_cumple_alcance text not null default 'todos' check (aviso_cumple_alcance in ('todos', 'habituales')),
  habitual_min_pedidos int not null default 3 check (habitual_min_pedidos >= 1),
  habitual_meses int not null default 12 check (habitual_meses between 1 and 60),
  actualizado_en timestamptz not null default now()
);
create trigger configuracion_actualizado before update on public.configuracion
  for each row execute function public.tg_actualizado_en();

insert into public.configuracion default values;

-- ---------- Perfiles (1 a 1 con auth.users) ----------

create table public.perfiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nombre text not null check (length(trim(nombre)) > 0),
  rol text not null default 'empleado' check (rol in ('jefe', 'empleado')),
  telefono text,
  activo boolean not null default true, -- solo lo cambia el jefe vía Edge Function (online)
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);
create trigger perfiles_actualizado before update on public.perfiles
  for each row execute function public.tg_actualizado_en();

-- ---------- Permisos por módulo ----------
-- Módulos: clientes, pedidos, catalogo, stock, compras, produccion, gastos, caja, reportes.
-- Niveles: ninguno < ver < cargar < editar. El jefe tiene siempre 'editar' en todo.
-- Las tareas y alertas NO son módulos: cada uno ve las suyas; el jefe ve todas las tareas.

create table public.permisos (
  id uuid primary key default gen_random_uuid(),
  perfil_id uuid not null references public.perfiles (id) on delete cascade,
  modulo text not null check (modulo in (
    'clientes', 'pedidos', 'catalogo', 'stock', 'compras', 'produccion', 'gastos', 'caja', 'reportes'
  )),
  nivel text not null default 'ninguno' check (nivel in ('ninguno', 'ver', 'cargar', 'editar')),
  actualizado_en timestamptz not null default now(),
  unique (perfil_id, modulo) -- filas creadas solo por el servidor
);
create index permisos_perfil_idx on public.permisos (perfil_id);
create trigger permisos_actualizado before update on public.permisos
  for each row execute function public.tg_actualizado_en();

-- ---------- Funciones de acceso (usadas por RLS) ----------

create or replace function public.es_jefe()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from perfiles where id = auth.uid() and rol = 'jefe' and activo
  )
$$;

create or replace function public.tiene_permiso(p_modulo text, p_nivel text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from permisos pe
    join perfiles pf on pf.id = pe.perfil_id
    where pe.perfil_id = auth.uid()
      and pf.activo
      and pe.modulo = p_modulo
      and nivel_a_numero(pe.nivel) >= nivel_a_numero(p_nivel)
  )
$$;

-- Usuarios activos con al menos 'ver' en alguno de los módulos (destinatarios de alertas).
create or replace function public.destinatarios_modulos(p_modulos text[])
returns setof uuid language sql stable security definer set search_path = public as $$
  select distinct pe.perfil_id
  from permisos pe
  join perfiles pf on pf.id = pe.perfil_id
  where pf.activo
    and pe.modulo = any (p_modulos)
    and pe.nivel <> 'ninguno'
$$;

-- ---------- Alta automática de perfil al crear un usuario de Auth ----------
-- El PRIMER usuario creado pasa a ser 'jefe'. Los demás, 'empleado' sin permisos.
-- IMPORTANTE: desactivar el registro público en Supabase (Auth > Sign In / Providers).

create or replace function public.manejar_nuevo_usuario()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_rol text;
begin
  v_rol := case when exists (select 1 from perfiles where rol = 'jefe') then 'empleado' else 'jefe' end;
  insert into perfiles (id, nombre, rol)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'nombre'), ''), split_part(new.email, '@', 1)),
    v_rol
  );
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.manejar_nuevo_usuario();

-- Crea las 9 filas de permisos de cada perfil nuevo.
create or replace function public.tg_perfil_crear_permisos()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into permisos (perfil_id, modulo, nivel)
  select new.id, m, case when new.rol = 'jefe' then 'editar' else 'ninguno' end
  from unnest(array['clientes', 'pedidos', 'catalogo', 'stock', 'compras', 'produccion', 'gastos', 'caja', 'reportes']) m
  on conflict (perfil_id, modulo) do nothing;
  return null;
end $$;

create trigger perfiles_crear_permisos
  after insert on public.perfiles
  for each row execute function public.tg_perfil_crear_permisos();

-- Reglas de perfiles:
--  * Nadie cambia su propio rol ni su propio estado activo.
--  * Solo el jefe cambia rol/activo de otros (además la RLS solo deja actualizar al jefe o a uno mismo).
--  * No se puede dejar el sistema sin jefe activo.
create or replace function public.tg_perfiles_guardia()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    return new; -- servidor / service role
  end if;
  if (new.rol is distinct from old.rol or new.activo is distinct from old.activo) then
    if old.id = auth.uid() then
      raise exception 'No podés cambiar tu propio rol ni desactivarte' using errcode = 'P0001';
    end if;
    if not es_jefe() then
      raise exception 'Solo el jefe puede cambiar roles o desactivar usuarios' using errcode = 'P0001';
    end if;
  end if;
  return new;
end $$;

create trigger perfiles_guardia before update on public.perfiles
  for each row execute function public.tg_perfiles_guardia();

-- Sincroniza permisos al cambiar rol o activo.
create or replace function public.tg_perfiles_sync_permisos()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.rol = 'jefe' and new.activo then
    update permisos set nivel = 'editar' where perfil_id = new.id and nivel <> 'editar';
  elsif not new.activo or (old.rol = 'jefe' and new.rol = 'empleado') then
    update permisos set nivel = 'ninguno' where perfil_id = new.id and nivel <> 'ninguno';
  end if;
  return null;
end $$;

create trigger perfiles_sync_permisos
  after update of rol, activo on public.perfiles
  for each row execute function public.tg_perfiles_sync_permisos();

-- El jefe siempre conserva 'editar'; modulo y perfil no se cambian.
create or replace function public.tg_permisos_guardia()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.perfil_id := old.perfil_id;
  new.modulo := old.modulo;
  if exists (select 1 from perfiles where id = new.perfil_id and rol = 'jefe' and activo) then
    new.nivel := 'editar';
  end if;
  if exists (select 1 from perfiles where id = new.perfil_id and not activo) then
    new.nivel := 'ninguno';
  end if;
  return new;
end $$;

create trigger permisos_guardia before update on public.permisos
  for each row execute function public.tg_permisos_guardia();
