import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/core/sesion/sesion.dart';
import 'package:jereposteria/features/alertas/alertas_pantalla.dart';
import 'package:jereposteria/features/auth/login_pantalla.dart';
import 'package:jereposteria/features/caja/caja_pantalla.dart';
import 'package:jereposteria/features/catalogo/producto_formulario_pantalla.dart';
import 'package:jereposteria/features/catalogo/productos_lista_pantalla.dart';
import 'package:jereposteria/features/catalogo/receta_formulario_pantalla.dart';
import 'package:jereposteria/features/catalogo/recetas_lista_pantalla.dart';
import 'package:jereposteria/features/clientes/cliente_detalle_pantalla.dart';
import 'package:jereposteria/features/clientes/cliente_formulario_pantalla.dart';
import 'package:jereposteria/features/clientes/clientes_lista_pantalla.dart';
import 'package:jereposteria/features/compras/compra_detalle_pantalla.dart';
import 'package:jereposteria/features/compras/compra_formulario_pantalla.dart';
import 'package:jereposteria/features/compras/compras_lista_pantalla.dart';
import 'package:jereposteria/features/compras/compras_sugeridas_pantalla.dart';
import 'package:jereposteria/features/equipo/configuracion_pantalla.dart';
import 'package:jereposteria/features/equipo/equipo_lista_pantalla.dart';
import 'package:jereposteria/features/equipo/equipo_permisos_pantalla.dart';
import 'package:jereposteria/features/gastos/categorias_gasto_pantalla.dart';
import 'package:jereposteria/features/gastos/gasto_formulario_pantalla.dart';
import 'package:jereposteria/features/gastos/gastos_lista_pantalla.dart';
import 'package:jereposteria/features/inicio/inicio_pantalla.dart';
import 'package:jereposteria/features/pedidos/pedido_detalle_pantalla.dart';
import 'package:jereposteria/features/pedidos/pedido_formulario_pantalla.dart';
import 'package:jereposteria/features/pedidos/pedidos_calendario_pantalla.dart';
import 'package:jereposteria/features/pedidos/pedidos_lista_pantalla.dart';
import 'package:jereposteria/features/produccion/produccion_detalle_pantalla.dart';
import 'package:jereposteria/features/produccion/produccion_formulario_pantalla.dart';
import 'package:jereposteria/features/produccion/produccion_lista_pantalla.dart';
import 'package:jereposteria/features/proveedores/proveedor_formulario_pantalla.dart';
import 'package:jereposteria/features/proveedores/proveedores_lista_pantalla.dart';
import 'package:jereposteria/features/reportes/reportes_pantalla.dart';
import 'package:jereposteria/features/stock/insumo_formulario_pantalla.dart';
import 'package:jereposteria/features/stock/stock_lista_pantalla.dart';
import 'package:jereposteria/features/stock/stock_movimientos_pantalla.dart';
import 'package:jereposteria/features/tareas/tarea_formulario_pantalla.dart';
import 'package:jereposteria/features/tareas/tareas_pantalla.dart';

class _DestinoMenu {
  const _DestinoMenu({
    required this.ruta,
    required this.etiqueta,
    required this.icono,
    this.modulo,
    this.soloJefe = false,
  });

  final String ruta;
  final String etiqueta;
  final IconData icono;
  final Modulo? modulo;
  final bool soloJefe;

  bool visiblePara(PermisosUsuario permisos) {
    if (soloJefe) return permisos.esJefe;
    if (modulo == null) return true;
    return permisos.puede(modulo!, NivelPermiso.ver);
  }
}

const List<_DestinoMenu> _destinosMenu = [
  _DestinoMenu(
    ruta: Rutas.inicio,
    etiqueta: 'Inicio',
    icono: Icons.home_outlined,
  ),
  _DestinoMenu(
    ruta: Rutas.pedidos,
    etiqueta: 'Pedidos',
    icono: Icons.receipt_long_outlined,
    modulo: Modulo.pedidos,
  ),
  _DestinoMenu(
    ruta: Rutas.clientes,
    etiqueta: 'Clientes',
    icono: Icons.people_outline,
    modulo: Modulo.clientes,
  ),
  _DestinoMenu(
    ruta: Rutas.stock,
    etiqueta: 'Stock',
    icono: Icons.inventory_2_outlined,
    modulo: Modulo.stock,
  ),
  _DestinoMenu(
    ruta: Rutas.compras,
    etiqueta: 'Compras',
    icono: Icons.shopping_cart_outlined,
    modulo: Modulo.compras,
  ),
  _DestinoMenu(
    ruta: Rutas.produccion,
    etiqueta: 'Producción',
    icono: Icons.bakery_dining_outlined,
    modulo: Modulo.produccion,
  ),
  _DestinoMenu(
    ruta: Rutas.caja,
    etiqueta: 'Caja',
    icono: Icons.point_of_sale_outlined,
    modulo: Modulo.caja,
  ),
  _DestinoMenu(
    ruta: Rutas.gastos,
    etiqueta: 'Gastos',
    icono: Icons.receipt_outlined,
    modulo: Modulo.gastos,
  ),
  _DestinoMenu(
    ruta: Rutas.productos,
    etiqueta: 'Catálogo',
    icono: Icons.cake_outlined,
    modulo: Modulo.catalogo,
  ),
  _DestinoMenu(
    ruta: Rutas.tareas,
    etiqueta: 'Tareas',
    icono: Icons.task_alt_outlined,
  ),
  _DestinoMenu(
    ruta: Rutas.alertas,
    etiqueta: 'Alertas',
    icono: Icons.notifications_outlined,
  ),
  _DestinoMenu(
    ruta: Rutas.equipo,
    etiqueta: 'Equipo',
    icono: Icons.badge_outlined,
    soloJefe: true,
  ),
];

class _ShellAdaptativo extends ConsumerWidget {
  const _ShellAdaptativo({required this.ubicacion, required this.child});

  final String ubicacion;
  final Widget child;

  int _indiceActual(List<_DestinoMenu> visibles) {
    for (var i = 0; i < visibles.length; i++) {
      final r = visibles[i].ruta;
      if (r == Rutas.inicio) {
        if (ubicacion == Rutas.inicio) return i;
      } else if (ubicacion.startsWith(r)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permisos = ref.watch(permisosActualesProvider);
    final visibles = _destinosMenu
        .where((d) => d.visiblePara(permisos))
        .toList();
    final esEscritorio = MediaQuery.sizeOf(context).width >= 840;
    final idx = _indiceActual(visibles);

    if (esEscritorio) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: idx,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (i) => context.go(visibles[i].ruta),
              destinations: [
                for (final d in visibles)
                  NavigationRailDestination(
                    icon: Icon(d.icono),
                    label: Text(d.etiqueta),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    final compactos = visibles.take(5).toList();
    final idxCompacto = idx < compactos.length ? idx : 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: compactos.length >= 2
          ? NavigationBar(
              selectedIndex: idxCompacto,
              onDestinationSelected: (i) => context.go(compactos[i].ruta),
              destinations: [
                for (final d in compactos)
                  NavigationDestination(icon: Icon(d.icono), label: d.etiqueta),
              ],
            )
          : null,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Rutas.inicio,
    routes: [
      GoRoute(
        path: Rutas.login,
        builder: (context, state) => const LoginPantalla(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            _ShellAdaptativo(ubicacion: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: Rutas.inicio,
            builder: (context, state) => const InicioPantalla(),
          ),
          GoRoute(
            path: Rutas.alertas,
            builder: (context, state) => const AlertasPantalla(),
          ),
          // Clientes
          GoRoute(
            path: Rutas.clientes,
            builder: (context, state) => const ClientesListaPantalla(),
          ),
          GoRoute(
            path: Rutas.clienteNuevo,
            builder: (context, state) => const ClienteFormularioPantalla(),
          ),
          GoRoute(
            path: '/clientes/:id',
            builder: (context, state) =>
                ClienteDetallePantalla(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/clientes/:id/editar',
            builder: (context, state) =>
                ClienteFormularioPantalla(id: state.pathParameters['id']!),
          ),
          // Pedidos
          GoRoute(
            path: Rutas.pedidos,
            builder: (context, state) => const PedidosListaPantalla(),
          ),
          GoRoute(
            path: Rutas.pedidosCalendario,
            builder: (context, state) => const PedidosCalendarioPantalla(),
          ),
          GoRoute(
            path: '/pedidos/nuevo',
            builder: (context, state) => PedidoFormularioPantalla(
              clienteIdInicial: state.uri.queryParameters['clienteId'],
            ),
          ),
          GoRoute(
            path: '/pedidos/:id',
            builder: (context, state) =>
                PedidoDetallePantalla(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/pedidos/:id/editar',
            builder: (context, state) =>
                PedidoFormularioPantalla(id: state.pathParameters['id']!),
          ),
          // Catálogo
          GoRoute(
            path: Rutas.productos,
            builder: (context, state) => const ProductosListaPantalla(),
          ),
          GoRoute(
            path: Rutas.productoNuevo,
            builder: (context, state) => const ProductoFormularioPantalla(),
          ),
          GoRoute(
            path: '/productos/:id/editar',
            builder: (context, state) =>
                ProductoFormularioPantalla(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: Rutas.recetas,
            builder: (context, state) => const RecetasListaPantalla(),
          ),
          GoRoute(
            path: Rutas.recetaNueva,
            builder: (context, state) => const RecetaFormularioPantalla(),
          ),
          GoRoute(
            path: '/recetas/:id/editar',
            builder: (context, state) =>
                RecetaFormularioPantalla(id: state.pathParameters['id']!),
          ),
          // Stock e insumos
          GoRoute(
            path: Rutas.stock,
            builder: (context, state) => const StockListaPantalla(),
          ),
          GoRoute(
            path: Rutas.insumoNuevo,
            builder: (context, state) => const InsumoFormularioPantalla(),
          ),
          GoRoute(
            path: '/stock/insumos/:id/editar',
            builder: (context, state) =>
                InsumoFormularioPantalla(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/stock/:insumoId/movimientos',
            builder: (context, state) => StockMovimientosPantalla(
              insumoId: state.pathParameters['insumoId']!,
            ),
          ),
          // Compras y proveedores
          GoRoute(
            path: Rutas.compras,
            builder: (context, state) => const ComprasListaPantalla(),
          ),
          GoRoute(
            path: Rutas.compraNueva,
            builder: (context, state) => const CompraFormularioPantalla(),
          ),
          GoRoute(
            path: Rutas.comprasSugeridas,
            builder: (context, state) => const ComprasSugeridasPantalla(),
          ),
          GoRoute(
            path: '/compras/:id',
            builder: (context, state) =>
                CompraDetallePantalla(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: Rutas.proveedores,
            builder: (context, state) => const ProveedoresListaPantalla(),
          ),
          GoRoute(
            path: Rutas.proveedorNuevo,
            builder: (context, state) => const ProveedorFormularioPantalla(),
          ),
          GoRoute(
            path: '/proveedores/:id/editar',
            builder: (context, state) =>
                ProveedorFormularioPantalla(id: state.pathParameters['id']!),
          ),
          // Producción
          GoRoute(
            path: Rutas.produccion,
            builder: (context, state) => const ProduccionListaPantalla(),
          ),
          GoRoute(
            path: '/produccion/nueva',
            builder: (context, state) => ProduccionFormularioPantalla(
              pedidoIdInicial: state.uri.queryParameters['pedidoId'],
            ),
          ),
          GoRoute(
            path: '/produccion/:id',
            builder: (context, state) =>
                ProduccionDetallePantalla(id: state.pathParameters['id']!),
          ),
          // Caja y gastos
          GoRoute(
            path: Rutas.caja,
            builder: (context, state) => const CajaPantalla(),
          ),
          GoRoute(
            path: Rutas.gastos,
            builder: (context, state) => const GastosListaPantalla(),
          ),
          GoRoute(
            path: Rutas.gastoNuevo,
            builder: (context, state) => const GastoFormularioPantalla(),
          ),
          GoRoute(
            path: Rutas.categoriasGasto,
            builder: (context, state) => const CategoriasGastoPantalla(),
          ),
          // Tareas
          GoRoute(
            path: Rutas.tareas,
            builder: (context, state) => const TareasPantalla(),
          ),
          GoRoute(
            path: Rutas.tareaNueva,
            builder: (context, state) => const TareaFormularioPantalla(),
          ),
          GoRoute(
            path: '/tareas/:id/editar',
            builder: (context, state) =>
                TareaFormularioPantalla(id: state.pathParameters['id']!),
          ),
          // Equipo y configuración
          GoRoute(
            path: Rutas.equipo,
            builder: (context, state) => const EquipoListaPantalla(),
          ),
          GoRoute(
            path: '/equipo/:perfilId/permisos',
            builder: (context, state) => EquipoPermisosPantalla(
              perfilId: state.pathParameters['perfilId']!,
            ),
          ),
          GoRoute(
            path: Rutas.configuracion,
            builder: (context, state) => const ConfiguracionPantalla(),
          ),
          // Reportes
          GoRoute(
            path: Rutas.reportes,
            builder: (context, state) => const ReportesPantalla(),
          ),
        ],
      ),
    ],
  );
});
