-- =============================================================================
-- 0600 POWERSYNC: publicación de replicación lógica
-- =============================================================================
-- PowerSync lee los cambios de estas tablas. Si se agrega una tabla sincronizada,
-- agregarla acá (alter publication powersync add table ...) Y en powersync/sync-config.yaml.
-- No se publican: dispositivos, auditoria.

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'powersync') then
    alter publication powersync set table
      public.configuracion,
      public.perfiles,
      public.permisos,
      public.clientes,
      public.proveedores,
      public.insumos,
      public.productos,
      public.recetas,
      public.receta_items,
      public.pedidos,
      public.pedido_items,
      public.compras,
      public.compra_items,
      public.categorias_gasto,
      public.gastos,
      public.producciones,
      public.movimientos_stock,
      public.movimientos_caja,
      public.tareas,
      public.alertas;
  else
    create publication powersync for table
      public.configuracion,
      public.perfiles,
      public.permisos,
      public.clientes,
      public.proveedores,
      public.insumos,
      public.productos,
      public.recetas,
      public.receta_items,
      public.pedidos,
      public.pedido_items,
      public.compras,
      public.compra_items,
      public.categorias_gasto,
      public.gastos,
      public.producciones,
      public.movimientos_stock,
      public.movimientos_caja,
      public.tareas,
      public.alertas;
  end if;
end $$;
