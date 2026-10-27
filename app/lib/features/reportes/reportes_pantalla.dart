import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

import 'rankings_periodo_seccion.dart';

class ReportesPantalla extends ConsumerStatefulWidget {
  const ReportesPantalla({super.key});

  @override
  ConsumerState<ReportesPantalla> createState() => _ReportesPantallaState();
}

class _ReportesPantallaState extends ConsumerState<ReportesPantalla> {
  PeriodoMensual _periodo = PeriodoMensual.actual();

  Future<void> _exportarReporte() async {
    final csv = await ref
        .read(reportesRepositorioProvider)
        .exportarResumenCsv(_periodo);
    if (!mounted) return;
    await mostrarDialogoExportacion(
      context,
      titulo: 'Exportar reporte mensual (CSV)',
      nombreArchivo:
          'reporte_${_periodo.anio}_${_periodo.mes.toString().padLeft(2, '0')}.csv',
      contenido: csv,
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncResumen = ref.watch(resumenFinancieroMensualProvider(_periodo));

    return PantallaBase(
      titulo: 'Reportes',
      acciones: [
        IconButton(
          tooltip: 'Exportar reporte CSV',
          icon: const Icon(Icons.download_outlined),
          onPressed: _exportarReporte,
        ),
      ],
      cuerpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Mes anterior',
                  onPressed: () {
                    setState(() {
                      _periodo = _periodo.anterior;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _periodo.etiqueta,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Mes siguiente',
                  onPressed: () {
                    setState(() {
                      _periodo = _periodo.siguiente;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: VistaAsync<ResumenFinancieroMensual>(
              valor: asyncResumen,
              builder: (context, r) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final tarjetas = [
                            TarjetaMetrica(
                              titulo: 'Ingresos del mes',
                              valor: r.totalIngresos.formatear(),
                              color: ColorEstado.exito,
                              icono: Icons.trending_up,
                            ),
                            TarjetaMetrica(
                              titulo: 'Egresos del mes',
                              valor: r.totalEgresos.formatear(),
                              color: ColorEstado.peligro,
                              icono: Icons.trending_down,
                            ),
                            TarjetaMetrica(
                              titulo: 'Resultado neto',
                              valor: r.resultadoNeto.formatear(conSigno: true),
                              color: r.resultadoNeto.esNegativo
                                  ? ColorEstado.peligro
                                  : ColorEstado.info,
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
                      Separacion.media,
                      TarjetaSeccion(
                        titulo: 'Desglose de movimientos',
                        children: [
                          FilaDato(
                            etiqueta: 'Cobros de pedidos y señas',
                            valor: r.ingresosPedidos.formatear(),
                            icono: Icons.payments_outlined,
                          ),
                          FilaDato(
                            etiqueta: 'Otros ingresos',
                            valor: r.otrosIngresos.formatear(),
                            icono: Icons.add_circle_outline,
                          ),
                          FilaDato(
                            etiqueta: 'Compras de insumos',
                            valor: r.egresosCompras.formatear(),
                            icono: Icons.shopping_cart_outlined,
                          ),
                          FilaDato(
                            etiqueta: 'Gastos operativos',
                            valor: r.egresosGastos.formatear(),
                            icono: Icons.receipt_long_outlined,
                          ),
                          FilaDato(
                            etiqueta: 'Otros egresos',
                            valor: r.otrosEgresos.formatear(),
                            icono: Icons.remove_circle_outline,
                          ),
                          FilaDato(
                            etiqueta: 'Pedidos entregados',
                            valor: '${r.pedidosEntregados}',
                            icono: Icons.check_circle_outline,
                          ),
                          FilaDato(
                            etiqueta: 'Pedidos cancelados',
                            valor: '${r.pedidosCancelados}',
                            icono: Icons.cancel_outlined,
                          ),
                        ],
                      ),
                      TarjetaSeccion(
                        titulo: 'Gastos por categoría',
                        children: [
                          if (r.gastosPorCategoria.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No hay gastos registrados en este mes',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            )
                          else
                            for (final cat in r.gastosPorCategoria)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        cat.categoriaNombre,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Separacion.chica,
                                    SizedBox(
                                      width: 44,
                                      child: Text(
                                        '${cat.porcentajeEntero}%',
                                        textAlign: TextAlign.end,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    Separacion.chica,
                                    Expanded(
                                      flex: 3,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: (cat.porcentajeEntero / 100)
                                              .clamp(0.0, 1.0),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ),
                                    Separacion.media,
                                    TextoDinero(cat.monto),
                                  ],
                                ),
                              ),
                        ],
                      ),
                      RankingsPeriodoSeccion(periodo: _periodo),
                    ],
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
