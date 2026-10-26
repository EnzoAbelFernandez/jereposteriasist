import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

import 'dialogos_stock.dart';

class StockListaPantalla extends ConsumerStatefulWidget {
  const StockListaPantalla({super.key});

  @override
  ConsumerState<StockListaPantalla> createState() => _StockListaPantallaState();
}

class _StockListaPantallaState extends ConsumerState<StockListaPantalla> {
  String _busqueda = '';
  bool _soloFaltantes = false;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final asyncInsumos = ref.watch(
      insumosConStockProvider(
        FiltroStock(busqueda: _busqueda, soloFaltantes: _soloFaltantes),
      ),
    );
    final cantidadFaltantes =
        ref.watch(cantidadFaltantesProvider).asData?.value ?? 0;
    final permisos = ref.watch(permisosActualesProvider);
    final puedeCargar = permisos.puede(Modulo.stock, NivelPermiso.cargar);
    final puedeEditar = permisos.puede(Modulo.stock, NivelPermiso.editar);

    final etiquetaFiltro = cantidadFaltantes > 0
        ? 'Solo faltantes ($cantidadFaltantes)'
        : 'Solo faltantes';

    return PantallaBase(
      titulo: 'Stock de insumos',
      botonFlotante: RequierePermiso(
        modulo: Modulo.stock,
        nivel: NivelPermiso.cargar,
        child: FloatingActionButton.extended(
          onPressed: () => context.push(Rutas.insumoNuevo),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo insumo'),
        ),
      ),
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampoBusqueda(
            hint: 'Buscar insumo...',
            onChanged: (v) => setState(() => _busqueda = v),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FilterChip(
              label: Text(etiquetaFiltro),
              selected: _soloFaltantes,
              onSelected: (seleccionado) {
                setState(() => _soloFaltantes = seleccionado);
              },
            ),
          ),
          Expanded(
            child: ListaAsync<InsumoConStock>(
              valor: asyncInsumos,
              vacio: _soloFaltantes
                  ? const EstadoVacio(
                      icono: Icons.check_circle_outline,
                      mensaje: 'No hay insumos en falta',
                    )
                  : const EstadoVacio(
                      icono: Icons.inventory_2_outlined,
                      mensaje: 'Todavía no cargaste insumos',
                    ),
              itemBuilder: (context, item) {
                final categoria = item.insumo.categoria?.trim();
                final tieneCategoria =
                    categoria != null && categoria.isNotEmpty;
                final tieneMinimo = item.insumo.stockMinimo > 0;

                final partesSubtitulo = [
                  if (tieneCategoria) categoria,
                  if (tieneMinimo)
                    'Mínimo: ${item.insumo.unidad.formatear(item.insumo.stockMinimo)}',
                ];
                final subtitulo = partesSubtitulo.join(' • ');

                return ListTile(
                  title: Text(item.insumo.nombre),
                  subtitle: subtitulo.isNotEmpty
                      ? Text(
                          subtitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextoCantidad(
                            item.stock,
                            item.insumo.unidad,
                            estilo: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item.faltante) ...[
                            const SizedBox(height: 4),
                            InsigniaEstado(
                              texto:
                                  'Falta ${item.insumo.unidad.formatear(item.cantidadFaltante)}',
                              color: ColorEstado.peligro,
                            ),
                          ],
                        ],
                      ),
                      if (puedeCargar || puedeEditar)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          tooltip: 'Más opciones',
                          onSelected: (opcion) {
                            if (opcion == 'ajustar') {
                              mostrarDialogoAjusteStock(context, item);
                            } else if (opcion == 'merma') {
                              mostrarDialogoMerma(context, item);
                            } else if (opcion == 'editar') {
                              context.push(Rutas.insumoEditar(item.insumo.id));
                            }
                          },
                          itemBuilder: (context) => [
                            if (puedeCargar) ...[
                              const PopupMenuItem<String>(
                                value: 'ajustar',
                                child: Row(
                                  children: [
                                    Icon(Icons.tune),
                                    SizedBox(width: 8),
                                    Text('Ajustar por conteo'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'merma',
                                child: Row(
                                  children: [
                                    Icon(Icons.remove_circle_outline),
                                    SizedBox(width: 8),
                                    Text('Registrar merma'),
                                  ],
                                ),
                              ),
                            ],
                            if (puedeEditar)
                              const PopupMenuItem<String>(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined),
                                    SizedBox(width: 8),
                                    Text('Editar insumo'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  onTap: () =>
                      context.push(Rutas.stockMovimientos(item.insumo.id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
