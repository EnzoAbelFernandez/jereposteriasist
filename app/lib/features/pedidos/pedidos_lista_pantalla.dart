import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class PedidosListaPantalla extends ConsumerStatefulWidget {
  const PedidosListaPantalla({super.key});

  @override
  ConsumerState<PedidosListaPantalla> createState() =>
      _PedidosListaPantallaState();
}

class _PedidosListaPantallaState extends ConsumerState<PedidosListaPantalla> {
  String _busqueda = '';
  Set<EstadoPedido> _estados = const {
    EstadoPedido.presupuesto,
    EstadoPedido.confirmado,
    EstadoPedido.enProduccion,
    EstadoPedido.listo,
  };

  Widget _construirIndicadorSaldo(BuildContext context, PedidoResumen r) {
    final tema = Theme.of(context);
    if (r.pedido.estado == EstadoPedido.cancelado) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: tema.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Cancelado',
          style: tema.textTheme.labelSmall?.copyWith(
            color: tema.colorScheme.outline,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (r.pagadoCompleto) {
      final paletaExito = resolverColorEstado(context, ColorEstado.exito);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: paletaExito.fondo,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: paletaExito.frente,
            ),
            const SizedBox(width: 4),
            Text(
              'Pagado',
              style: tema.textTheme.labelSmall?.copyWith(
                color: paletaExito.frente,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final paletaPeligro = resolverColorEstado(context, ColorEstado.peligro);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: paletaPeligro.fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pending_actions_outlined,
            size: 14,
            color: paletaPeligro.frente,
          ),
          const SizedBox(width: 4),
          Text(
            'Adeuda ',
            style: tema.textTheme.labelSmall?.copyWith(
              color: paletaPeligro.frente,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextoDinero(
            r.saldo,
            estilo: tema.textTheme.labelSmall?.copyWith(
              color: paletaPeligro.frente,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final asyncPedidos = ref.watch(
      pedidosProvider(FiltroPedidos(estados: _estados, busqueda: _busqueda)),
    );

    return PantallaBase(
      titulo: 'Pedidos',
      acciones: [
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: 'Ver calendario',
          onPressed: () => context.push(Rutas.pedidosCalendario),
        ),
      ],
      botonFlotante: RequierePermiso(
        modulo: Modulo.pedidos,
        nivel: NivelPermiso.cargar,
        child: FloatingActionButton.extended(
          onPressed: () => context.push(Rutas.pedidoNuevo()),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo pedido'),
        ),
      ),
      cuerpo: Column(
        children: [
          CampoBusqueda(
            hint: 'Buscar por cliente o número...',
            onChanged: (v) => setState(() => _busqueda = v),
          ),
          ChipsFiltro<EstadoPedido>(
            opciones: EstadoPedido.values,
            seleccionados: _estados,
            etiqueta: (e) => e.etiqueta,
            multiple: true,
            onChanged: (nuevos) => setState(() => _estados = nuevos),
          ),
          Expanded(
            child: ListaAsync<PedidoResumen>(
              valor: asyncPedidos,
              separadores: false,
              vacio: EstadoVacio(
                icono: Icons.receipt_long_outlined,
                mensaje: 'No hay pedidos para el filtro seleccionado',
                textoAccion: 'Nuevo pedido',
                onAccion: () => context.push(Rutas.pedidoNuevo()),
              ),
              itemBuilder: (context, r) {
                final tienePrimerItem =
                    r.primerItem != null && r.primerItem!.isNotEmpty;
                final resumenItems = tienePrimerItem
                    ? (r.cantidadItems > 1
                          ? '${r.primerItem!} + ${r.cantidadItems - 1} más'
                          : r.primerItem!)
                    : null;

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: tema.colorScheme.outlineVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push(Rutas.pedido(r.pedido.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: tema.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  r.pedido.numeroTexto,
                                  style: tema.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: tema.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              Separacion.chica,
                              Expanded(
                                child: Text(
                                  r.clienteNombre,
                                  style: tema.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Separacion.chica,
                              InsigniaEstadoPedido(r.pedido.estado),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                r.pedido.tipoEntrega == TipoEntrega.envio
                                    ? Icons.local_shipping_outlined
                                    : Icons.storefront_outlined,
                                size: 16,
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${formatearFechaHora(r.pedido.fechaEntrega)} • ${r.pedido.tipoEntrega.etiqueta}',
                                  style: tema.textTheme.bodyMedium?.copyWith(
                                    color: tema.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (resumenItems != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.cake_outlined,
                                  size: 16,
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    resumenItems,
                                    style: tema.textTheme.bodySmall?.copyWith(
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: tema.colorScheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Total: ',
                                    style: tema.textTheme.bodySmall?.copyWith(
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  TextoDinero(
                                    r.total,
                                    estilo: tema.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              _construirIndicadorSaldo(context, r),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
