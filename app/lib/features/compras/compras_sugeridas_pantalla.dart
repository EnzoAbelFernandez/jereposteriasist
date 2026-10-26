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

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: resumen.items.length + 1,
                  separatorBuilder: (context, index) {
                    if (index == 0) return const SizedBox.shrink();
                    return const Divider(height: 1);
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) return encabezado;
                    final item = resumen.items[index - 1];

                    return ListTile(
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.insumo.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Separacion.chica,
                          InsigniaEstado(
                            texto: 'Comprar ${item.sugeridoTexto}',
                            color: ColorEstado.advertencia,
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'En stock: ${item.stockActualTexto} · Mínimo: ${item.stockMinimoTexto} · Para pedidos: ${item.requeridoTexto}',
                      ),
                      trailing: item.costoEstimado != null
                          ? TextoDinero(item.costoEstimado!)
                          : null,
                      onTap: () =>
                          context.push(Rutas.stockMovimientos(item.insumo.id)),
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
