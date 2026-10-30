begin;
create table public.registros_publicos_limite (
  id bigint generated always as identity primary key,
  creado_en timestamptz not null default now()
);
alter table public.registros_publicos_limite enable row level security;
revoke all on public.registros_publicos_limite from anon, authenticated;
create function public.registrar_cliente_publico(p_nombre text, p_telefono text, p_dia integer, p_mes integer, p_sitio text default '')
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_nombre text := trim(coalesce(p_nombre, ''));
  v_telefono text := regexp_replace(coalesce(p_telefono, ''), '[^0-9]', '', 'g');
  v_dias integer;
begin
  if coalesce(p_sitio, '') <> '' then return; end if;
  if char_length(v_nombre) < 2 or char_length(v_nombre) > 120 or v_nombre ~ '[[:cntrl:]]' or
     char_length(v_telefono) < 8 or char_length(v_telefono) > 15 or
     p_mes is null or p_mes not between 1 and 12 or p_dia is null then
    raise exception 'Datos inválidos' using errcode = '22023';
  end if;
  v_dias := extract(day from (make_date(2024, p_mes, 1) + interval '1 month - 1 day'))::integer;
  if p_dia < 1 or p_dia > v_dias then raise exception 'Fecha inválida' using errcode = '22023'; end if;
  perform pg_advisory_xact_lock(hashtext('jere_registro_publico'));
  if (select count(*) from public.registros_publicos_limite where creado_en > now() - interval '1 minute') >= 20 then
    raise exception 'Intentá de nuevo en unos minutos' using errcode = 'P0001';
  end if;
  insert into public.registros_publicos_limite default values;
  if not exists (select 1 from public.clientes c where regexp_replace(coalesce(c.telefono, ''), '[^0-9]', '', 'g') = v_telefono) then
    insert into public.clientes(nombre, telefono, cumple_dia, cumple_mes, notas)
    values (v_nombre, v_telefono, p_dia, p_mes, 'Registro desde formulario de clientes');
  end if;
end $$;
revoke all on function public.registrar_cliente_publico(text,text,integer,integer,text) from public;
grant execute on function public.registrar_cliente_publico(text,text,integer,integer,text) to anon, authenticated;
commit;
