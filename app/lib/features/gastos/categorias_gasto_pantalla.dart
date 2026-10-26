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
      cuerpo: ListaAsync<CategoriaGasto>(
        valor: asyncCategorias,
        vacio: const EstadoVacio(
          icono: Icons.category_outlined,
          mensaje: 'No hay categorías',
        ),
        itemBuilder: (context, c) {
          Widget? trailing;
          if (puedeEditar) {
            if (c.archivada) {
              trailing = TextButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Restaurar'),
                onPressed: () => _desarchivar(c),
              );
            } else {
              trailing = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _renombrar(c),
                  ),
                  IconButton(
                    tooltip: 'Archivar',
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () => _archivar(c),
                  ),
                ],
              );
            }
          }

          return ListTile(
            title: Text(c.nombre),
            subtitle: c.archivada ? const Text('Archivada') : null,
            trailing: trailing,
          );
        },
      ),
    );
  }
}
