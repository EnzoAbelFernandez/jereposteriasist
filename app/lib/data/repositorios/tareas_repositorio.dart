import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/formato/fechas.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/tareas_modelos.dart';

abstract class TareasRepositorio {
  Stream<List<TareaResumen>> observarMias({bool incluirTerminadas = false});
  Stream<List<TareaResumen>> observarTodas(FiltroTareas filtro);
  Stream<TareaResumen?> observarPorId(String id);
  Stream<int> observarCantidadPendientesMias();
  Future<String> crear(TareaDatos datos);
  Future<void> actualizar(String id, TareaDatos datos);
  Future<void> cambiarEstado(String id, EstadoTarea estado);
}

class _TareasRepositorioLocal implements TareasRepositorio {
  _TareasRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  TareaResumen _resumen(Tarea t) => TareaResumen(
    tarea: t,
    asignadoNombre: _almacen.nombreDePerfil(t.asignadoA) ?? 'Empleado',
    creadoPorNombre: _almacen.nombreDePerfil(t.creadoPor),
  );

  int _comparar(Tarea a, Tarea b) {
    final h = hoy();
    final va = a.vencida(h);
    final vb = b.vencida(h);
    if (va != vb) return va ? -1 : 1;
    final pa = a.prioridad.index;
    final pb = b.prioridad.index;
    if (pa != pb) return pb.compareTo(pa); // alta primero
    if (a.fechaVencimiento != null && b.fechaVencimiento != null) {
      return a.fechaVencimiento!.compareTo(b.fechaVencimiento!);
    }
    if (a.fechaVencimiento != null) return -1;
    if (b.fechaVencimiento != null) return 1;
    return b.creadoEn.compareTo(a.creadoEn);
  }

  @override
  Stream<List<TareaResumen>> observarMias({bool incluirTerminadas = false}) {
    return _almacen.observar(() {
      final uid = _almacen.usuarioActualId;
      final lista = _almacen.tareas.values.where((t) {
        if (uid != null && t.asignadoA != uid) return false;
        if (!incluirTerminadas && t.estado.esFinal) return false;
        return true;
      }).toList()..sort(_comparar);
      return lista.map(_resumen).toList();
    });
  }

  @override
  Stream<List<TareaResumen>> observarTodas(FiltroTareas filtro) {
    return _almacen.observar(() {
      final lista = _almacen.tareas.values.where((t) {
        if (filtro.asignadoA != null && t.asignadoA != filtro.asignadoA) {
          return false;
        }
        if (!filtro.incluirTerminadas && t.estado.esFinal) return false;
        return true;
      }).toList()..sort(_comparar);
      return lista.map(_resumen).toList();
    });
  }

  @override
  Stream<TareaResumen?> observarPorId(String id) {
    return _almacen.observar(() {
      final t = _almacen.tareas[id];
      return t == null ? null : _resumen(t);
    });
  }

  @override
  Stream<int> observarCantidadPendientesMias() {
    return _almacen.observar(() {
      final uid = _almacen.usuarioActualId;
      return _almacen.tareas.values
          .where((t) => t.asignadoA == uid && !t.estado.esFinal)
          .length;
    });
  }

  @override
  Future<String> crear(TareaDatos datos) async {
    if (datos.titulo.trim().isEmpty) {
      throw const ErrorDeNegocio('El título de la tarea es obligatorio.');
    }
    final uid = _almacen.usuarioActualId;
    final esJefe = uid != null && (_almacen.perfiles[uid]?.esJefe ?? false);
    if (!esJefe && uid != null && datos.asignadoA != uid) {
      throw const ErrorDeNegocio(
        'Solo el jefe puede asignar tareas a otras personas.',
      );
    }
    final id = _almacen.generarId();
    final tarea = Tarea(
      id: id,
      titulo: datos.titulo.trim(),
      descripcion: datos.descripcion?.trim().isEmpty == true
          ? null
          : datos.descripcion?.trim(),
      tipo: datos.tipo,
      prioridad: datos.prioridad,
      asignadoA: datos.asignadoA,
      fechaVencimiento: datos.fechaVencimiento,
      pedidoId: datos.pedidoId,
      creadoPor: uid,
      creadoEn: DateTime.now(),
    );
    await _almacen.persistirTarea(tarea);
    return id;
  }

  @override
  Future<void> actualizar(String id, TareaDatos datos) async {
    if (datos.titulo.trim().isEmpty) {
      throw const ErrorDeNegocio('El título de la tarea es obligatorio.');
    }
    final actual = _almacen.tareas[id];
    if (actual == null) {
      throw const ErrorDeNegocio('La tarea no existe.');
    }
    final uid = _almacen.usuarioActualId;
    final esJefe = uid != null && (_almacen.perfiles[uid]?.esJefe ?? false);
    if (!esJefe && actual.creadoPor != uid) {
      throw const ErrorDeNegocio('Solo podés cambiar el estado de esta tarea.');
    }
    final tarea = Tarea(
      id: id,
      titulo: datos.titulo.trim(),
      descripcion: datos.descripcion?.trim().isEmpty == true
          ? null
          : datos.descripcion?.trim(),
      tipo: datos.tipo,
      prioridad: datos.prioridad,
      estado: actual.estado,
      asignadoA: datos.asignadoA,
      fechaVencimiento: datos.fechaVencimiento,
      pedidoId: datos.pedidoId,
      completadaEn: actual.completadaEn,
      creadoPor: actual.creadoPor,
      creadoEn: actual.creadoEn,
    );
    await _almacen.persistirTarea(tarea);
  }

  @override
  Future<void> cambiarEstado(String id, EstadoTarea estado) async {
    final actual = _almacen.tareas[id];
    if (actual == null) return;
    final tarea = Tarea(
      id: actual.id,
      titulo: actual.titulo,
      descripcion: actual.descripcion,
      tipo: actual.tipo,
      prioridad: actual.prioridad,
      estado: estado,
      asignadoA: actual.asignadoA,
      fechaVencimiento: actual.fechaVencimiento,
      pedidoId: actual.pedidoId,
      completadaEn: estado == EstadoTarea.hecha ? DateTime.now() : null,
      creadoPor: actual.creadoPor,
      creadoEn: actual.creadoEn,
    );
    await _almacen.persistirTarea(tarea);
  }
}

final tareasRepositorioProvider = Provider<TareasRepositorio>((ref) {
  return _TareasRepositorioLocal(ref.watch(almacenLocalProvider));
});

final misTareasProvider = StreamProvider.autoDispose
    .family<List<TareaResumen>, bool>((ref, incluirTerminadas) {
      return ref
          .watch(tareasRepositorioProvider)
          .observarMias(incluirTerminadas: incluirTerminadas);
    });

final tareasProvider = StreamProvider.autoDispose
    .family<List<TareaResumen>, FiltroTareas>((ref, filtro) {
      return ref.watch(tareasRepositorioProvider).observarTodas(filtro);
    });

final tareaProvider = StreamProvider.autoDispose.family<TareaResumen?, String>((
  ref,
  id,
) {
  return ref.watch(tareasRepositorioProvider).observarPorId(id);
});

final cantidadTareasPendientesProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(tareasRepositorioProvider).observarCantidadPendientesMias();
});
