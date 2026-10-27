import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class CategoriasGastoPantalla extends ConsumerStatefulWidget {
  const CategoriasGastoPantalla({super.key});

  @override
  ConsumerState<CategoriasGastoPantalla> createState() =>
      _CategoriasGastoPantallaState();
}

class _CategoriasGastoPantallaState
    extends ConsumerState<CategoriasGastoPantalla> {
  bool _incluirArchivadas = false;

  Future<void> _crearCategoria() async {
    final nombre = await pedirTexto(
      context,
      titulo: 'Nueva categoría',
      etiqueta: 'Nombre',
      textoConfirmar: 'Crear',
    );
    if (nombre == null || nombre.isEmpty || !mounted) return;
    await ejecutarConManejo(
      context,
      () => ref.read(gastosRepositorioProvider).crearCategoria(nombre),
      mensajeExito: 'Categoría creada',
    );
  }

  Future<void> _renombrar(CategoriaGasto c) async {
    final nuevoNombre = await pedirTexto(
      context,
      titulo: 'Renombrar categoría',
      etiqueta: 'Nombre',
      textoConfirmar: 'Guardar',
    );
    if (nuevoNombre == null || nuevoNombre.isEmpty || !mounted) return;
    await ejecutarConManejo(
      context,
      () => ref
          .read(gastosRepositorioProvider)
          .renombrarCategoria(c.id, nuevoNombre),
      mensajeExito: 'Categoría renombrada',
    );
  }

  Future<void> _archivar(CategoriaGasto c) async {
    final ok = await confirmar(
      context,
      titulo: 'Archivar categoría',
      mensaje: '¿Querés archivar la categoría "${c.nombre}"?',
      textoConfirmar: 'Archivar',
      peligroso: true,
    );
    if (!ok || !mounted) return;
    await ejecutarConManejo(
      context,
      () => ref.read(gastosRepositorioProvider).archivarCategoria(c.id),
      mensajeExito: 'Categoría archivada',
    );
  }

  Future<void> _desarchivar(CategoriaGasto c) async {
    await ejecutarConManejo(
      context,
      () => ref.read(gastosRepositorioProvider).desarchivarCategoria(c.id),
      mensajeExito: 'Categoría restaurada',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final asyncCategorias = ref.watch(
      categoriasGastoProvider(_incluirArchivadas),
    );
    final puedeEditar = ref
        .watch(permisosActualesProvider)
        .puede(Modulo.gastos, NivelPermiso.editar);

    return PantallaBase(
      titulo: 'Categorías de gasto',
      acciones: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FilterChip(
            label: const Text('Ver archivadas'),
            selected: _incluirArchivadas,
            tooltip: 'Ver archivadas',
            onSelected: (v) => setState(() => _incluirArchivadas = v),
          ),
        ),
      ],
      botonFlotante: RequierePermiso(
        modulo: Modulo.gastos,
        nivel: NivelPermiso.editar,
        child: FloatingActionButton.extended(
          onPressed: _crearCategoria,
          icon: const Icon(Icons.add),
          label: const Text('Nueva categoría'),
        ),
      ),
      cuerpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tema.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tema.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 20,
                    color: tema.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Las categorías organizan tus egresos para los reportes mensuales de distribución de costos.',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Separacion.chica,
          Expanded(
            child: ListaAsync<CategoriaGasto>(
              valor: asyncCategorias,
              separadores: false,
              vacio: const EstadoVacio(
                icono: Icons.category_outlined,
                mensaje: 'No hay categorías registradas',
              ),
              itemBuilder: (context, c) {
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: c.archivada
                                ? tema.colorScheme.surfaceContainerHighest
                                : tema.colorScheme.primaryContainer.withValues(
                                    alpha: 0.5,
                                  ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            c.archivada
                                ? Icons.archive_outlined
                                : Icons.category_outlined,
                            size: 18,
                            color: c.archivada
                                ? tema.colorScheme.onSurfaceVariant
                                : tema.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.nombre,
                                style: tema.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: c.archivada
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: c.archivada
                                      ? tema.colorScheme.outline
                                      : null,
                                ),
                              ),
                              if (c.archivada) ...[
                                const SizedBox(height: 2),
                                const InsigniaEstado(
                                  texto: 'Archivada',
                                  color: ColorEstado.neutro,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (puedeEditar)
                          if (c.archivada)
                            TextButton.icon(
                              icon: const Icon(Icons.restore, size: 18),
                              label: const Text('Restaurar'),
                              onPressed: () => _desarchivar(c),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Renombrar categoría',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _renombrar(c),
                                ),
                                IconButton(
                                  tooltip: 'Archivar categoría',
                                  icon: const Icon(Icons.archive_outlined),
                                  onPressed: () => _archivar(c),
                                ),
                              ],
                            ),
                      ],
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
