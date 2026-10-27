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
            child: Row(
              children: [
                FilterChip(
                  label: Text(etiquetaFiltro),
                  selected: _soloFaltantes,
                  avatar: _soloFaltantes
                      ? const Icon(Icons.check, size: 16)
                      : (cantidadFaltantes > 0
                            ? const Icon(Icons.warning_amber_rounded, size: 16)
                            : null),
                  onSelected: (seleccionado) {
                    setState(() => _soloFaltantes = seleccionado);
                  },
                ),
              ],
            ),
          ),
          if (cantidadFaltantes > 0 && !_soloFaltantes)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Material(
                color: resolverColorEstado(context, ColorEstado.peligro).fondo,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _soloFaltantes = true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: resolverColorEstado(
                            context,
                            ColorEstado.peligro,
                          ).frente,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cantidadFaltantes == 1
                                ? 'Hay 1 insumo bajo el stock mínimo'
                                : 'Hay $cantidadFaltantes insumos bajo el stock mínimo',
                            style: tema.textTheme.bodyMedium?.copyWith(
                              color: resolverColorEstado(
                                context,
                                ColorEstado.peligro,
                              ).frente,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          'Ver faltantes',
                          style: tema.textTheme.labelMedium?.copyWith(
                            color: resolverColorEstado(
                              context,
                              ColorEstado.peligro,
                            ).frente,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                final paletaPeligro = resolverColorEstado(
                  context,
                  ColorEstado.peligro,
                );

                final stockMinTexto = tieneMinimo
                    ? 'Mínimo: ${item.insumo.unidad.formatear(item.insumo.stockMinimo)}'
                    : 'Sin stock mínimo';
                final partesSubtitulo = [
                  if (tieneCategoria) categoria,
                  stockMinTexto,
                ];
                final subtitulo = partesSubtitulo.join(' • ');

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: item.faltante
                        ? paletaPeligro.fondo.withValues(alpha: 0.35)
                        : tema.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.faltante
                          ? paletaPeligro.fondo
                          : tema.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: item.faltante
                          ? paletaPeligro.fondo
                          : tema.colorScheme.surfaceContainerHighest,
                      foregroundColor: item.faltante
                          ? paletaPeligro.frente
                          : tema.colorScheme.onSurfaceVariant,
                      child: Icon(
                        item.faltante
                            ? Icons.warning_amber_rounded
                            : Icons.inventory_2_outlined,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.insumo.nombre,
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.faltante) ...[
                          const SizedBox(width: 8),
                          const InsigniaEstado(
                            texto: 'Bajo mínimo',
                            color: ColorEstado.peligro,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: item.faltante
                            ? paletaPeligro.frente
                            : tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
                                color: item.faltante
                                    ? paletaPeligro.frente
                                    : null,
                              ),
                            ),
                            if (item.faltante) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Falta ${item.insumo.unidad.formatear(item.cantidadFaltante)}',
                                style: tema.textTheme.labelSmall?.copyWith(
                                  color: paletaPeligro.frente,
                                  fontWeight: FontWeight.w600,
                                ),
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
                                context.push(
                                  Rutas.insumoEditar(item.insumo.id),
                                );
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
