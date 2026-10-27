import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class ComprasSugeridasPantalla extends ConsumerStatefulWidget {
  const ComprasSugeridasPantalla({super.key});

  @override
  ConsumerState<ComprasSugeridasPantalla> createState() =>
      _ComprasSugeridasPantallaState();
}

class _ComprasSugeridasPantallaState
    extends ConsumerState<ComprasSugeridasPantalla> {
  int _diasHorizonte = 7;

  @override
  Widget build(BuildContext context) {
    final asyncResumen = ref.watch(comprasSugeridasProvider(_diasHorizonte));

    return PantallaBase(
      titulo: 'Compras sugeridas',
      botonFlotante: RequierePermiso(
        modulo: Modulo.compras,
        nivel: NivelPermiso.cargar,
        child: FloatingActionButton.extended(
          onPressed: () => context.push(Rutas.compraNueva),
          icon: const Icon(Icons.add),
          label: const Text('Registrar compra'),
        ),
      ),
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChipsFiltro<int>(
            opciones: const [3, 7, 14, 30],
            seleccionados: {_diasHorizonte},
            multiple: false,
            etiqueta: (d) => 'Próximos $d días',
            onChanged: (nuevos) {
              if (nuevos.isNotEmpty) {
                setState(() => _diasHorizonte = nuevos.first);
              }
            },
          ),
          Expanded(
            child: VistaAsync<ResumenComprasSugeridas>(
              valor: asyncResumen,
              builder: (context, resumen) {
                final encabezado = Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tarjetas = [
                        TarjetaMetrica(
                          titulo: 'Pedidos activos',
                          valor: '${resumen.pedidosActivosEnHorizonte}',
                          icono: Icons.receipt_long_outlined,
                        ),
                        TarjetaMetrica(
                          titulo: 'Insumos a reponer',
                          valor: '${resumen.items.length}',
                          icono: Icons.inventory_2_outlined,
                          color: resumen.items.isNotEmpty
                              ? ColorEstado.advertencia
                              : ColorEstado.neutro,
                        ),
                        TarjetaMetrica(
                          titulo: 'Costo total estimado',
                          valor: resumen.costoTotalEstimado.formatear(),
                          icono: Icons.payments_outlined,
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
                );

                if (resumen.items.isEmpty) {
                  return Column(
                    children: [
                      encabezado,
                      const Expanded(
                        child: EstadoVacio(
                          icono: Icons.check_circle_outline,
                          mensaje: 'Tenés stock suficiente para cubrir los pedidos y el stock mínimo',
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: resumen.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return encabezado;
                    final item = resumen.items[index - 1];
                    final tema = Theme.of(context);
                    final paletaAdvertencia = resolverColorEstado(
                      context,
                      ColorEstado.advertencia,
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: tema.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: paletaAdvertencia.fondo,
                                  foregroundColor: paletaAdvertencia.frente,
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.insumo.nombre,
                                    style: tema.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                InsigniaEstado(
                                  texto: 'Comprar ${item.sugeridoTexto}',
                                  color: ColorEstado.advertencia,
                                  icono: Icons.add_shopping_cart,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: tema.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        'En stock',
                                        style: tema.textTheme.labelSmall
                                            ?.copyWith(
                                              color: tema
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.stockActualTexto,
                                        style: tema.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: 24,
                                    width: 1,
                                    color: tema.colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        'Mínimo',
                                        style: tema.textTheme.labelSmall
                                            ?.copyWith(
                                              color: tema
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.stockMinimoTexto,
                                        style: tema.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: 24,
                                    width: 1,
                                    color: tema.colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        'Para pedidos',
                                        style: tema.textTheme.labelSmall
                                            ?.copyWith(
                                              color: tema
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.requeridoTexto,
                                        style: tema.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (item.costoEstimado != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Costo estimado de reposición:',
                                    style: tema.textTheme.bodySmall?.copyWith(
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  TextoDinero(
                                    item.costoEstimado!,
                                    estilo: tema.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => context.push(
                                    Rutas.stockMovimientos(item.insumo.id),
                                  ),
                                  icon: const Icon(Icons.history, size: 16),
                                  label: const Text('Movimientos'),
                                ),
                                const SizedBox(width: 8),
                                RequierePermiso(
                                  modulo: Modulo.compras,
                                  nivel: NivelPermiso.cargar,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () =>
                                        context.push(Rutas.compraNueva),
                                    icon: const Icon(
                                      Icons.add_shopping_cart,
                                      size: 16,
                                    ),
                                    label: const Text('Cargar compra'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
