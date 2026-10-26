import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/formato/fechas.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';

@immutable
class Tarea {
  const Tarea({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.tipo = TipoTarea.otro,
    this.prioridad = PrioridadTarea.media,
    this.estado = EstadoTarea.pendiente,
    required this.asignadoA,
    this.fechaVencimiento,
    this.pedidoId,
    this.completadaEn,
    this.creadoPor,
    required this.creadoEn,
  });

  final String id;
  final String titulo;
  final String? descripcion;
  final TipoTarea tipo;
  final PrioridadTarea prioridad;
  final EstadoTarea estado;
  final String asignadoA;
  final DateTime? fechaVencimiento;
  final String? pedidoId;
  final DateTime? completadaEn;
  final String? creadoPor;
  final DateTime creadoEn;

  bool vencida(DateTime referencia) {
    if (estado.esFinal || fechaVencimiento == null) return false;
    return soloFecha(fechaVencimiento!).isBefore(soloFecha(referencia));
  }
}

@immutable
class TareaResumen {
  const TareaResumen({
    required this.tarea,
    required this.asignadoNombre,
    this.creadoPorNombre,
  });

  final Tarea tarea;
  final String asignadoNombre;
  final String? creadoPorNombre;
}

class TareaDatos {
  TareaDatos({
    required this.titulo,
    this.descripcion,
    this.tipo = TipoTarea.otro,
    this.prioridad = PrioridadTarea.media,
    required this.asignadoA,
    this.fechaVencimiento,
    this.pedidoId,
  });

  factory TareaDatos.desde(Tarea t) => TareaDatos(
    titulo: t.titulo,
    descripcion: t.descripcion,
    tipo: t.tipo,
    prioridad: t.prioridad,
    asignadoA: t.asignadoA,
    fechaVencimiento: t.fechaVencimiento,
    pedidoId: t.pedidoId,
  );

  final String titulo;
  final String? descripcion;
  final TipoTarea tipo;
  final PrioridadTarea prioridad;
  final String asignadoA;
  final DateTime? fechaVencimiento;
  final String? pedidoId;
}

@immutable
class FiltroTareas {
  const FiltroTareas({this.asignadoA, this.incluirTerminadas = false});

  final String? asignadoA;
  final bool incluirTerminadas;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiltroTareas &&
          other.asignadoA == asignadoA &&
          other.incluirTerminadas == incluirTerminadas);

  @override
  int get hashCode => Object.hash(asignadoA, incluirTerminadas);
}
