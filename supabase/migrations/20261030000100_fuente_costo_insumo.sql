alter table public.insumos add column fuente_costo text;
update public.insumos i set fuente_costo = case
  when exists (select 1 from public.compra_items ci join public.compras c on c.id=ci.compra_id where ci.insumo_id=i.id and c.estado <> 'anulado' and ci.cantidad > 0) then 'ultima_compra'
  when i.precio_referencia_centavos is not null and i.cantidad_referencia > 0 then 'referencia'
  else 'ultima_compra' end;
alter table public.insumos alter column fuente_costo set default 'ultima_compra', alter column fuente_costo set not null;
alter table public.insumos add constraint insumos_fuente_costo_valida check (fuente_costo in ('ultima_compra','referencia'));
