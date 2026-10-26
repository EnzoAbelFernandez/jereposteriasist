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

  @override
  Widget build(BuildContext context) {
    final filtroActual = _filtro;
    final asyncResumen = ref.watch(resumenCajaProvider(filtroActual));
    final asyncMovimientos = ref.watch(movimientosCajaProvider(filtroActual));

    return PantallaBase(
      titulo: 'Caja',
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
          Expanded(
            child: ListaAsync<MovimientoCaja>(
              valor: asyncMovimientos,
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

                return ListTile(
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          m.descripcionTexto,
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
                  subtitle: Text(
                    '${formatearFechaHora(m.fecha)} · ${m.medioPago.etiqueta} · ${m.concepto.etiqueta}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextoDinero(
                        m.montoConSigno,
                        colorear: true,
                        conSigno: true,
                      ),
                      if (m.anulable) ...[
                        Separacion.chica,
                        RequierePermiso(
                          modulo: Modulo.caja,
                          nivel: NivelPermiso.editar,
                          child: IconButton(
                            icon: const Icon(Icons.undo),
                            tooltip: 'Anular movimiento',
                            onPressed: () => _confirmarYAnular(context, ref, m),
                          ),
                        ),
                      ] else if (onTap != null) ...[
                        Separacion.chica,
                        const Icon(Icons.chevron_right),
                      ],
                    ],
                  ),
                  onTap: onTap,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  Separacion.chica,
                  Text(
                    _textoPeriodo,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
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
    );
  }
}

class _EncabezadoResumen extends StatelessWidget {
  const _EncabezadoResumen({required this.resumen});

  final ResumenCaja resumen;

  @override
  Widget build(BuildContext context) {
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
                  titulo: 'Saldo',
                  valor: resumen.saldo.formatear(),
                  color: ColorEstado.neutro,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final items = [
                    for (final medio in MedioPago.values)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            medio.icono,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          Separacion.chica,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                medio.etiqueta,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              TextoDinero(
                                resumen.saldoPorMedio[medio] ?? Dinero.cero,
                                estilo: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ];

                  if (constraints.maxWidth < 450) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceAround,
                      children: items,
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: items,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
