import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

import 'dialogo_movimiento_caja.dart';

class CajaPantalla extends ConsumerStatefulWidget {
  const CajaPantalla({super.key});

  @override
  ConsumerState<CajaPantalla> createState() => _CajaPantallaState();
}

class _CajaPantallaState extends ConsumerState<CajaPantalla> {
  late DateTime _desde;
  late DateTime _hasta;
  TipoMovimientoCaja? _tipo;
  MedioPago? _medio;

  @override
  void initState() {
    super.initState();
    final inicial = FiltroCaja.mesActual();
    _desde = inicial.desde;
    _hasta = inicial.hasta;
  }

  FiltroCaja get _filtro =>
      FiltroCaja(desde: _desde, hasta: _hasta, tipo: _tipo, medio: _medio);

  void _mesAnterior() {
    final anterior = DateTime(_desde.year, _desde.month - 1, 1);
    setState(() {
      _desde = inicioDeMes(anterior);
      _hasta = finDeMes(anterior);
    });
  }

  void _mesSiguiente() {
    final siguiente = DateTime(_desde.year, _desde.month + 1, 1);
    setState(() {
      _desde = inicioDeMes(siguiente);
      _hasta = finDeMes(siguiente);
    });
  }

  Future<void> _elegirRangoFechas() async {
    final rango = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _desde, end: _hasta),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Elegí el período',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
    );
    if (rango != null) {
      setState(() {
        _desde = DateTime(
          rango.start.year,
          rango.start.month,
          rango.start.day,
          0,
          0,
          0,
        );
        _hasta = DateTime(
          rango.end.year,
          rango.end.month,
          rango.end.day,
          23,
          59,
          59,
          999,
        );
      });
    }
  }

  Future<void> _confirmarYAnular(
    BuildContext context,
    WidgetRef ref,
    MovimientoCaja m,
  ) async {
    final seguro = await confirmar(
      context,
      titulo: '¿Anular movimiento?',
      mensaje:
          '¿Seguro que querés anular "${m.descripcionTexto}" por ${m.monto.formatear()}?',
      textoConfirmar: 'Anular',
      peligroso: true,
    );
    if (!seguro || !context.mounted) return;

    await ejecutarConManejo(
      context,
      () => ref.read(cajaRepositorioProvider).anularMovimiento(m.id),
      mensajeExito: 'Movimiento anulado',
    );
  }

  Future<void> _exportarCsv() async {
    final csv = await ref.read(cajaRepositorioProvider).exportarCsv(_filtro);
    if (!mounted) return;
    await mostrarDialogoExportacion(
      context,
      titulo: 'Exportar movimientos de caja (CSV)',
      nombreArchivo:
          'caja_${_desde.year}_${_desde.month.toString().padLeft(2, '0')}.csv',
      contenido: csv,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtroActual = _filtro;
    final asyncResumen = ref.watch(resumenCajaProvider(filtroActual));
    final asyncMovimientos = ref.watch(movimientosCajaProvider(filtroActual));

    return PantallaBase(
      titulo: 'Caja',
      acciones: [
        IconButton(
          tooltip: 'Exportar CSV',
          icon: const Icon(Icons.download_outlined),
          onPressed: _exportarCsv,
        ),
      ],
      botonFlotante: RequierePermiso(
        modulo: Modulo.caja,
        nivel: NivelPermiso.cargar,
        child: FloatingActionButton.extended(
          onPressed: () => mostrarDialogoMovimientoCaja(context),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo movimiento'),
        ),
      ),
      cuerpo: Column(
        children: [
          _BarraPeriodo(
            desde: _desde,
            hasta: _hasta,
            onAnterior: _mesAnterior,
            onSiguiente: _mesSiguiente,
            onElegirRango: _elegirRangoFechas,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ChipsFiltro<TipoMovimientoCaja>(
                  opciones: TipoMovimientoCaja.values,
                  seleccionados: _tipo != null ? {_tipo!} : const {},
                  etiqueta: (t) => t.etiqueta,
                  multiple: false,
                  onChanged: (sel) =>
                      setState(() => _tipo = sel.isEmpty ? null : sel.first),
                ),
                ChipsFiltro<MedioPago>(
                  opciones: MedioPago.values,
                  seleccionados: _medio != null ? {_medio!} : const {},
                  etiqueta: (m) => m.etiqueta,
                  multiple: false,
                  onChanged: (sel) =>
                      setState(() => _medio = sel.isEmpty ? null : sel.first),
                ),
              ],
            ),
          ),
          Separacion.chica,
          Expanded(
            child: ListaAsync<MovimientoCaja>(
              valor: asyncMovimientos,
              separadores: false,
              encabezado: VistaAsync<ResumenCaja>(
                valor: asyncResumen,
                builder: (context, resumen) =>
                    _EncabezadoResumen(resumen: resumen),
              ),
              vacio: const EstadoVacio(
                icono: Icons.point_of_sale_outlined,
                mensaje: 'No hay movimientos en este período',
              ),
              itemBuilder: (context, m) {
                VoidCallback? onTap;
                if (m.pedidoId != null) {
                  onTap = () => context.push(Rutas.pedido(m.pedidoId!));
                } else if (m.compraId != null) {
                  onTap = () => context.push(Rutas.compra(m.compraId!));
                } else if (m.gastoId != null) {
                  onTap = () => context.push(Rutas.gastos);
                }

                final tema = Theme.of(context);
                final esIngreso = m.tipo == TipoMovimientoCaja.ingreso;
                final paleta = m.anulado
                    ? resolverColorEstado(context, ColorEstado.neutro)
                    : resolverColorEstado(
                        context,
                        esIngreso ? ColorEstado.exito : ColorEstado.peligro,
                      );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: tema.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: paleta.fondo,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              m.anulado
                                  ? Icons.block_outlined
                                  : (esIngreso
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward),
                              color: paleta.frente,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.descripcionTexto,
                                        style: tema.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              decoration: m.anulado
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (m.anulado) ...[
                                      Separacion.chica,
                                      const InsigniaEstado(
                                        texto: 'Anulado',
                                        color: ColorEstado.neutro,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 2,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      formatearFechaHora(m.fecha),
                                      style: tema.textTheme.bodySmall?.copyWith(
                                        color:
                                            tema.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      '•',
                                      style: tema.textTheme.bodySmall?.copyWith(
                                        color: tema.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          m.medioPago.icono,
                                          size: 14,
                                          color:
                                              tema.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          m.medioPago.etiqueta,
                                          style: tema.textTheme.bodySmall
                                              ?.copyWith(
                                                color: tema
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '•',
                                      style: tema.textTheme.bodySmall?.copyWith(
                                        color: tema.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tema
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        m.concepto.etiqueta,
                                        style: tema.textTheme.labelSmall
                                            ?.copyWith(
                                              fontSize: 10,
                                              color: tema
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextoDinero(
                                m.montoConSigno,
                                colorear: !m.anulado,
                                conSigno: true,
                                estilo: tema.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (m.anulable) ...[
                                const SizedBox(height: 2),
                                RequierePermiso(
                                  modulo: Modulo.caja,
                                  nivel: NivelPermiso.editar,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(4),
                                    onTap: () =>
                                        _confirmarYAnular(context, ref, m),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.undo,
                                        size: 18,
                                        color:
                                            tema.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (onTap != null) ...[
                                const SizedBox(height: 2),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: tema.colorScheme.outlineVariant,
                                ),
                              ],
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

class _BarraPeriodo extends StatelessWidget {
  const _BarraPeriodo({
    required this.desde,
    required this.hasta,
    required this.onAnterior,
    required this.onSiguiente,
    required this.onElegirRango,
  });

  final DateTime desde;
  final DateTime hasta;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  final VoidCallback onElegirRango;

  bool get _esMesCompleto =>
      desde.day == 1 &&
      hasta.year == desde.year &&
      hasta.month == desde.month &&
      hasta.day == finDeMes(desde).day;

  String get _textoPeriodo {
    if (_esMesCompleto) {
      return formatearMesAnio(desde);
    }
    return '${formatearFechaCorta(desde)} - ${formatearFechaCorta(hasta)}';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: tema.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tema.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Mes anterior',
              onPressed: onAnterior,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onElegirRango,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: tema.colorScheme.primary,
                    ),
                    Separacion.chica,
                    Text(
                      _textoPeriodo,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Mes siguiente',
              onPressed: onSiguiente,
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoResumen extends StatelessWidget {
  const _EncabezadoResumen({required this.resumen});

  final ResumenCaja resumen;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final tarjetas = [
                TarjetaMetrica(
                  titulo: 'Ingresos',
                  valor: resumen.ingresos.formatear(),
                  color: ColorEstado.exito,
                  icono: Icons.arrow_downward,
                ),
                TarjetaMetrica(
                  titulo: 'Egresos',
                  valor: resumen.egresos.formatear(),
                  color: ColorEstado.peligro,
                  icono: Icons.arrow_upward,
                ),
                TarjetaMetrica(
                  titulo: 'Saldo neto',
                  valor: resumen.saldo.formatear(),
                  color: resumen.saldo.esNegativo
                      ? ColorEstado.peligro
                      : (resumen.saldo.esPositivo
                            ? ColorEstado.exito
                            : ColorEstado.neutro),
                  icono: Icons.account_balance_wallet_outlined,
                ),
              ];

              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    for (var i = 0; i < tarjetas.length; i++) ...[
                      if (i > 0) Separacion.chica,
                      tarjetas[i],
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < tarjetas.length; i++) ...[
                    if (i > 0) Separacion.chica,
                    Expanded(child: tarjetas[i]),
                  ],
                ],
              );
            },
          ),
          Separacion.chica,
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 16,
                        color: tema.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Desglose por medio de pago',
                        style: tema.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final items = [
                        for (final medio in MedioPago.values)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: tema.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: tema.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    medio.icono,
                                    size: 18,
                                    color: tema.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      medio.etiqueta,
                                      style: tema.textTheme.labelSmall
                                          ?.copyWith(
                                            color: tema
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    TextoDinero(
                                      resumen.saldoPorMedio[medio] ??
                                          Dinero.cero,
                                      estilo: tema.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ];

                      if (constraints.maxWidth < 500) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: items
                              .map(
                                (item) => SizedBox(
                                  width: (constraints.maxWidth - 24) / 2,
                                  child: item,
                                ),
                              )
                              .toList(),
                        );
                      }

                      return Row(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(child: items[i]),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
