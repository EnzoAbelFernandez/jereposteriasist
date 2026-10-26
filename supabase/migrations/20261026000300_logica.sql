-- =============================================================================
-- 0300 LÓGICA: triggers de control, guardias, anulaciones, cliente habitual, alertas
-- =============================================================================

-- ---------- Campos de control (creado_por / creado_en / actualizado_en) ----------
do $$
declare
  t text;
begin
  -- Tablas con creado_por + creado_en
  foreach t in array array[
    'clientes', 'proveedores', 'insumos', 'productos', 'recetas', 'pedidos', 'compras',
    'categorias_gasto', 'gastos', 'producciones', 'movimientos_stock', 'movimientos_caja', 'tareas'
  ] loop
    execute format(
      'create trigger %1$s_campos_control before insert or update on public.%1$I
         for each row execute function public.tg_campos_control()', t);
  end loop;

  -- Tablas con actualizado_en
  foreach t in array array[
    'clientes', 'proveedores', 'insumos', 'productos', 'recetas', 'receta_items', 'pedidos',
    'pedido_items', 'compras', 'categorias_gasto', 'gastos', 'producciones', 'tareas'
  ] loop
    execute format(
      'create trigger %1$s_actualizado before update on public.%1$I
         for each row execute function public.tg_actualizado_en()', t);
  end loop;
end $$;

-- ---------- Auditoría ----------
create or replace function public.tg_auditoria()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into auditoria (tabla, registro_id, accion, usuario_id, antes, despues)
  values (
    tg_table_name,
    case when tg_op = 'DELETE' then old.id else new.id end,
    tg_op,
    auth.uid(),
    case when tg_op <> 'INSERT' then to_jsonb(old) end,
    case when tg_op <> 'DELETE' then to_jsonb(new) end
  );
  return null;
end $$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'clientes', 'proveedores', 'insumos', 'productos', 'recetas', 'receta_items', 'pedidos',
    'pedido_items', 'compras', 'compra_items', 'categorias_gasto', 'gastos', 'producciones',
    'movimientos_stock', 'movimientos_caja', 'tareas', 'perfiles', 'permisos', 'configuracion'
  ] loop
    execute format(
      'create trigger %1$s_auditoria after insert or update or delete on public.%1$I
         for each row execute function public.tg_auditoria()', t);
  end loop;
end $$;

-- ---------- Documentos anulables: compras, gastos, producciones ----------
-- Una vez registrados solo se puede: pasar a 'anulado' (con anulado_en / motivo) o editar notas.
create or replace function public.tg_documento_anulable()
returns trigger language plpgsql as $$
declare
  v_libres text[] := array['estado', 'anulado_en', 'motivo_anulacion', 'notas', 'actualizado_en', 'creado_por', 'creado_en'];
begin
  if old.estado = 'anulado' then
    raise exception 'El registro está anulado y no se puede modificar' using errcode = 'P0001';
  end if;
  if (to_jsonb(new) - v_libres) is distinct from (to_jsonb(old) - v_libres) then
    raise exception 'Un registro confirmado no se puede editar: anulalo y cargalo de nuevo' using errcode = 'P0001';
  end if;
  if new.estado = 'anulado' and new.anulado_en is null then
    new.anulado_en := now();
  end if;
  return new;
end $$;

create trigger compras_anulable before update on public.compras
  for each row execute function public.tg_documento_anulable();
create trigger gastos_anulable before update on public.gastos
  for each row execute function public.tg_documento_anulable();
create trigger producciones_anulable before update on public.producciones
  for each row execute function public.tg_documento_anulable();

-- compra_items no se modifican nunca (la RLS tampoco lo permite; esto cubre al service role).
create or replace function public.tg_inmutable()
returns trigger language plpgsql as $$
begin
  raise exception 'Los registros de % no se pueden modificar ni borrar', tg_table_name using errcode = 'P0001';
end $$;

create trigger compra_items_inmutable before update or delete on public.compra_items
  for each row execute function public.tg_inmutable();
create trigger movimientos_stock_inmutable before update or delete on public.movimientos_stock
  for each row execute function public.tg_inmutable();
create trigger movimientos_caja_inmutable before update or delete on public.movimientos_caja
  for each row execute function public.tg_inmutable();

-- ---------- Anulaciones en los libros ----------
-- El servidor recalcula los valores de la anulación a partir del movimiento original,
-- así un cliente con datos viejos no puede dejar el libro inconsistente.
create or replace function public.tg_mov_stock_antes()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  o movimientos_stock;
begin
  if new.tipo = 'anulacion' then
    select * into o from movimientos_stock where id = new.anula_id;
    if not found then
      raise exception 'El movimiento a anular no existe' using errcode = 'P0001';
    end if;
    if o.tipo = 'anulacion' then
      raise exception 'No se puede anular una anulación' using errcode = 'P0001';
    end if;
    new.insumo_id := o.insumo_id;
    new.cantidad := -o.cantidad;
    new.compra_id := o.compra_id;
    new.produccion_id := o.produccion_id;
  end if;
  return new;
end $$;

create trigger movimientos_stock_antes before insert on public.movimientos_stock
  for each row execute function public.tg_mov_stock_antes();

create or replace function public.tg_mov_caja_antes()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  o movimientos_caja;
begin
  if new.concepto = 'anulacion' then
    select * into o from movimientos_caja where id = new.anula_id;
    if not found then
      raise exception 'El movimiento a anular no existe' using errcode = 'P0001';
    end if;
    if o.concepto = 'anulacion' then
      raise exception 'No se puede anular una anulación' using errcode = 'P0001';
    end if;
    new.tipo := case when o.tipo = 'ingreso' then 'egreso' else 'ingreso' end;
    new.monto_centavos := o.monto_centavos;
    new.medio_pago := o.medio_pago;
    new.pedido_id := o.pedido_id;
    new.compra_id := o.compra_id;
    new.gasto_id := o.gasto_id;
  end if;
  return new;
end $$;

create trigger movimientos_caja_antes before insert on public.movimientos_caja
  for each row execute function public.tg_mov_caja_antes();

-- ---------- Pedidos ----------
-- * Fija entregado_en / cancelado_en.
-- * El número no se modifica.
-- * Quien NO tiene pedidos:editar (p. ej. producción) solo puede pasar el estado a en_produccion / listo.
create or replace function public.tg_pedidos_guardia()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_libres text[] := array['estado', 'actualizado_en', 'entregado_en', 'cancelado_en'];
begin
  if new.estado = 'entregado' and new.entregado_en is null then
    new.entregado_en := now();
  end if;
  if new.estado = 'cancelado' and new.cancelado_en is null then
    new.cancelado_en := now();
  end if;

  if tg_op = 'UPDATE' then
    new.numero := old.numero;
    if auth.uid() is not null and not tiene_permiso('pedidos', 'editar') then
      if (to_jsonb(new) - v_libres) is distinct from (to_jsonb(old) - v_libres)
         or new.estado not in ('en_produccion', 'listo') then
        raise exception 'Solo podés cambiar el estado a "En producción" o "Listo"' using errcode = 'P0001';
      end if;
    end if;
  end if;
  return new;
end $$;

create trigger pedidos_guardia before insert or update on public.pedidos
  for each row execute function public.tg_pedidos_guardia();

-- ---------- Clientes: habitual_auto solo lo escribe el servidor ----------
create or replace function public.tg_clientes_guardia()
returns trigger language plpgsql as $$
begin
  if coalesce(current_setting('app.sistema', true), '') <> 'on' then
    if tg_op = 'INSERT' then
      new.habitual_auto := false;
    else
      new.habitual_auto := old.habitual_auto;
    end if;
  end if;
  return new;
end $$;

create trigger clientes_guardia before insert or update on public.clientes
  for each row execute function public.tg_clientes_guardia();

-- Cliente habitual (automático): >= habitual_min_pedidos pedidos ENTREGADOS en los últimos habitual_meses.
create or replace function public.recalcular_habitual(p_cliente uuid default null)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_min int;
  v_meses int;
begin
  select habitual_min_pedidos, habitual_meses into v_min, v_meses from configuracion limit 1;
  v_min := coalesce(v_min, 3);
  v_meses := coalesce(v_meses, 12);

  perform set_config('app.sistema', 'on', true);

  update clientes c
  set habitual_auto = sub.es_habitual
  from (
    select c2.id,
      (select count(*) from pedidos p
        where p.cliente_id = c2.id
          and p.estado = 'entregado'
          and coalesce(p.entregado_en, p.fecha_entrega) >= now() - make_interval(months => v_meses)
      ) >= v_min as es_habitual
    from clientes c2
    where p_cliente is null or c2.id = p_cliente
  ) sub
  where c.id = sub.id
    and c.habitual_auto is distinct from sub.es_habitual;

  perform set_config('app.sistema', 'off', true);
end $$;

create or replace function public.tg_pedidos_habitual()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform recalcular_habitual(new.cliente_id);
  if tg_op = 'UPDATE' and old.cliente_id is distinct from new.cliente_id then
    perform recalcular_habitual(old.cliente_id);
  end if;
  return null;
end $$;

create trigger pedidos_habitual
  after insert or update of estado, entregado_en, cliente_id on public.pedidos
  for each row execute function public.tg_pedidos_habitual();

-- ---------- Tareas ----------
-- * Empleado (no jefe): solo crea tareas asignadas a sí mismo y no reasigna.
-- * Si la tarea no la creó él, solo puede cambiar estado.
-- * completada_en se fija al pasar a 'hecha'.
create or replace function public.tg_tareas_guardia()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_libres text[] := array['estado', 'completada_en', 'actualizado_en'];
begin
  if new.estado = 'hecha' and new.completada_en is null then
    new.completada_en := now();
  elsif new.estado <> 'hecha' then
    new.completada_en := null;
  end if;

  if auth.uid() is null or es_jefe() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.asignado_a <> auth.uid() then
      raise exception 'Solo el jefe puede asignar tareas a otras personas' using errcode = 'P0001';
    end if;
  else
    if new.asignado_a is distinct from old.asignado_a then
      raise exception 'Solo el jefe puede reasignar tareas' using errcode = 'P0001';
    end if;
    if old.creado_por is distinct from auth.uid()
       and (to_jsonb(new) - v_libres) is distinct from (to_jsonb(old) - v_libres) then
      raise exception 'Solo podés cambiar el estado de esta tarea' using errcode = 'P0001';
    end if;
  end if;
  return new;
end $$;

create trigger tareas_guardia before insert or update on public.tareas
  for each row execute function public.tg_tareas_guardia();

-- ---------- Alertas: el usuario solo puede marcarlas como leídas ----------
create or replace function public.tg_alertas_guardia()
returns trigger language plpgsql as $$
begin
  if auth.uid() is not null
     and (to_jsonb(new) - 'leida_en') is distinct from (to_jsonb(old) - 'leida_en') then
    raise exception 'Solo se puede marcar la alerta como leída' using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger alertas_guardia before update on public.alertas
  for each row execute function public.tg_alertas_guardia();

-- =============================================================================
-- GENERACIÓN DE ALERTAS
-- =============================================================================

create or replace function public.formatear_cantidad(p bigint, u text)
returns text language sql immutable as $$
  select case
    when u = 'g' and abs(p) >= 1000 then replace(rtrim(to_char(p / 1000.0, 'FM9999999990.99'), '.'), '.', ',') || ' kg'
    when u = 'g' then p || ' g'
    when u = 'ml' and abs(p) >= 1000 then replace(rtrim(to_char(p / 1000.0, 'FM9999999990.99'), '.'), '.', ',') || ' l'
    when u = 'ml' then p || ' ml'
    else p || ' u.'
  end
$$;

-- Fecha del cumpleaños en un año dado (29/02 -> 28/02 en años no bisiestos).
create or replace function public.fecha_cumple_en(p_anio int, p_dia int, p_mes int)
returns date language sql immutable as $$
  select make_date(
    p_anio, p_mes,
    least(p_dia, extract(day from (make_date(p_anio, p_mes, 1) + interval '1 month - 1 day'))::int)
  )
$$;

create or replace function public.proximo_cumple(p_dia int, p_mes int, p_desde date)
returns date language plpgsql immutable as $$
declare
  v date;
begin
  v := fecha_cumple_en(extract(year from p_desde)::int, p_dia, p_mes);
  if v < p_desde then
    v := fecha_cumple_en(extract(year from p_desde)::int + 1, p_dia, p_mes);
  end if;
  return v;
end $$;

-- Inserta la alerta para cada destinatario, ignorando duplicados. Devuelve cuántas creó.
create or replace function public.crear_alerta(
  p_dest uuid[], p_tipo text, p_titulo text, p_mensaje text,
  p_entidad_tipo text, p_entidad_id uuid, p_clave text
) returns int language plpgsql security definer set search_path = public as $$
declare
  v int;
begin
  if p_dest is null or cardinality(p_dest) = 0 then
    return 0;
  end if;
  insert into alertas (destinatario_id, tipo, titulo, mensaje, entidad_tipo, entidad_id, clave)
  select d, p_tipo, p_titulo, p_mensaje, p_entidad_tipo, p_entidad_id, p_clave
  from unnest(p_dest) d
  on conflict (destinatario_id, clave) do nothing;
  get diagnostics v = row_count;
  return v;
end $$;

-- Stock bajo mínimo: se evalúa con cada movimiento (máx. 1 alerta por insumo por día).
create or replace function public.tg_mov_stock_alerta()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  i insumos;
  v_stock bigint;
begin
  select * into i from insumos where id = new.insumo_id;
  if i.stock_minimo <= 0 or i.archivado_en is not null then
    return null;
  end if;
  select coalesce(sum(cantidad), 0) into v_stock from movimientos_stock where insumo_id = new.insumo_id;
  if v_stock < i.stock_minimo then
    perform crear_alerta(
      array(select destinatarios_modulos(array['stock', 'compras'])),
      'stock_bajo',
      'Falta ' || i.nombre,
      'Quedan ' || formatear_cantidad(v_stock, i.unidad) || ' (mínimo ' || formatear_cantidad(i.stock_minimo, i.unidad) || ').',
      'insumo', i.id,
      'stock_bajo:' || i.id || ':' || hoy_ar()
    );
  end if;
  return null;
end $$;

create trigger movimientos_stock_alerta after insert on public.movimientos_stock
  for each row execute function public.tg_mov_stock_alerta();

-- Tarea asignada a otra persona.
create or replace function public.tg_tareas_alerta()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.asignado_a is distinct from auth.uid()
     and (tg_op = 'INSERT' or new.asignado_a is distinct from old.asignado_a) then
    perform crear_alerta(
      array[new.asignado_a],
      'tarea_asignada',
      'Nueva tarea: ' || new.titulo,
      coalesce('Vence el ' || to_char(new.fecha_vencimiento, 'DD/MM') || '.', 'Sin fecha de vencimiento.'),
      'tarea', new.id,
      'tarea_asignada:' || new.id || ':' || new.asignado_a
    );
  end if;
  return null;
end $$;

create trigger tareas_alerta after insert or update of asignado_a on public.tareas
  for each row execute function public.tg_tareas_alerta();

-- Cumpleaños dentro de los próximos `dias_aviso_cumple` días (1 alerta por cliente por año).
create or replace function public.generar_alertas_cumpleanos()
returns int language plpgsql security definer set search_path = public as $$
declare
  v_cfg configuracion;
  v_hoy date := hoy_ar();
  v_dest uuid[];
  v_n int := 0;
  v_prox date;
  v_falta int;
  v_hab boolean;
  r record;
begin
  select * into v_cfg from configuracion limit 1;
  v_dest := array(select destinatarios_modulos(array['clientes']));
  if cardinality(v_dest) = 0 then
    return 0;
  end if;

  for r in select * from clientes where archivado_en is null and cumple_dia is not null loop
    v_hab := r.habitual_modo = 'si' or (r.habitual_modo = 'auto' and r.habitual_auto);
    continue when v_cfg.aviso_cumple_alcance = 'habituales' and not v_hab;

    v_prox := proximo_cumple(r.cumple_dia, r.cumple_mes, v_hoy);
    v_falta := v_prox - v_hoy;
    continue when v_falta > v_cfg.dias_aviso_cumple;

    v_n := v_n + crear_alerta(
      v_dest,
      'cumpleanos',
      'Se acerca el cumpleaños de ' || r.nombre,
      case when v_falta = 0 then '¡Es hoy!' when v_falta = 1 then 'Es mañana' else 'Faltan ' || v_falta || ' días' end
        || ' (' || to_char(v_prox, 'DD/MM') || ').'
        || case when v_hab then ' Es cliente habitual: ofrecele un regalo o descuento.' else '' end,
      'cliente', r.id,
      'cumple:' || r.id || ':' || extract(year from v_prox)
    );
  end loop;
  return v_n;
end $$;

-- Entregas de mañana.
create or replace function public.generar_alertas_entregas()
returns int language plpgsql security definer set search_path = public as $$
declare
  v_manana date := hoy_ar() + 1;
  v_dest uuid[];
  v_n int := 0;
  r record;
begin
  v_dest := array(select destinatarios_modulos(array['pedidos', 'produccion']));
  for r in
    select p.*, c.nombre as cliente_nombre
    from pedidos p
    join clientes c on c.id = p.cliente_id
    where p.estado in ('confirmado', 'en_produccion', 'listo')
      and (p.fecha_entrega at time zone 'America/Argentina/Buenos_Aires')::date = v_manana
  loop
    v_n := v_n + crear_alerta(
      v_dest,
      'entrega_proxima',
      'Entrega mañana: pedido #' || coalesce(r.numero::text, '?'),
      r.cliente_nombre || ' – ' || to_char(r.fecha_entrega at time zone 'America/Argentina/Buenos_Aires', 'HH24:MI') || ' hs'
        || case when r.tipo_entrega = 'envio' then ' (envío)' else ' (retira)' end,
      'pedido', r.id,
      'entrega:' || r.id || ':' || v_manana
    );
  end loop;
  return v_n;
end $$;

-- Tareas vencidas sin terminar (1 alerta por tarea).
create or replace function public.generar_alertas_tareas_vencidas()
returns int language plpgsql security definer set search_path = public as $$
declare
  v_n int := 0;
  r record;
begin
  for r in
    select * from tareas
    where estado in ('pendiente', 'en_progreso')
      and fecha_vencimiento is not null
      and fecha_vencimiento < hoy_ar()
  loop
    v_n := v_n + crear_alerta(
      array[r.asignado_a],
      'tarea_vencida',
      'Tarea vencida: ' || r.titulo,
      'Venció el ' || to_char(r.fecha_vencimiento, 'DD/MM') || '.',
      'tarea', r.id,
      'tarea_vencida:' || r.id
    );
  end loop;
  return v_n;
end $$;

-- Punto de entrada del cron diario.
create or replace function public.tareas_diarias()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_res jsonb;
begin
  perform recalcular_habitual(null);
  v_res := jsonb_build_object(
    'cumpleanos', generar_alertas_cumpleanos(),
    'entregas', generar_alertas_entregas(),
    'tareas_vencidas', generar_alertas_tareas_vencidas()
  );
  return v_res;
end $$;

-- Las funciones internas no se pueden llamar desde la API.
revoke execute on function public.recalcular_habitual(uuid) from public, anon, authenticated;
revoke execute on function public.crear_alerta(uuid[], text, text, text, text, uuid, text) from public, anon, authenticated;
revoke execute on function public.generar_alertas_cumpleanos() from public, anon, authenticated;
revoke execute on function public.generar_alertas_entregas() from public, anon, authenticated;
revoke execute on function public.generar_alertas_tareas_vencidas() from public, anon, authenticated;
revoke execute on function public.tareas_diarias() from public, anon, authenticated;
revoke execute on function public.destinatarios_modulos(text[]) from public, anon, authenticated;
