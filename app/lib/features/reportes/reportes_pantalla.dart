import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

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
    final tema = Theme.of(context);
    final asyncResumen = ref.watch(resumenFinancieroMensualProvider(_periodo));
    final asyncRankings = ref.watch(rankingsPeriodoProvider(_periodo));

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
                    onPressed: () {
                      setState(() {
                        _periodo = _periodo.anterior;
                      });
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        size: 18,
                        color: tema.colorScheme.primary,
                      ),
                      Separacion.chica,
                      Text(
                        _periodo.etiqueta,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
          ),
          Expanded(
            child: VistaAsync<ResumenFinancieroMensual>(
              valor: asyncResumen,
              builder: (context, r) {
                final rentabilidadEntera = r.totalIngresos.centavos > 0
                    ? ((r.resultadoNeto.centavos * 100) /
                              r.totalIngresos.centavos)
                          .round()
                    : 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final tarjetas = [
                            TarjetaMetrica(
                              titulo: 'Ventas e ingresos',
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
                                  : ColorEstado.exito,
                              icono: Icons.account_balance_wallet_outlined,
                            ),
                            TarjetaMetrica(
                              titulo: 'Rentabilidad neta',
                              valor: r.totalIngresos.centavos > 0
                                  ? '$rentabilidadEntera%'
                                  : '0%',
                              color: rentabilidadEntera >= 0
                                  ? ColorEstado.info
                                  : ColorEstado.peligro,
                              icono: Icons.query_stats_outlined,
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

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: tarjetas[0]),
                                  Separacion.chica,
                                  Expanded(child: tarjetas[1]),
                                ],
                              ),
                              Separacion.chica,
                              Row(
                                children: [
                                  Expanded(child: tarjetas[2]),
                                  Separacion.chica,
                                  Expanded(child: tarjetas[3]),
                                ],
                              ),
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
                                style: tema.textTheme.bodyMedium?.copyWith(
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            for (final cat in r.gastosPorCategoria)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.label_outline,
                                          size: 15,
                                          color: tema.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            cat.categoriaNombre,
                                            style: tema.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tema
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${cat.porcentajeEntero}%',
                                            style: tema.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      tema.colorScheme.primary,
                                                ),
                                          ),
                                        ),
                                        Separacion.media,
                                        TextoDinero(
                                          cat.monto,
                                          estilo: tema.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (cat.porcentajeEntero / 100)
                                            .clamp(0.0, 1.0),
                                        minHeight: 7,
                                        backgroundColor: tema
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        color: tema.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                      VistaAsync<RankingsPeriodo>(
                        valor: asyncRankings,
                        builder: (context, rankings) {
                          final maxUnidades =
                              rankings.productosMasVendidos.isEmpty
                              ? 1
                              : rankings.productosMasVendidos
                                    .map((p) => p.unidadesVendidas)
                                    .reduce((a, b) => a > b ? a : b);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TarjetaSeccion(
                                titulo: 'Productos más vendidos del mes',
                                children: [
                                  if (rankings.productosMasVendidos.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'Sin ventas confirmadas en este período',
                                        style: tema.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: tema
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    )
                                  else
                                    for (
                                      var i = 0;
                                      i < rankings.productosMasVendidos.length;
                                      i++
                                    ) ...[
                                      _FilaProductoConBarra(
                                        posicion: i + 1,
                                        producto:
                                            rankings.productosMasVendidos[i],
                                        maxUnidades: maxUnidades,
                                      ),
                                      if (i <
                                          rankings.productosMasVendidos.length -
                                              1)
                                        const SizedBox(height: 6),
                                    ],
                                ],
                              ),
                              TarjetaSeccion(
                                titulo: 'Mejores clientes del mes',
                                children: [
                                  if (rankings.mejoresClientes.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'Sin pedidos de clientes en este período',
                                        style: tema.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: tema
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    )
                                  else
                                    for (final c in rankings.mejoresClientes)
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Avatar(c.nombre),
                                        title: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                c.nombre,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (c.esHabitual) ...[
                                              Separacion.chica,
                                              const InsigniaHabitual(),
                                            ],
                                          ],
                                        ),
                                        subtitle: Text(
                                          '${c.cantidadPedidos} pedido(s)',
                                        ),
                                        trailing: TextoDinero(c.montoTotal),
                                        onTap: () => context.push(
                                          Rutas.cliente(c.clienteId),
                                        ),
                                      ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
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

class _FilaProductoConBarra extends StatelessWidget {
  const _FilaProductoConBarra({
    required this.posicion,
    required this.producto,
    required this.maxUnidades,
  });

  final int posicion;
  final RankingProducto producto;
  final int maxUnidades;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final fraccionProgreso = maxUnidades > 0
        ? (producto.unidadesVendidas / maxUnidades).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: posicion <= 3
                      ? tema.colorScheme.primaryContainer
                      : tema.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '#$posicion',
                  style: tema.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: posicion <= 3
                        ? tema.colorScheme.primary
                        : tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${producto.unidadesVendidas} u. vendidas',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Separacion.media,
              TextoDinero(
                producto.ingresosTotales,
                estilo: tema.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraccionProgreso,
              minHeight: 6,
              backgroundColor: tema.colorScheme.surfaceContainerHighest,
              color: tema.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
