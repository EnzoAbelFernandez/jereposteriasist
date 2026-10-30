-- Precio de referencia por presentación, independiente de compras y stock.
alter table public.insumos
  add column precio_referencia_centavos bigint,
  add column cantidad_referencia bigint,
  add constraint insumos_referencia_valida check (
    (precio_referencia_centavos is null and cantidad_referencia is null) or
    (precio_referencia_centavos > 0 and cantidad_referencia > 0 and precio_referencia_centavos is not null and cantidad_referencia is not null)
  );
