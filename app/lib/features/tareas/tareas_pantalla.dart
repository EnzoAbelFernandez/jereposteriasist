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

  ColorEstado _colorEstadoTarea(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.hecha:
        return ColorEstado.exito;
      case EstadoTarea.enProgreso:
        return ColorEstado.info;
      case EstadoTarea.cancelada:
        return ColorEstado.peligro;
      case EstadoTarea.pendiente:
        return ColorEstado.neutro;
    }
  }

  IconData _iconoEstadoTarea(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.hecha:
        return Icons.check_circle_outline;
      case EstadoTarea.enProgreso:
        return Icons.timelapse;
      case EstadoTarea.cancelada:
        return Icons.cancel_outlined;
      case EstadoTarea.pendiente:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilterChip(
                      label: const Text('Ver terminadas'),
                      selected: _incluirTerminadas,
                      tooltip: 'Mostrar u ocultar tareas finalizadas',
                      onSelected: (v) => setState(() => _incluirTerminadas = v),
                    ),
                    Text(
                      esTodoElEquipo ? 'Vista equipo' : 'Tus pendientes',
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListaAsync<TareaResumen>(
              valor: asyncTareas,
              separadores: false,
              vacio: EstadoVacio(
                icono: Icons.task_alt_outlined,
                mensaje: 'No tenés tareas pendientes',
                textoAccion: 'Nueva tarea',
                onAccion: () => context.push(Rutas.tareaNueva),
              ),
              itemBuilder: (context, r) {
                final esVencida = r.tarea.vencida(hoy());
                final desc = r.tarea.descripcion?.trim();
                final puedeEditar =
                    esJefe ||
                    (perfilActual != null &&
                        r.tarea.creadoPor == perfilActual.id);
                final estaHecha = r.tarea.estado == EstadoTarea.hecha;
                final paletaPrioridad = resolverColorEstado(
                  context,
                  r.tarea.prioridad.color,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: estaHecha
                          ? tema.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            )
                          : (r.tarea.prioridad == PrioridadTarea.alta
                                ? paletaPrioridad.frente.withValues(alpha: 0.6)
                                : tema.colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  )),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: puedeEditar
                        ? () => context.push(Rutas.tareaEditar(r.tarea.id))
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: Icon(
                              estaHecha
                                  ? Icons.check_circle
                                  : (r.tarea.estado == EstadoTarea.enProgreso
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked),
                              size: 24,
                              color: estaHecha
                                  ? tema.colorScheme.primary
                                  : (r.tarea.estado == EstadoTarea.enProgreso
                                        ? tema.colorScheme.secondary
                                        : tema.colorScheme.outline),
                            ),
                            tooltip: estaHecha
                                ? 'Marcar como pendiente'
                                : 'Marcar como hecha',
                            onPressed: () async {
                              final nuevoEstado = estaHecha
                                  ? EstadoTarea.pendiente
                                  : EstadoTarea.hecha;
                              await ejecutarConManejo(
                                context,
                                () => ref
                                    .read(tareasRepositorioProvider)
                                    .cambiarEstado(r.tarea.id, nuevoEstado),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tema
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            r.tarea.tipo.icono,
                                            size: 13,
                                            color: tema
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            r.tarea.tipo.etiqueta,
                                            style: tema.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: tema
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InsigniaEstado(
                                      texto: r.tarea.prioridad.etiqueta,
                                      color: r.tarea.prioridad.color,
                                    ),
                                    InsigniaEstado(
                                      texto: r.tarea.estado.etiqueta,
                                      color: _colorEstadoTarea(r.tarea.estado),
                                      icono: _iconoEstadoTarea(r.tarea.estado),
                                    ),
                                    if (esVencida && !estaHecha)
                                      const InsigniaEstado(
                                        texto: 'Vencida',
                                        color: ColorEstado.peligro,
                                        icono: Icons.warning_amber_rounded,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  r.tarea.titulo,
                                  style: tema.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: estaHecha
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: estaHecha
                                        ? tema.colorScheme.outline
                                        : null,
                                  ),
                                ),
                                if (desc != null && desc.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: tema.textTheme.bodySmall?.copyWith(
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (r.tarea.fechaVencimiento != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 13,
                                            color: esVencida && !estaHecha
                                                ? tema.colorScheme.error
                                                : tema
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Vence: ${formatearFecha(r.tarea.fechaVencimiento!)}',
                                            style: tema.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: esVencida && !estaHecha
                                                      ? tema.colorScheme.error
                                                      : tema
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  fontWeight:
                                                      esVencida && !estaHecha
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                          ),
                                        ],
                                      ),
                                    if (esTodoElEquipo)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 14,
                                            color: tema
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            r.asignadoNombre,
                                            style: tema.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: tema
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            tooltip: 'Cambiar estado u opciones',
                            onSelected: (opcion) async {
                              if (opcion == 'editar') {
                                context.push(Rutas.tareaEditar(r.tarea.id));
                                return;
                              }
                              final nuevoEstado = EstadoTarea.desdeValor(
                                opcion,
                              );
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
