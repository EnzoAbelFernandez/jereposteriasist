# Fichas de tareas para agentes

Cada tarea está diseñada para que la resuelva un agente de forma **aislada**, sin tocar la base de datos, la sincronización ni la lógica de negocio.

## Cómo asignarle una tarea a un agente

Copiá y pegá este prompt (cambiando el archivo de la tarea):

```text
Leé AGENTS.md y después leé docs/tareas/F1-01-proveedores.md.
Implementá únicamente esa tarea respetando todas las reglas de AGENTS.md.
Antes de terminar, ejecutá el comando de verificación que figura al final de la ficha y pegá el resultado.
```

## Orden recomendado y paralelismo

Las tareas del mismo bloque que no dependen entre sí se pueden correr en paralelo en ramas separadas (`git worktree` o ramas por agente).

| ID | Archivo | Dif. | Depende de | Archivos que toca |
|---|---|---|---|---|
| **Bloque A – Catálogos** |||||
| F1-01 | [F1-01-proveedores.md](file:///d:/projects/jereposteria/docs/tareas/F1-01-proveedores.md) | 🟢 | Fase 0 | `features/proveedores/*` |
| F1-02 | [F1-02-insumos.md](file:///d:/projects/jereposteria/docs/tareas/F1-02-insumos.md) | 🟢 | Fase 0 | `features/stock/insumo_formulario_pantalla.dart` |
| F1-03 | [F1-03-productos.md](file:///d:/projects/jereposteria/docs/tareas/F1-03-productos.md) | 🟢 | Fase 0 | `features/catalogo/*` |
| F1-04 | [F1-04-categorias-gasto.md](file:///d:/projects/jereposteria/docs/tareas/F1-04-categorias-gasto.md) | 🟢 | Fase 0 | `features/gastos/categorias_gasto_pantalla.dart` |
| **Bloque B – Stock y compras** |||||
| F1-05 | [F1-05-stock-lista.md](file:///d:/projects/jereposteria/docs/tareas/F1-05-stock-lista.md) | 🟢 | F1-02 | `features/stock/stock_lista_pantalla.dart` |
| F1-06 | [F1-06-stock-ajuste-merma.md](file:///d:/projects/jereposteria/docs/tareas/F1-06-stock-ajuste-merma.md) | 🟢 | F1-05 | `features/stock/dialogos_stock.dart`, `stock_lista_pantalla.dart` |
| F1-07 | [F1-07-stock-movimientos.md](file:///d:/projects/jereposteria/docs/tareas/F1-07-stock-movimientos.md) | 🟢 | F1-06 | `features/stock/stock_movimientos_pantalla.dart` |
| F1-08 | [F1-08-compras-lista-detalle.md](file:///d:/projects/jereposteria/docs/tareas/F1-08-compras-lista-detalle.md) | 🟢 | F1-01 | `features/compras/compras_lista_pantalla.dart`, `compra_detalle_pantalla.dart` |
| F1-09 | [F1-09-compra-formulario.md](file:///d:/projects/jereposteria/docs/tareas/F1-09-compra-formulario.md) | 🟡 | F1-08 | `features/compras/compra_formulario_pantalla.dart` |
| **Bloque C – Pedidos, caja y gastos** |||||
| F1-10 | [F1-10-pedidos-lista.md](file:///d:/projects/jereposteria/docs/tareas/F1-10-pedidos-lista.md) | 🟢 | F1-03 | `features/pedidos/pedidos_lista_pantalla.dart` |
| F1-11 | [F1-11-pedido-formulario.md](file:///d:/projects/jereposteria/docs/tareas/F1-11-pedido-formulario.md) | 🟡 | F1-10 | `features/pedidos/pedido_formulario_pantalla.dart` |
| F1-12 | [F1-12-pedido-detalle.md](file:///d:/projects/jereposteria/docs/tareas/F1-12-pedido-detalle.md) | 🟡 | F1-11 | `features/pedidos/pedido_detalle_pantalla.dart`, `dialogo_pago_pedido.dart` |
| F1-13 | [F1-13-pedidos-calendario.md](file:///d:/projects/jereposteria/docs/tareas/F1-13-pedidos-calendario.md) | 🟡 | F1-10 | `features/pedidos/pedidos_calendario_pantalla.dart` |
| F1-14 | [F1-14-caja-lista.md](file:///d:/projects/jereposteria/docs/tareas/F1-14-caja-lista.md) | 🟢 | Fase 0 | `features/caja/caja_pantalla.dart` |
| F1-15 | [F1-15-caja-movimiento-manual.md](file:///d:/projects/jereposteria/docs/tareas/F1-15-caja-movimiento-manual.md) | 🟢 | F1-14 | `features/caja/dialogo_movimiento_caja.dart`, `caja_pantalla.dart` |
| F1-16 | [F1-16-gastos.md](file:///d:/projects/jereposteria/docs/tareas/F1-16-gastos.md) | 🟢 | F1-04 | `features/gastos/gastos_lista_pantalla.dart`, `gasto_formulario_pantalla.dart` |
| **Bloque D – Producción y equipo** |||||
| F1-17 | [F1-17-produccion.md](file:///d:/projects/jereposteria/docs/tareas/F1-17-produccion.md) | 🟡 | F1-02 | `features/produccion/*` |
| F1-18 | [F1-18-mis-tareas.md](file:///d:/projects/jereposteria/docs/tareas/F1-18-mis-tareas.md) | 🟢 | Fase 0 | `features/tareas/tareas_pantalla.dart` |
| F1-19 | [F1-19-tarea-formulario.md](file:///d:/projects/jereposteria/docs/tareas/F1-19-tarea-formulario.md) | 🟢 | F1-18 | `features/tareas/tarea_formulario_pantalla.dart`, `tareas_pantalla.dart` |
| F1-20 | [F1-20-equipo-y-configuracion.md](file:///d:/projects/jereposteria/docs/tareas/F1-20-equipo-y-configuracion.md) | 🟢 | Fase 0 | `features/equipo/equipo_lista_pantalla.dart`, `configuracion_pantalla.dart` |
| F1-21 | [F1-21-equipo-permisos.md](file:///d:/projects/jereposteria/docs/tareas/F1-21-equipo-permisos.md) | 🟡 | F1-20 | `features/equipo/equipo_permisos_pantalla.dart` |
| **Bloque E – Alertas e inicio** |||||
| F1-22 | [F1-22-alertas.md](file:///d:/projects/jereposteria/docs/tareas/F1-22-alertas.md) | 🟢 | Fase 0 | `features/alertas/alertas_pantalla.dart` |
| F1-23 | [F1-23-inicio.md](file:///d:/projects/jereposteria/docs/tareas/F1-23-inicio.md) | 🟡 | F1-22 | `features/inicio/inicio_pantalla.dart` |
| F1-24 | [F1-24-notificaciones-push.md](file:///d:/projects/jereposteria/docs/tareas/F1-24-notificaciones-push.md) | 🔴 | F1-22 + Firebase | modelo fuerte |
| **Fase 2 – Recetas, costos y reportes** |||||
| F2-01 | [F2-01-recetas.md](file:///d:/projects/jereposteria/docs/tareas/F2-01-recetas.md) | 🟢 | Fase 1 | `features/catalogo/recetas_lista_pantalla.dart`, `receta_formulario_pantalla.dart` |
| F2-02 | [F2-02-produccion-desde-receta.md](file:///d:/projects/jereposteria/docs/tareas/F2-02-produccion-desde-receta.md) | 🟢 | F2-01 | `features/produccion/produccion_formulario_pantalla.dart` |
| F2-03 | [F2-03-costo-producto.md](file:///d:/projects/jereposteria/docs/tareas/F2-03-costo-producto.md) | 🟢 | F2-01 | `features/catalogo/productos_lista_pantalla.dart`, `producto_formulario_pantalla.dart` |
| F2-04 | [F2-04-compras-sugeridas.md](file:///d:/projects/jereposteria/docs/tareas/F2-04-compras-sugeridas.md) | 🟡 | F2-01 | `features/compras/compras_sugeridas_pantalla.dart`, `compras_lista_pantalla.dart` |
| F2-05 | [F2-05-reportes-financieros.md](file:///d:/projects/jereposteria/docs/tareas/F2-05-reportes-financieros.md) | 🟡 | Fase 1 | `features/reportes/reportes_pantalla.dart` |
| F2-06 | [F2-06-reportes-rankings.md](file:///d:/projects/jereposteria/docs/tareas/F2-06-reportes-rankings.md) | 🟢 | F2-05 | `features/reportes/rankings_periodo_seccion.dart`, `reportes_pantalla.dart` |
