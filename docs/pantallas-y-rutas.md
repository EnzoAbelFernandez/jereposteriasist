# Pantallas y rutas (`Rutas`)

Ubicación: `app/lib/core/router/rutas.dart` y `app/lib/core/router/router.dart`.

> [!IMPORTANT]
> **Prohibido** escribir strings de rutas a mano en las pantallas (como `context.push('/pedidos/123')`). Usar **siempre** la clase `Rutas`: `context.push(Rutas.pedido(id))`.

## Tabla de rutas y permisos requeridos

El router redirige automáticamente si el usuario no está logueado o no tiene el permiso mínimo.

| Constante / método en `Rutas` | Path | Pantalla | Permiso mínimo | Tarea |
|---|---|---|---|---|
| `Rutas.login` | `/login` | `LoginPantalla` | público | F0 |
| `Rutas.inicio` | `/` | `InicioPantalla` | autenticado | F1-23 |
| `Rutas.alertas` | `/alertas` | `AlertasPantalla` | autenticado | F1-22 |
| **Clientes (referencia)** |||||
| `Rutas.clientes` | `/clientes` | `ClientesListaPantalla` | `clientes:ver` | F0 |
| `Rutas.clienteNuevo` | `/clientes/nuevo` | `ClienteFormularioPantalla` | `clientes:cargar` | F0 |
| `Rutas.cliente(id)` | `/clientes/:id` | `ClienteDetallePantalla` | `clientes:ver` | F0 |
| `Rutas.clienteEditar(id)` | `/clientes/:id/editar` | `ClienteFormularioPantalla(id: id)` | `clientes:editar` | F0 |
| **Pedidos** |||||
| `Rutas.pedidos` | `/pedidos` | `PedidosListaPantalla` | `pedidos:ver` o `produccion:ver` | F1-10 |
| `Rutas.pedidosCalendario` | `/pedidos/calendario` | `PedidosCalendarioPantalla` | `pedidos:ver` o `produccion:ver` | F1-13 |
| `Rutas.pedidoNuevo({String? clienteId})` | `/pedidos/nuevo` | `PedidoFormularioPantalla` | `pedidos:cargar` | F1-11 |
| `Rutas.pedido(id)` | `/pedidos/:id` | `PedidoDetallePantalla` | `pedidos:ver` o `produccion:ver` | F1-12 |
| `Rutas.pedidoEditar(id)` | `/pedidos/:id/editar` | `PedidoFormularioPantalla(id: id)` | `pedidos:editar` | F1-11 |
| **Catálogo (productos y recetas)** |||||
| `Rutas.productos` | `/productos` | `ProductosListaPantalla` | `catalogo:ver` | F1-03 |
| `Rutas.productoNuevo` | `/productos/nuevo` | `ProductoFormularioPantalla` | `catalogo:cargar` | F1-03 |
| `Rutas.productoEditar(id)` | `/productos/:id/editar` | `ProductoFormularioPantalla(id: id)` | `catalogo:editar` | F1-03 |
| `Rutas.recetas` | `/recetas` | `RecetasListaPantalla` | `produccion:ver` o `catalogo:ver` | F2-01 |
| `Rutas.recetaNueva` | `/recetas/nueva` | `RecetaFormularioPantalla` | `produccion:cargar` | F2-01 |
| `Rutas.recetaEditar(id)` | `/recetas/:id/editar` | `RecetaFormularioPantalla(id: id)` | `produccion:editar` | F2-01 |
| **Stock e insumos** |||||
| `Rutas.stock` | `/stock` | `StockListaPantalla` | `stock:ver` | F1-05 |
| `Rutas.insumoNuevo` | `/stock/insumos/nuevo` | `InsumoFormularioPantalla` | `stock:cargar` | F1-02 |
| `Rutas.insumoEditar(id)` | `/stock/insumos/:id/editar` | `InsumoFormularioPantalla(id: id)` | `stock:editar` | F1-02 |
| `Rutas.stockMovimientos(insumoId)` | `/stock/:insumoId/movimientos` | `StockMovimientosPantalla` | `stock:ver` | F1-07 |
| **Compras y proveedores** |||||
| `Rutas.compras` | `/compras` | `ComprasListaPantalla` | `compras:ver` | F1-08 |
| `Rutas.compraNueva` | `/compras/nueva` | `CompraFormularioPantalla` | `compras:cargar` | F1-09 |
| `Rutas.compra(id)` | `/compras/:id` | `CompraDetallePantalla` | `compras:ver` | F1-08 |
| `Rutas.proveedores` | `/proveedores` | `ProveedoresListaPantalla` | `compras:ver` | F1-01 |
| `Rutas.proveedorNuevo` | `/proveedores/nuevo` | `ProveedorFormularioPantalla` | `compras:cargar` | F1-01 |
| `Rutas.proveedorEditar(id)` | `/proveedores/:id/editar` | `ProveedorFormularioPantalla(id: id)` | `compras:editar` | F1-01 |
| **Producción** |||||
| `Rutas.produccion` | `/produccion` | `ProduccionListaPantalla` | `produccion:ver` | F1-17 |
| `Rutas.produccionNueva({String? pedidoId})` | `/produccion/nueva` | `ProduccionFormularioPantalla` | `produccion:cargar` | F1-17 |
| `Rutas.produccionDetalle(id)` | `/produccion/:id` | `ProduccionDetallePantalla` | `produccion:ver` | F1-17 |
| **Caja y gastos** |||||
| `Rutas.caja` | `/caja` | `CajaPantalla` | `caja:ver` | F1-14 |
| `Rutas.gastos` | `/gastos` | `GastosListaPantalla` | `gastos:ver` | F1-16 |
| `Rutas.gastoNuevo` | `/gastos/nuevo` | `GastoFormularioPantalla` | `gastos:cargar` | F1-16 |
| `Rutas.categoriasGasto` | `/gastos/categorias` | `CategoriasGastoPantalla` | `gastos:editar` | F1-04 |
| **Tareas** |||||
| `Rutas.tareas` | `/tareas` | `TareasPantalla` | autenticado | F1-18 / F1-19 |
| `Rutas.tareaNueva` | `/tareas/nueva` | `TareaFormularioPantalla` | autenticado | F1-18 / F1-19 |
| `Rutas.tareaEditar(id)` | `/tareas/:id/editar` | `TareaFormularioPantalla(id: id)` | autenticado | F1-19 |
| **Equipo y configuración (jefe)** |||||
| `Rutas.equipo` | `/equipo` | `EquipoListaPantalla` | solo jefe | F1-20 |
| `Rutas.equipoPermisos(perfilId)` | `/equipo/:perfilId/permisos` | `EquipoPermisosPantalla` | solo jefe | F1-21 |
| `Rutas.configuracion` | `/configuracion` | `ConfiguracionPantalla` | solo jefe | F1-20 |
| **Reportes (Fase 2)** |||||
| `Rutas.reportes` | `/reportes` | `ReportesPantalla` | `reportes:ver` | F2-05 |
| `Rutas.comprasSugeridas` | `/compras/sugeridas` | `ComprasSugeridasPantalla` | `compras:ver` | F2-04 |

> [!NOTE]
> El router ya viene configurado en la Fase 0 con todas las rutas apuntando a pantallas placeholder (`PantallaEnConstruccion`), así que **ninguna tarea de la Fase 1 tiene que tocar `router.dart` ni `rutas.dart`**. Solo reemplazan el archivo de la pantalla que les toca.
