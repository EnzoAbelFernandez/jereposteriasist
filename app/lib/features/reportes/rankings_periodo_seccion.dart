import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class RankingsPeriodoSeccion extends ConsumerWidget {
  const RankingsPeriodoSeccion({super.key, required this.periodo});

  final PeriodoMensual periodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRankings = ref.watch(rankingsPeriodoProvider(periodo));

    return VistaAsync<RankingsPeriodo>(
      valor: asyncRankings,
      builder: (context, rankings) {
        final tema = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TarjetaSeccion(
              titulo: 'Productos más vendidos del mes',
              children: [
                if (rankings.productosMasVendidos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Sin ventas confirmadas en este período',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < rankings.productosMasVendidos.length; i++)
                    _FilaProductoRanking(
                      posicion: i + 1,
                      producto: rankings.productosMasVendidos[i],
                    ),
              ],
            ),
            TarjetaSeccion(
              titulo: 'Mejores clientes del mes',
              children: [
                if (rankings.mejoresClientes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Sin pedidos de clientes en este período',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
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
                      subtitle: Text('${c.cantidadPedidos} pedido(s)'),
                      trailing: TextoDinero(c.montoTotal),
                      onTap: () => context.push(Rutas.cliente(c.clienteId)),
                    ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FilaProductoRanking extends StatelessWidget {
  const _FilaProductoRanking({required this.posicion, required this.producto});

  final int posicion;
  final RankingProducto producto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#$posicion',
              style: tema.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: tema.colorScheme.primary,
              ),
            ),
          ),
          Separacion.chica,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  producto.nombre,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
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
          TextoDinero(producto.ingresosTotales),
        ],
      ),
    );
  }
}
