import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class TareaFormularioPantalla extends ConsumerStatefulWidget {
  const TareaFormularioPantalla({super.key, this.id});
  final String? id;

  bool get esEdicion => id != null;

  @override
  ConsumerState<TareaFormularioPantalla> createState() =>
      _TareaFormularioPantallaState();
}

class _TareaFormularioPantallaState
    extends ConsumerState<TareaFormularioPantalla> {
  final _formKey = GlobalKey<FormState>();
  bool _inicializado = false;

  String _titulo = '';
  TipoTarea _tipo = TipoTarea.otro;
  PrioridadTarea _prioridad = PrioridadTarea.media;
  String? _asignadoA;
  DateTime? _fechaVencimiento;
  String? _pedidoId;
  String _descripcion = '';

  void _precargar(Tarea t) {
    if (_inicializado) return;
    _inicializado = true;
    _titulo = t.titulo;
    _tipo = t.tipo;
    _prioridad = t.prioridad;
    _asignadoA = t.asignadoA;
    _fechaVencimiento = t.fechaVencimiento;
    _pedidoId = t.pedidoId;
    _descripcion = t.descripcion ?? '';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final permisos = ref.read(permisosActualesProvider);
    final perfil = ref.read(perfilActualProvider).value;
    final asignadoA = permisos.esJefe ? _asignadoA : (perfil?.id ?? _asignadoA);

    if (asignadoA == null || asignadoA.trim().isEmpty) {
      mostrarError(
        context,
        const ErrorDeNegocio('Tenés que asignar la tarea a una persona.'),
      );
      return;
    }

    final datos = TareaDatos(
      titulo: _titulo.trim(),
      descripcion: _descripcion.trim().isEmpty ? null : _descripcion.trim(),
      tipo: _tipo,
      prioridad: _prioridad,
      asignadoA: asignadoA,
      fechaVencimiento: _fechaVencimiento,
      pedidoId: _pedidoId,
    );

    final repo = ref.read(tareasRepositorioProvider);
    if (widget.esEdicion) {
      await repo.actualizar(widget.id!, datos);
    } else {
      await repo.crear(datos);
    }

    if (mounted) {
      mostrarExito(context, 'Tarea guardada');
      context.pop();
    }
  }

  Widget _construirFormulario() {
    final tema = Theme.of(context);

    return FormularioResponsivo(
      formKey: _formKey,
      campos: [
        Container(
          padding: const EdgeInsets.all(12),
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
              Icon(Icons.task_alt_outlined, color: tema.colorScheme.primary),
              Separacion.media,
              Expanded(
                child: Text(
                  widget.esEdicion
                      ? 'Editá los detalles, responsable o fecha límite de la tarea.'
                      : 'Asigná tareas al equipo para coordinar producción, pedidos o compras.',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        CampoTexto(
          etiqueta: 'Título',
          valorInicial: _titulo,
          obligatorio: true,
          icono: Icons.edit_note_outlined,
          onChanged: (v) => _titulo = v,
        ),
        SelectorOpcion<TipoTarea>(
          etiqueta: 'Tipo de tarea',
          opciones: TipoTarea.values,
          valor: _tipo,
          etiquetaDe: (t) => t.etiqueta,
          onChanged: (v) {
            if (v != null) setState(() => _tipo = v);
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Prioridad',
                style: tema.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<PrioridadTarea>(
                segments: [
                  for (final p in PrioridadTarea.values)
                    ButtonSegment(
                      value: p,
                      label: Text(p.etiqueta),
                      icon: Icon(
                        p == PrioridadTarea.alta
                            ? Icons.priority_high
                            : (p == PrioridadTarea.media
                                  ? Icons.remove
                                  : Icons.arrow_downward),
                        size: 16,
                      ),
                    ),
                ],
                selected: {_prioridad},
                onSelectionChanged: (seleccion) {
                  setState(() => _prioridad = seleccion.first);
                },
              ),
            ),
          ],
        ),
        SoloJefe(
          child: SelectorPerfil(
            perfilId: _asignadoA,
            obligatorio: true,
            onChanged: (p) => setState(() => _asignadoA = p?.id),
          ),
        ),
        CampoFecha(
          etiqueta: 'Fecha de vencimiento (opcional)',
          valor: _fechaVencimiento,
          onChanged: (d) => setState(() => _fechaVencimiento = d),
        ),
        SelectorPedido(
          pedidoId: _pedidoId,
          onChanged: (p) => setState(() => _pedidoId = p?.pedido.id),
        ),
        CampoTexto(
          etiqueta: 'Descripción / notas (opcional)',
          valorInicial: _descripcion,
          maxLineas: 3,
          icono: Icons.notes_outlined,
          onChanged: (v) => _descripcion = v,
        ),
      ],
      botonGuardar: BotonGuardar(
        texto: widget.esEdicion ? 'Guardar cambios' : 'Crear tarea',
        onGuardar: _guardar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esJefe = ref.watch(permisosActualesProvider).esJefe;
    final perfil = ref.watch(perfilActualProvider).value;

    if (!esJefe && !widget.esEdicion && perfil != null && _asignadoA == null) {
      _asignadoA = perfil.id;
    }

    if (!widget.esEdicion) {
      return PantallaBase(
        titulo: 'Nueva tarea',
        cuerpo: _construirFormulario(),
      );
    }

    final asyncTarea = ref.watch(tareaProvider(widget.id!));
    return PantallaBase(
      titulo: 'Editar tarea',
      cuerpo: VistaAsync<TareaResumen?>(
        valor: asyncTarea,
        builder: (context, resumen) {
          _precargar(resumen!.tarea);
          return _construirFormulario();
        },
      ),
    );
  }
}
