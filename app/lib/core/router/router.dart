import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';
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
    ruta: Rutas.recetas,
    etiqueta: 'Recetas',
    icono: Icons.menu_book_outlined,
    modulo: Modulo.produccion,
  ),
  _DestinoMenu(
    ruta: Rutas.reportes,
    etiqueta: 'Reportes',
    icono: Icons.bar_chart_outlined,
    modulo: Modulo.reportes,
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

class _IndicadorSyncCompacto extends StatelessWidget {
  const _IndicadorSyncCompacto({this.sync});
  final EstadoSync? sync;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final conectado = sync?.conectado ?? false;
    final pendientes = sync?.cambiosPendientes ?? 0;

    IconData icono = Icons.cloud_done_outlined;
    Color color = cs.primary;
    String texto = 'Al día';

    if (!conectado) {
      icono = Icons.cloud_off_outlined;
      color = cs.outline;
      texto = 'Offline';
    } else if (pendientes > 0) {
      icono = Icons.sync;
      color = cs.secondary;
      texto = '$pendientes pend.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

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

  Widget _iconoDestino(_DestinoMenu d, int noLeidas) {
    if (d.ruta == Rutas.alertas && noLeidas > 0) {
      return Badge.count(count: noLeidas, child: Icon(d.icono));
    }
    return Icon(d.icono);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permisos = ref.watch(permisosActualesProvider);
    final perfil = ref.watch(perfilActualProvider).value;
    final sync = ref.watch(estadoSyncProvider).value;
    final noLeidas = ref.watch(cantidadAlertasNoLeidasProvider).value ?? 0;

    final visibles = _destinosMenu
        .where((d) => d.visiblePara(permisos))
        .toList();
    final esEscritorio = MediaQuery.sizeOf(context).width >= 840;
    final idx = _indiceActual(visibles);
    final tema = Theme.of(context);

    if (esEscritorio) {
      return Scaffold(
        body: Row(
          children: [
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      selectedIndex: idx,
                      labelType: NavigationRailLabelType.all,
                      leading: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: tema.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.bakery_dining,
                                size: 26,
                                color: tema.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'JeRepostería',
                              style: tema.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _IndicadorSyncCompacto(sync: sync),
                            if (perfil != null) ...[
                              const SizedBox(height: 10),
                              Tooltip(
                                message:
                                    '${perfil.nombre} (${perfil.esJefe ? "Jefe" : "Empleado"})',
                                child: Avatar(perfil.nombre, radio: 16),
                              ),
                            ],
                          ],
                        ),
                      ),
                      onDestinationSelected: (i) =>
                          context.go(visibles[i].ruta),
                      destinations: [
                        for (final d in visibles)
                          NavigationRailDestination(
                            icon: _iconoDestino(d, noLeidas),
                            label: Text(d.etiqueta),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    final principales = visibles.take(4).toList();
    final tieneMas = visibles.length > 4;
    final idxCompacto = idx < principales.length ? idx : principales.length;
    final alertasEnMas =
        visibles.skip(4).any((d) => d.ruta == Rutas.alertas) && noLeidas > 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: principales.length >= 2
          ? NavigationBar(
              selectedIndex: tieneMas
                  ? idxCompacto
                  : idx.clamp(0, principales.length - 1),
              onDestinationSelected: (i) {
                if (tieneMas && i == principales.length) {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (ctx) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: tema.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.grid_view_rounded,
                                    size: 20,
                                    color: tema.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Más módulos',
                                    style: tema.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: visibles.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, idx) {
                                  final d = visibles[idx];
                                  final esSeleccionado =
                                      ubicacion == d.ruta ||
                                      (d.ruta != Rutas.inicio &&
                                          ubicacion.startsWith(d.ruta));
                                  final cs = Theme.of(context).colorScheme;
                                  return Material(
                                    color: esSeleccionado
                                        ? cs.primaryContainer.withValues(
                                            alpha: 0.5,
                                          )
                                        : cs.surfaceContainerLowest,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: esSeleccionado
                                            ? cs.primary
                                            : cs.outlineVariant.withValues(
                                                alpha: 0.65,
                                              ),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: _iconoDestino(d, noLeidas),
                                      title: Text(
                                        d.etiqueta,
                                        style: TextStyle(
                                          fontWeight: esSeleccionado
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      trailing:
                                          d.ruta == Rutas.alertas &&
                                              noLeidas > 0
                                          ? Badge.count(count: noLeidas)
                                          : const Icon(
                                              Icons.chevron_right,
                                              size: 20,
                                            ),
                                      selected: esSeleccionado,
                                      onTap: () {
                                        Navigator.of(ctx).pop();
                                        context.go(d.ruta);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  return;
                }
                context.go(principales[i].ruta);
              },
              destinations: [
                for (final d in principales)
                  NavigationDestination(
                    icon: _iconoDestino(d, noLeidas),
                    label: d.etiqueta,
                  ),
                if (tieneMas)
                  NavigationDestination(
                    icon: alertasEnMas
                        ? Badge.count(
                            count: noLeidas,
                            child: const Icon(Icons.menu),
                          )
                        : const Icon(Icons.menu),
                    label: 'Más',
                  ),
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
