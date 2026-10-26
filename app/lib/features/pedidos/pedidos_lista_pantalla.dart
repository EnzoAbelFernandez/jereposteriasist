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
              vacio: const EstadoVacio(
                icono: Icons.receipt_long_outlined,
                mensaje: 'No hay pedidos para el filtro seleccionado',
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
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ListTile(
                    isThreeLine: true,
                    title: Row(
                      children: [
                        Text(
                          r.pedido.numeroTexto,
                          style: tema.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Separacion.chica,
                        Expanded(
                          child: Text(
                            r.clienteNombre,
                            style: tema.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Separacion.chica,
                        InsigniaEstadoPedido(r.pedido.estado),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Separacion.chica,
                        Text(
                          'Entrega: ${formatearFechaHora(r.pedido.fechaEntrega)} (${r.pedido.tipoEntrega.etiqueta})',
                        ),
                        if (resumenItems != null) ...[
                          Separacion.chica,
                          Text(resumenItems, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextoDinero(
                          r.total,
                          estilo: tema.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!r.pagadoCompleto &&
                            r.pedido.estado != EstadoPedido.cancelado)
                          Text(
                            'Resta ${r.saldo.formatear()}',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: tema.colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else if (r.pagadoCompleto)
                          Text(
                            'Pagado',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: tema.colorScheme.tertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    onTap: () => context.push(Rutas.pedido(r.pedido.id)),
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
