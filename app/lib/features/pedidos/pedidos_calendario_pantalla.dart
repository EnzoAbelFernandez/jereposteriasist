import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class PedidosCalendarioPantalla extends ConsumerStatefulWidget {
  const PedidosCalendarioPantalla({super.key});

  @override
  ConsumerState<PedidosCalendarioPantalla> createState() =>
      _PedidosCalendarioPantallaState();
}

class _PedidosCalendarioPantallaState
    extends ConsumerState<PedidosCalendarioPantalla> {
  static const Set<EstadoPedido> _estadosSinCancelados = {
    EstadoPedido.presupuesto,
    EstadoPedido.confirmado,
    EstadoPedido.enProduccion,
    EstadoPedido.listo,
    EstadoPedido.entregado,
  };

  static const List<String> _diasSemana = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  late DateTime _mesActual;
  late DateTime _diaSeleccionado;

  @override
  void initState() {
    super.initState();
    _diaSeleccionado = hoy();
    _mesActual = inicioDeMes(_diaSeleccionado);
  }

  void _cambiarMes(int deltaMeses) {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + deltaMeses, 1);
      if (_diaSeleccionado.year != _mesActual.year ||
          _diaSeleccionado.month != _mesActual.month) {
        final ahora = hoy();
        if (ahora.year == _mesActual.year && ahora.month == _mesActual.month) {
          _diaSeleccionado = ahora;
        } else {
          _diaSeleccionado = _mesActual;
        }
      }
    });
  }

  void _irAHoy() {
    setState(() {
      _diaSeleccionado = hoy();
      _mesActual = inicioDeMes(_diaSeleccionado);
    });
  }

  int _contarEntregas(DateTime dia, List<PedidoResumen> pedidos) {
    var total = 0;
    for (final p in pedidos) {
      if (esMismoDia(p.pedido.fechaEntrega, dia)) {
        total++;
      }
    }
    return total;
  }

  Widget _construirIndicadorSaldo(BuildContext context, PedidoResumen r) {
    final tema = Theme.of(context);
    if (r.pedido.estado == EstadoPedido.cancelado) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: tema.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Cancelado',
          style: tema.textTheme.labelSmall?.copyWith(
            color: tema.colorScheme.outline,
          ),
        ),
      );
    }

    if (r.pagadoCompleto) {
      final paletaExito = resolverColorEstado(context, ColorEstado.exito);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: paletaExito.fondo,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: paletaPeligro.fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pending_actions_outlined,
            size: 13,
            color: paletaPeligro.frente,
          ),
          const SizedBox(width: 3),
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
    final filtro = FiltroPedidos(
      desde: inicioDeMes(_mesActual),
      hasta: finDeMes(_mesActual),
      estados: _estadosSinCancelados,
    );

    final asyncPedidos = ref.watch(pedidosProvider(filtro));
    final pedidosDelMes = asyncPedidos.asData?.value ?? const <PedidoResumen>[];

    final asyncPedidosDelDia = asyncPedidos.whenData((todos) {
      final delDia =
          todos
              .where((r) => esMismoDia(r.pedido.fechaEntrega, _diaSeleccionado))
              .toList()
            ..sort(
              (a, b) => a.pedido.fechaEntrega.compareTo(b.pedido.fechaEntrega),
            );
      return delDia;
    });

    final totalEntregasDia = _contarEntregas(_diaSeleccionado, pedidosDelMes);

    return PantallaBase(
      titulo: 'Calendario de entregas',
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
          _construirNavegacionMes(context),
          _construirCabeceraSemana(tema),
          _construirGrillaMes(context, pedidosDelMes),
          Separacion.chica,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 20,
                        color: tema.colorScheme.primary,
                      ),
                      Separacion.chica,
                      Text(
                        formatearFecha(_diaSeleccionado),
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Separacion.chica,
                      Text(
                        '(${formatearDiaSemana(_diaSeleccionado)})',
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          totalEntregasDia == 1
                              ? '1 entrega'
                              : '$totalEntregasDia entregas',
                          style: tema.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tema.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListaAsync<PedidoResumen>(
                    valor: asyncPedidosDelDia,
                    separadores: false,
                    vacio: const EstadoVacio(
                      icono: Icons.event_available,
                      mensaje: 'No hay entregas para este día',
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
                          vertical: 5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: tema.colorScheme.outlineVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => context.push(Rutas.pedido(r.pedido.id)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            tema.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 14,
                                            color: tema
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            formatearHora(
                                              r.pedido.fechaEntrega,
                                            ),
                                            style: tema.textTheme.labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: tema
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tema
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        r.pedido.numeroTexto,
                                        style: tema.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        r.clienteNombre,
                                        style: tema.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InsigniaEstadoPedido(r.pedido.estado),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      r.pedido.tipoEntrega == TipoEntrega.envio
                                          ? Icons.local_shipping_outlined
                                          : Icons.storefront_outlined,
                                      size: 15,
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      r.pedido.tipoEntrega.etiqueta,
                                      style: tema.textTheme.bodySmall?.copyWith(
                                        color:
                                            tema.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (resumenItems != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '•',
                                        style: TextStyle(
                                          color:
                                              tema.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          resumenItems,
                                          style: tema.textTheme.bodySmall
                                              ?.copyWith(
                                                color: tema
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Divider(
                                  height: 1,
                                  color: tema.colorScheme.outlineVariant
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Total: ',
                                          style: tema.textTheme.bodySmall
                                              ?.copyWith(
                                                color: tema
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        TextoDinero(
                                          r.total,
                                          estilo: tema.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
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
          ),
        ],
      ),
    );
  }

  Widget _construirNavegacionMes(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mes anterior',
            onPressed: () => _cambiarMes(-1),
          ),
          Expanded(
            child: Center(
              child: Text(
                formatearMesAnio(_mesActual),
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Mes siguiente',
            onPressed: () => _cambiarMes(1),
          ),
          Separacion.chica,
          OutlinedButton(onPressed: _irAHoy, child: const Text('Hoy')),
        ],
      ),
    );
  }

  Widget _construirCabeceraSemana(ThemeData tema) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final dia in _diasSemana)
            Expanded(
              child: Center(
                child: Text(
                  dia,
                  style: tema.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirGrillaMes(
    BuildContext context,
    List<PedidoResumen> pedidosDelMes,
  ) {
    final tema = Theme.of(context);
    final primerDia = inicioDeMes(_mesActual);
    final primerDiaSemana = primerDia.weekday; // 1 = Lunes, 7 = Domingo
    final diasEnMes = DateTime(_mesActual.year, _mesActual.month + 1, 0).day;
    final offsetInicio = primerDiaSemana - 1;
    final totalCeldas = offsetInicio + diasEnMes;
    final totalFilas = (totalCeldas / 7).ceil();

    final filas = <Widget>[];
    for (var fila = 0; fila < totalFilas; fila++) {
      final celdas = <Widget>[];
      for (var col = 0; col < 7; col++) {
        final indice = fila * 7 + col;
        final diaNumero = indice - offsetInicio + 1;
        if (diaNumero < 1 || diaNumero > diasEnMes) {
          celdas.add(const Expanded(child: SizedBox(height: 48)));
        } else {
          final fechaDia = DateTime(
            _mesActual.year,
            _mesActual.month,
            diaNumero,
          );
          final esSeleccionado = esMismoDia(fechaDia, _diaSeleccionado);
          final esHoy = esMismoDia(fechaDia, hoy());
          final cantidadEntregas = _contarEntregas(fechaDia, pedidosDelMes);

          celdas.add(
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: InkWell(
                  onTap: () => setState(() => _diaSeleccionado = fechaDia),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: esSeleccionado
                          ? tema.colorScheme.primary
                          : (esHoy
                                ? tema.colorScheme.surfaceContainerHighest
                                : null),
                      borderRadius: BorderRadius.circular(8),
                      border: esHoy && !esSeleccionado
                          ? Border.all(
                              color: tema.colorScheme.primary,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$diaNumero',
                          style: tema.textTheme.bodyMedium?.copyWith(
                            fontWeight: esSeleccionado || esHoy
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: esSeleccionado
                                ? tema.colorScheme.onPrimary
                                : (esHoy
                                      ? tema.colorScheme.primary
                                      : tema.colorScheme.onSurface),
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (cantidadEntregas > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 0.5,
                            ),
                            decoration: BoxDecoration(
                              color: esSeleccionado
                                  ? tema.colorScheme.onPrimary
                                  : tema.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$cantidadEntregas',
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                fontWeight: FontWeight.bold,
                                color: esSeleccionado
                                    ? tema.colorScheme.primary
                                    : tema.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
      filas.add(Row(children: celdas));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: filas),
    );
  }
}
