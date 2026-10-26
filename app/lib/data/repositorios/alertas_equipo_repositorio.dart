import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/alertas_equipo_modelos.dart';

abstract class AlertasRepositorio {
  Stream<List<Alerta>> observarTodas();
  Stream<int> observarCantidadNoLeidas();
  Future<void> marcarLeida(String id);
  Future<void> marcarTodasLeidas();
}

abstract class EquipoRepositorio {
  Stream<List<Perfil>> observarPerfiles({bool incluirInactivos = false});
  Stream<Perfil?> observarPerfil(String id);
  Stream<Map<Modulo, NivelPermiso>> observarPermisos(String perfilId);
  Future<void> cambiarPermiso(
    String perfilId,
    Modulo modulo,
    NivelPermiso nivel,
  );
  Future<void> actualizarMiPerfil({required String nombre, String? telefono});
  Future<void> invitarEmpleado({
    required String nombre,
    required String email,
    String? telefono,
  });
  Future<void> desactivar(String perfilId);
  Future<void> reactivar(String perfilId);
}

abstract class ConfiguracionRepositorio {
  Stream<Configuracion> observar();
  Future<void> actualizar(Configuracion c);
}

class _AlertasRepositorioLocal implements AlertasRepositorio {
  _AlertasRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  @override
  Stream<List<Alerta>> observarTodas() {
    return _almacen.observar(() {
      final lista = _almacen.alertas.values.toList()
        ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return lista;
    });
  }

  @override
  Stream<int> observarCantidadNoLeidas() {
    return _almacen.observar(
      () => _almacen.alertas.values.where((a) => !a.leida).length,
    );
  }

  @override
  Future<void> marcarLeida(String id) async {
    final a = _almacen.alertas[id];
    if (a == null || a.leida) return;
    _almacen.alertas[id] = Alerta(
      id: a.id,
      tipo: a.tipo,
      titulo: a.titulo,
      mensaje: a.mensaje,
      entidadTipo: a.entidadTipo,
      entidadId: a.entidadId,
      leidaEn: DateTime.now(),
      creadoEn: a.creadoEn,
    );
    _almacen.notificar();
  }

  @override
  Future<void> marcarTodasLeidas() async {
    final ahora = DateTime.now();
    for (final e in _almacen.alertas.entries.toList()) {
      final a = e.value;
      if (!a.leida) {
        _almacen.alertas[e.key] = Alerta(
          id: a.id,
          tipo: a.tipo,
          titulo: a.titulo,
          mensaje: a.mensaje,
          entidadTipo: a.entidadTipo,
          entidadId: a.entidadId,
          leidaEn: ahora,
          creadoEn: a.creadoEn,
        );
      }
    }
    _almacen.notificar();
  }
}

class _EquipoRepositorioLocal implements EquipoRepositorio {
  _EquipoRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  @override
  Stream<List<Perfil>> observarPerfiles({bool incluirInactivos = false}) {
    return _almacen.observar(() {
      final lista =
          _almacen.perfiles.values
              .where((p) => incluirInactivos || p.activo)
              .toList()
            ..sort((a, b) {
              if (a.esJefe != b.esJefe) return a.esJefe ? -1 : 1;
              return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
            });
      return lista;
    });
  }

  @override
  Stream<Perfil?> observarPerfil(String id) =>
      _almacen.observar(() => _almacen.perfiles[id]);

  @override
  Stream<Map<Modulo, NivelPermiso>> observarPermisos(String perfilId) {
    return _almacen.observar(() {
      final actual = _almacen.permisos[perfilId] ?? const {};
      return {
        for (final m in Modulo.values) m: actual[m] ?? NivelPermiso.ninguno,
      };
    });
  }

  @override
  Future<void> cambiarPermiso(
    String perfilId,
    Modulo modulo,
    NivelPermiso nivel,
  ) async {
    final perfil = _almacen.perfiles[perfilId];
    if (perfil == null) {
      throw const ErrorDeNegocio('El usuario no existe.');
    }
    if (perfil.esJefe) {
      throw const ErrorDeNegocio(
        'El jefe siempre tiene acceso total a todos los módulos.',
      );
    }
    final mapa = Map<Modulo, NivelPermiso>.of(
      _almacen.permisos[perfilId] ?? {},
    );
    mapa[modulo] = nivel;
    _almacen.permisos[perfilId] = mapa;
    _almacen.notificar();
  }

  @override
  Future<void> actualizarMiPerfil({
    required String nombre,
    String? telefono,
  }) async {
    if (nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre es obligatorio.');
    }
    final uid = _almacen.usuarioActualId;
    if (uid == null || !_almacen.perfiles.containsKey(uid)) return;
    final actual = _almacen.perfiles[uid]!;
    _almacen.perfiles[uid] = Perfil(
      id: actual.id,
      nombre: nombre.trim(),
      rol: actual.rol,
      telefono: telefono?.trim().isEmpty == true ? null : telefono?.trim(),
      activo: actual.activo,
    );
    _almacen.notificar();
  }

  @override
  Future<void> invitarEmpleado({
    required String nombre,
    required String email,
    String? telefono,
  }) async {
    if (!_almacen.conectadoAInternet) {
      throw const SinConexion();
    }
    if (nombre.trim().isEmpty || email.trim().isEmpty) {
      throw const ErrorDeNegocio('Completá el nombre y el email.');
    }
    final id = _almacen.generarId();
    _almacen.perfiles[id] = Perfil(
      id: id,
      nombre: nombre.trim(),
      rol: Rol.empleado,
      telefono: telefono?.trim().isEmpty == true ? null : telefono?.trim(),
      activo: true,
    );
    _almacen.permisos[id] = {
      for (final m in Modulo.values) m: NivelPermiso.ninguno,
    };
    _almacen.notificar();
  }

  @override
  Future<void> desactivar(String perfilId) async {
    if (!_almacen.conectadoAInternet) {
      throw const SinConexion();
    }
    final p = _almacen.perfiles[perfilId];
    if (p == null) return;
    if (p.esJefe) {
      throw const ErrorDeNegocio('No se puede desactivar al jefe.');
    }
    _almacen.perfiles[perfilId] = Perfil(
      id: p.id,
      nombre: p.nombre,
      rol: p.rol,
      telefono: p.telefono,
      activo: false,
    );
    _almacen.permisos[perfilId] = {
      for (final m in Modulo.values) m: NivelPermiso.ninguno,
    };
    _almacen.notificar();
  }

  @override
  Future<void> reactivar(String perfilId) async {
    if (!_almacen.conectadoAInternet) {
      throw const SinConexion();
    }
    final p = _almacen.perfiles[perfilId];
    if (p == null) return;
    _almacen.perfiles[perfilId] = Perfil(
      id: p.id,
      nombre: p.nombre,
      rol: p.rol,
      telefono: p.telefono,
      activo: true,
    );
    _almacen.notificar();
  }
}

class _ConfiguracionRepositorioLocal implements ConfiguracionRepositorio {
  _ConfiguracionRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  @override
  Stream<Configuracion> observar() =>
      _almacen.observar(() => _almacen.configuracion);

  @override
  Future<void> actualizar(Configuracion c) async {
    if (c.nombreNegocio.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre del negocio es obligatorio.');
    }
    if (c.diasAvisoCumple < 1 || c.diasAvisoCumple > 60) {
      throw const ErrorDeNegocio(
        'Los días de anticipación deben estar entre 1 y 60.',
      );
    }
    if (c.habitualMinPedidos < 1 || c.habitualMeses < 1) {
      throw const ErrorDeNegocio('Los valores deben ser mayores a cero.');
    }
    _almacen.configuracion = c.copyWith(nombreNegocio: c.nombreNegocio.trim());
    _almacen.recalcularTodosLosHabituales();
    _almacen.notificar();
  }
}

final alertasRepositorioProvider = Provider<AlertasRepositorio>((ref) {
  return _AlertasRepositorioLocal(ref.watch(almacenLocalProvider));
});

final alertasProvider = StreamProvider.autoDispose<List<Alerta>>((ref) {
  return ref.watch(alertasRepositorioProvider).observarTodas();
});

final cantidadAlertasNoLeidasProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(alertasRepositorioProvider).observarCantidadNoLeidas();
});

final equipoRepositorioProvider = Provider<EquipoRepositorio>((ref) {
  return _EquipoRepositorioLocal(ref.watch(almacenLocalProvider));
});

final perfilesProvider = StreamProvider.autoDispose.family<List<Perfil>, bool>((
  ref,
  incluirInactivos,
) {
  return ref
      .watch(equipoRepositorioProvider)
      .observarPerfiles(incluirInactivos: incluirInactivos);
});

final perfilProvider = StreamProvider.autoDispose.family<Perfil?, String>((
  ref,
  id,
) {
  return ref.watch(equipoRepositorioProvider).observarPerfil(id);
});

final permisosDePerfilProvider = StreamProvider.autoDispose
    .family<Map<Modulo, NivelPermiso>, String>((ref, perfilId) {
      return ref.watch(equipoRepositorioProvider).observarPermisos(perfilId);
    });

final configuracionRepositorioProvider = Provider<ConfiguracionRepositorio>((
  ref,
) {
  return _ConfiguracionRepositorioLocal(ref.watch(almacenLocalProvider));
});

final configuracionProvider = StreamProvider.autoDispose<Configuracion>((ref) {
  return ref.watch(configuracionRepositorioProvider).observar();
});
