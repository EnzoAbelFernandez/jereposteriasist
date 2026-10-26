import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

enum _VistaTareas { misTareas, todoElEquipo }

class TareasPantalla extends ConsumerStatefulWidget {
  const TareasPantalla({super.key});

  @override
  ConsumerState<TareasPantalla> createState() => _TareasPantallaState();
}

class _TareasPantallaState extends ConsumerState<TareasPantalla> {
  _VistaTareas _vista = _VistaTareas.misTareas;
  bool _incluirTerminadas = false;
  String? _empleadoFiltroId;

  @override
  Widget build(BuildContext context) {
    final esJefe = ref.watch(permisosActualesProvider).esJefe;
    final perfilActual = ref.watch(perfilActualProvider).value;
    final esTodoElEquipo = esJefe && _vista == _VistaTareas.todoElEquipo;

    final asyncTareas = esTodoElEquipo
        ? ref.watch(
            tareasProvider(
              FiltroTareas(
                asignadoA: _empleadoFiltroId,
                incluirTerminadas: _incluirTerminadas,
              ),
            ),
          )
        : ref.watch(misTareasProvider(_incluirTerminadas));

    return PantallaBase(
      titulo: 'Tareas',
      botonFlotante: FloatingActionButton.extended(
        onPressed: () => context.push(Rutas.tareaNueva),
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
      cuerpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SoloJefe(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<_VistaTareas>(
                        segments: const [
                          ButtonSegment(
                            value: _VistaTareas.misTareas,
                            label: Text('Mis tareas'),
                            icon: Icon(Icons.person_outline),
                          ),
                          ButtonSegment(
                            value: _VistaTareas.todoElEquipo,
                            label: Text('Todo el equipo'),
                            icon: Icon(Icons.groups_outlined),
                          ),
                        ],
                        selected: {_vista},
                        onSelectionChanged: (seleccion) {
                          setState(() {
                            _vista = seleccion.first;
                            if (_vista == _VistaTareas.misTareas) {
                              _empleadoFiltroId = null;
                            }
                          });
                        },
                      ),
                      if (_vista == _VistaTareas.todoElEquipo) ...[
                        Separacion.chica,
                        SelectorPerfil(
                          perfilId: _empleadoFiltroId,
                          onChanged: (perfil) {
                            setState(() {
                              _empleadoFiltroId = perfil?.id;
                            });
                          },
                        ),
                      ],
                      Separacion.chica,
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('Ver terminadas'),
                    selected: _incluirTerminadas,
                    onSelected: (v) => setState(() => _incluirTerminadas = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListaAsync<TareaResumen>(
              valor: asyncTareas,
              vacio: EstadoVacio(
                icono: Icons.task_alt_outlined,
                mensaje: 'No tenés tareas pendientes',
                textoAccion: 'Nueva tarea',
                onAccion: () => context.push(Rutas.tareaNueva),
              ),
              itemBuilder: (context, r) {
                final esVencida = r.tarea.vencida(hoy());
                final detalles = <String>[
                  r.tarea.tipo.etiqueta,
                  if (r.tarea.fechaVencimiento != null)
                    'Vence: ${formatearFecha(r.tarea.fechaVencimiento!)}',
                  if (esTodoElEquipo) 'Asignada a: ${r.asignadoNombre}',
                ];
                final desc = r.tarea.descripcion?.trim();
                final puedeEditar =
                    esJefe ||
                    (perfilActual != null &&
                        r.tarea.creadoPor == perfilActual.id);

                return ListTile(
                  leading: Checkbox(
                    value: r.tarea.estado == EstadoTarea.hecha,
                    onChanged: (bool? valor) async {
                      final nuevoEstado = (valor == true)
                          ? EstadoTarea.hecha
                          : EstadoTarea.pendiente;
                      await ejecutarConManejo(
                        context,
                        () => ref
                            .read(tareasRepositorioProvider)
                            .cambiarEstado(r.tarea.id, nuevoEstado),
                      );
                    },
                  ),
                  title: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        r.tarea.titulo,
                        style: r.tarea.estado == EstadoTarea.hecha
                            ? TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Theme.of(context).colorScheme.outline,
                              )
                            : null,
                      ),
                      if (r.tarea.prioridad == PrioridadTarea.alta)
                        InsigniaEstado(
                          texto: r.tarea.prioridad.etiqueta,
                          color: r.tarea.prioridad.color,
                        ),
                      if (esVencida)
                        const InsigniaEstado(
                          texto: 'Vencida',
                          color: ColorEstado.peligro,
                          icono: Icons.warning_amber_rounded,
                        ),
                    ],
                  ),
                  subtitle: (desc != null && desc.isNotEmpty)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(detalles.join(' • ')),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : Text(detalles.join(' • ')),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Opciones de tarea',
                    onSelected: (opcion) async {
                      if (opcion == 'editar') {
                        context.push(Rutas.tareaEditar(r.tarea.id));
                        return;
                      }
                      final nuevoEstado = EstadoTarea.desdeValor(opcion);
                      if (nuevoEstado == r.tarea.estado) return;
                      await ejecutarConManejo(
                        context,
                        () => ref
                            .read(tareasRepositorioProvider)
                            .cambiarEstado(r.tarea.id, nuevoEstado),
                      );
                    },
                    itemBuilder: (context) => [
                      if (puedeEditar) ...[
                        const PopupMenuItem<String>(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              Separacion.chica,
                              Text('Editar tarea'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                      ],
                      for (final estado in EstadoTarea.values)
                        PopupMenuItem<String>(
                          value: estado.valor,
                          child: Row(
                            children: [
                              if (estado == r.tarea.estado)
                                const Icon(Icons.check, size: 18)
                              else
                                const SizedBox(width: 18),
                              Separacion.chica,
                              Text(estado.etiqueta),
                            ],
                          ),
                        ),
                    ],
                  ),
                  onTap: puedeEditar
                      ? () => context.push(Rutas.tareaEditar(r.tarea.id))
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
