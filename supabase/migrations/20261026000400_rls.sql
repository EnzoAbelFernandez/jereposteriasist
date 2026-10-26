-- =============================================================================
-- 0400 SEGURIDAD: Row Level Security
-- =============================================================================
-- Niveles: ver (leer) < cargar (crear) < editar (crear + modificar + anular).
-- IMPORTANTE: estas políticas deben mantenerse ALINEADAS con powersync/sync-config.yaml
-- (lo que un usuario puede leer acá es lo que se sincroniza a su dispositivo).
-- No hay políticas DELETE salvo en ítems editables (pedido_items, receta_items):
-- todo lo demás se archiva o se anula.
-- =============================================================================

do $$
declare
  t text;
begin
  foreach t in array array[
    'configuracion', 'perfiles', 'permisos', 'clientes', 'proveedores', 'insumos', 'productos',
    'recetas', 'receta_items', 'pedidos', 'pedido_items', 'compras', 'compra_items',
    'categorias_gasto', 'gastos', 'producciones', 'movimientos_stock', 'movimientos_caja',
    'tareas', 'alertas', 'dispositivos', 'auditoria'
  ] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

grant usage on sequence public.pedidos_numero_seq to authenticated;

-- ---------- configuracion ----------
create policy configuracion_select on public.configuracion for select to authenticated using (true);
create policy configuracion_update on public.configuracion for update to authenticated
  using (es_jefe()) with check (es_jefe());

-- ---------- perfiles ----------
create policy perfiles_select on public.perfiles for select to authenticated using (true);
create policy perfiles_update on public.perfiles for update to authenticated
  using (es_jefe() or id = auth.uid()) with check (es_jefe() or id = auth.uid());

-- ---------- permisos ----------
create policy permisos_select on public.permisos for select to authenticated
  using (perfil_id = auth.uid() or es_jefe());
create policy permisos_update on public.permisos for update to authenticated
  using (es_jefe()) with check (es_jefe());

-- ---------- clientes (también los leen/crean quienes cargan pedidos) ----------
create policy clientes_select on public.clientes for select to authenticated
  using (tiene_permiso('clientes', 'ver') or tiene_permiso('pedidos', 'ver'));
create policy clientes_insert on public.clientes for insert to authenticated
  with check (tiene_permiso('clientes', 'cargar') or tiene_permiso('pedidos', 'cargar'));
create policy clientes_update on public.clientes for update to authenticated
  using (tiene_permiso('clientes', 'editar')) with check (tiene_permiso('clientes', 'editar'));

-- ---------- proveedores (módulo compras) ----------
create policy proveedores_select on public.proveedores for select to authenticated
  using (tiene_permiso('compras', 'ver'));
create policy proveedores_insert on public.proveedores for insert to authenticated
  with check (tiene_permiso('compras', 'cargar'));
create policy proveedores_update on public.proveedores for update to authenticated
  using (tiene_permiso('compras', 'editar')) with check (tiene_permiso('compras', 'editar'));

-- ---------- insumos (módulo stock; lectura también para compras y producción) ----------
create policy insumos_select on public.insumos for select to authenticated
  using (tiene_permiso('stock', 'ver') or tiene_permiso('compras', 'ver') or tiene_permiso('produccion', 'ver'));
create policy insumos_insert on public.insumos for insert to authenticated
  with check (tiene_permiso('stock', 'cargar'));
create policy insumos_update on public.insumos for update to authenticated
  using (tiene_permiso('stock', 'editar')) with check (tiene_permiso('stock', 'editar'));

-- ---------- productos (módulo catalogo; lectura también para pedidos y producción) ----------
create policy productos_select on public.productos for select to authenticated
  using (tiene_permiso('catalogo', 'ver') or tiene_permiso('pedidos', 'ver') or tiene_permiso('produccion', 'ver'));
create policy productos_insert on public.productos for insert to authenticated
  with check (tiene_permiso('catalogo', 'cargar'));
create policy productos_update on public.productos for update to authenticated
  using (tiene_permiso('catalogo', 'editar')) with check (tiene_permiso('catalogo', 'editar'));

-- ---------- recetas / receta_items (módulo produccion; lectura también catalogo) ----------
create policy recetas_select on public.recetas for select to authenticated
  using (tiene_permiso('produccion', 'ver') or tiene_permiso('catalogo', 'ver'));
create policy recetas_insert on public.recetas for insert to authenticated
  with check (tiene_permiso('produccion', 'cargar'));
create policy recetas_update on public.recetas for update to authenticated
  using (tiene_permiso('produccion', 'editar')) with check (tiene_permiso('produccion', 'editar'));

create policy receta_items_select on public.receta_items for select to authenticated
  using (tiene_permiso('produccion', 'ver') or tiene_permiso('catalogo', 'ver'));
create policy receta_items_insert on public.receta_items for insert to authenticated
  with check (tiene_permiso('produccion', 'cargar'));
create policy receta_items_update on public.receta_items for update to authenticated
  using (tiene_permiso('produccion', 'editar')) with check (tiene_permiso('produccion', 'editar'));
create policy receta_items_delete on public.receta_items for delete to authenticated
  using (tiene_permiso('produccion', 'editar'));

-- ---------- pedidos / pedido_items (lectura también para producción) ----------
create policy pedidos_select on public.pedidos for select to authenticated
  using (tiene_permiso('pedidos', 'ver') or tiene_permiso('produccion', 'ver'));
create policy pedidos_insert on public.pedidos for insert to authenticated
  with check (tiene_permiso('pedidos', 'cargar'));
-- produccion:cargar puede actualizar, pero el trigger pedidos_guardia lo limita al estado.
create policy pedidos_update on public.pedidos for update to authenticated
  using (tiene_permiso('pedidos', 'editar') or tiene_permiso('produccion', 'cargar'))
  with check (tiene_permiso('pedidos', 'editar') or tiene_permiso('produccion', 'cargar'));

create policy pedido_items_select on public.pedido_items for select to authenticated
  using (tiene_permiso('pedidos', 'ver') or tiene_permiso('produccion', 'ver'));
create policy pedido_items_insert on public.pedido_items for insert to authenticated
  with check (tiene_permiso('pedidos', 'cargar'));
create policy pedido_items_update on public.pedido_items for update to authenticated
  using (tiene_permiso('pedidos', 'editar')) with check (tiene_permiso('pedidos', 'editar'));
create policy pedido_items_delete on public.pedido_items for delete to authenticated
  using (tiene_permiso('pedidos', 'editar'));

-- ---------- compras / compra_items ----------
create policy compras_select on public.compras for select to authenticated
  using (tiene_permiso('compras', 'ver'));
create policy compras_insert on public.compras for insert to authenticated
  with check (tiene_permiso('compras', 'cargar'));
create policy compras_update on public.compras for update to authenticated
  using (tiene_permiso('compras', 'editar')) with check (tiene_permiso('compras', 'editar'));

create policy compra_items_select on public.compra_items for select to authenticated
  using (tiene_permiso('compras', 'ver'));
create policy compra_items_insert on public.compra_items for insert to authenticated
  with check (tiene_permiso('compras', 'cargar'));

-- ---------- gastos / categorias_gasto ----------
create policy categorias_gasto_select on public.categorias_gasto for select to authenticated
  using (tiene_permiso('gastos', 'ver') or tiene_permiso('caja', 'ver'));
create policy categorias_gasto_insert on public.categorias_gasto for insert to authenticated
  with check (tiene_permiso('gastos', 'editar'));
create policy categorias_gasto_update on public.categorias_gasto for update to authenticated
  using (tiene_permiso('gastos', 'editar')) with check (tiene_permiso('gastos', 'editar'));

create policy gastos_select on public.gastos for select to authenticated
  using (tiene_permiso('gastos', 'ver') or tiene_permiso('caja', 'ver'));
create policy gastos_insert on public.gastos for insert to authenticated
  with check (tiene_permiso('gastos', 'cargar'));
create policy gastos_update on public.gastos for update to authenticated
  using (tiene_permiso('gastos', 'editar')) with check (tiene_permiso('gastos', 'editar'));

-- ---------- producciones ----------
create policy producciones_select on public.producciones for select to authenticated
  using (tiene_permiso('produccion', 'ver'));
create policy producciones_insert on public.producciones for insert to authenticated
  with check (tiene_permiso('produccion', 'cargar'));
create policy producciones_update on public.producciones for update to authenticated
  using (tiene_permiso('produccion', 'editar')) with check (tiene_permiso('produccion', 'editar'));

-- ---------- movimientos_stock (solo INSERT; el permiso depende del origen) ----------
create policy movimientos_stock_select on public.movimientos_stock for select to authenticated
  using (tiene_permiso('stock', 'ver') or tiene_permiso('compras', 'ver') or tiene_permiso('produccion', 'ver'));
create policy movimientos_stock_insert on public.movimientos_stock for insert to authenticated
  with check (
    (tipo in ('inicial', 'ajuste', 'merma') and tiene_permiso('stock', 'cargar'))
    or (tipo = 'compra' and tiene_permiso('compras', 'cargar'))
    or (tipo = 'produccion' and tiene_permiso('produccion', 'cargar'))
    or (tipo = 'anulacion' and (
          (compra_id is not null and tiene_permiso('compras', 'editar'))
       or (produccion_id is not null and tiene_permiso('produccion', 'editar'))
       or (compra_id is null and produccion_id is null and tiene_permiso('stock', 'editar'))
    ))
  );

-- ---------- movimientos_caja (solo INSERT; el permiso depende del concepto) ----------
-- Sin caja:ver, cada módulo ve solo SUS movimientos (pagos de pedidos para calcular saldos,
-- egresos de compras/gastos para poder anularlos), nunca la caja completa.
create policy movimientos_caja_select on public.movimientos_caja for select to authenticated
  using (
    tiene_permiso('caja', 'ver')
    or (pedido_id is not null and tiene_permiso('pedidos', 'ver'))
    or (compra_id is not null and tiene_permiso('compras', 'ver'))
    or (gasto_id is not null and tiene_permiso('gastos', 'ver'))
  );
create policy movimientos_caja_insert on public.movimientos_caja for insert to authenticated
  with check (
    (concepto in ('otro_ingreso', 'otro_egreso') and tiene_permiso('caja', 'cargar'))
    or (concepto in ('sena', 'pago_pedido') and (tiene_permiso('pedidos', 'cargar') or tiene_permiso('caja', 'cargar')))
    or (concepto = 'compra' and tiene_permiso('compras', 'cargar'))
    or (concepto = 'gasto' and tiene_permiso('gastos', 'cargar'))
    or (concepto = 'anulacion' and (
          tiene_permiso('caja', 'editar')
       or (pedido_id is not null and tiene_permiso('pedidos', 'editar'))
       or (compra_id is not null and tiene_permiso('compras', 'editar'))
       or (gasto_id is not null and tiene_permiso('gastos', 'editar'))
    ))
  );

-- ---------- tareas ----------
create policy tareas_select on public.tareas for select to authenticated
  using (es_jefe() or asignado_a = auth.uid() or creado_por = auth.uid());
create policy tareas_insert on public.tareas for insert to authenticated
  with check (es_jefe() or asignado_a = auth.uid());
create policy tareas_update on public.tareas for update to authenticated
  using (es_jefe() or asignado_a = auth.uid() or creado_por = auth.uid())
  with check (es_jefe() or asignado_a = auth.uid() or creado_por = auth.uid());

-- ---------- alertas ----------
create policy alertas_select on public.alertas for select to authenticated
  using (destinatario_id = auth.uid());
create policy alertas_update on public.alertas for update to authenticated
  using (destinatario_id = auth.uid()) with check (destinatario_id = auth.uid());

-- ---------- dispositivos ----------
create policy dispositivos_all on public.dispositivos for all to authenticated
  using (perfil_id = auth.uid()) with check (perfil_id = auth.uid());

-- ---------- auditoria ----------
create policy auditoria_select on public.auditoria for select to authenticated
  using (es_jefe());
