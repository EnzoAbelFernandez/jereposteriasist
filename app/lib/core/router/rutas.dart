/// Constantes y constructores de rutas de la aplicación.
///
/// **Prohibido** escribir rutas como strings sueltos en las pantallas.
abstract final class Rutas {
  static const String login = '/login';
  static const String inicio = '/';
  static const String alertas = '/alertas';

  // Clientes
  static const String clientes = '/clientes';
  static const String clienteNuevo = '/clientes/nuevo';
  static String cliente(String id) => '/clientes/$id';
  static String clienteEditar(String id) => '/clientes/$id/editar';

  // Pedidos
  static const String pedidos = '/pedidos';
  static const String pedidosCalendario = '/pedidos/calendario';
  static String pedidoNuevo({String? clienteId}) => clienteId == null
      ? '/pedidos/nuevo'
      : '/pedidos/nuevo?clienteId=$clienteId';
  static String pedido(String id) => '/pedidos/$id';
  static String pedidoEditar(String id) => '/pedidos/$id/editar';

  // Catálogo (productos y recetas)
  static const String productos = '/productos';
  static const String productoNuevo = '/productos/nuevo';
  static String productoEditar(String id) => '/productos/$id/editar';

  static const String recetas = '/recetas';
  static const String recetaNueva = '/recetas/nueva';
  static String recetaEditar(String id) => '/recetas/$id/editar';

  // Stock e insumos
  static const String stock = '/stock';
  static const String insumoNuevo = '/stock/insumos/nuevo';
  static String insumoEditar(String id) => '/stock/insumos/$id/editar';
  static String stockMovimientos(String insumoId) =>
      '/stock/$insumoId/movimientos';

  // Compras y proveedores
  static const String compras = '/compras';
  static const String compraNueva = '/compras/nueva';
  static const String comprasSugeridas = '/compras/sugeridas';
  static String compra(String id) => '/compras/$id';

  static const String proveedores = '/proveedores';
  static const String proveedorNuevo = '/proveedores/nuevo';
  static String proveedorEditar(String id) => '/proveedores/$id/editar';

  // Producción
  static const String produccion = '/produccion';
  static String produccionNueva({String? pedidoId}) => pedidoId == null
      ? '/produccion/nueva'
      : '/produccion/nueva?pedidoId=$pedidoId';
  static String produccionDetalle(String id) => '/produccion/$id';

  // Caja y gastos
  static const String caja = '/caja';
  static const String gastos = '/gastos';
  static const String gastoNuevo = '/gastos/nuevo';
  static const String categoriasGasto = '/gastos/categorias';

  // Tareas
  static const String tareas = '/tareas';
  static const String tareaNueva = '/tareas/nueva';
  static String tareaEditar(String id) => '/tareas/$id/editar';

  // Equipo y configuración
  static const String equipo = '/equipo';
  static String equipoPermisos(String perfilId) => '/equipo/$perfilId/permisos';
  static const String configuracion = '/configuracion';

  // Reportes
  static const String reportes = '/reportes';
}
