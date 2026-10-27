import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class RecetasListaPantalla extends ConsumerStatefulWidget {
  const RecetasListaPantalla({super.key});

  @override
  ConsumerState<RecetasListaPantalla> createState() =>
      _RecetasListaPantallaState();
}

class _RecetasListaPantallaState extends ConsumerState<RecetasListaPantalla> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final asyncRecetas = ref.watch(recetasProvider(_busqueda));
    final puedeEditar = ref
        .watch(permisosActualesProvider)
        .puede(Modulo.produccion, NivelPermiso.editar);

    return PantallaBase(
      titulo: 'Recetas',
      botonFlotante: RequierePermiso(
        modulo: Modulo.produccion,
        nivel: NivelPermiso.cargar,
        child: FloatingActionButton.extended(
          onPressed: () => context.push(Rutas.recetaNueva),
          icon: const Icon(Icons.add),
          label: const Text('Nueva receta'),
        ),
      ),
      cuerpo: Column(
        children: [
          CampoBusqueda(
            hint: 'Buscar receta o producto...',
            onChanged: (v) => setState(() => _busqueda = v),
          ),
          Expanded(
            child: ListaAsync<RecetaResumen>(
              valor: asyncRecetas,
              vacio: const EstadoVacio(
                icono: Icons.menu_book_outlined,
                mensaje: 'Todavía no cargaste recetas',
              ),
              itemBuilder: (context, r) {
                final tema = Theme.of(context);
                final cantIngredientes = r.cantidadIngredientes == 1
                    ? '1 ingrediente'
                    : '${r.cantidadIngredientes} ingredientes';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: puedeEditar
                        ? () => context.push(Rutas.recetaEditar(r.receta.id))
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    tema.colorScheme.primaryContainer,
                                foregroundColor:
                                    tema.colorScheme.onPrimaryContainer,
                                child: const Icon(
                                  Icons.menu_book_outlined,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  r.receta.nombre,
                                  style: tema.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InsigniaEstado(
                                texto: r.receta.rindeTexto,
                                color: ColorEstado.info,
                                icono: Icons.pie_chart_outline,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              if (r.productoNombre != null &&
                                  r.productoNombre!.trim().isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.cake_outlined,
                                      size: 14,
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      r.productoNombre!.trim(),
                                      style: tema.textTheme.bodySmall?.copyWith(
                                        color:
                                            tema.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.kitchen_outlined,
                                    size: 14,
                                    color: tema.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    cantIngredientes,
                                    style: tema.textTheme.bodySmall?.copyWith(
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: tema.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Costo de insumos: ',
                                      style: tema.textTheme.bodySmall?.copyWith(
                                        color:
                                            tema.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    TextoDinero(
                                      r.costoTotalEstimado,
                                      estilo: tema.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (r.receta.rindeCantidad > 1) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${r.costoPorUnidadRinde.formatear()}/u)',
                                        style: tema.textTheme.bodySmall
                                            ?.copyWith(
                                              color: tema
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (!r.tieneCostoCompleto)
                                  const InsigniaEstado(
                                    texto: 'Costo parcial',
                                    color: ColorEstado.neutro,
                                  ),
                              ],
                            ),
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
