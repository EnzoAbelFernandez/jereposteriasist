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
                final cantIngredientes = r.cantidadIngredientes == 1
                    ? '1 ingrediente'
                    : '${r.cantidadIngredientes} ingredientes';
                final partes = <String>[
                  if (r.productoNombre != null &&
                      r.productoNombre!.trim().isNotEmpty)
                    r.productoNombre!.trim(),
                  r.receta.rindeTexto,
                  cantIngredientes,
                ];
                final subtitulo = partes.join(' • ');

                Widget? trailing;
                if (r.costoTotalEstimado.esPositivo) {
                  trailing = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextoDinero(r.costoTotalEstimado),
                      if (!r.tieneCostoCompleto)
                        Text(
                          'Costo parcial',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                    ],
                  );
                }

                return ListTile(
                  title: Text(r.receta.nombre),
                  subtitle: Text(
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: trailing,
                  onTap: puedeEditar
                      ? () => context.push(Rutas.recetaEditar(r.receta.id))
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
