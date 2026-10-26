import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/alertas_equipo_modelos.dart';

@immutable
class PermisosUsuario {
  PermisosUsuario({
    required this.esJefe,
    required Map<Modulo, NivelPermiso> niveles,
  }) : _niveles = Map<Modulo, NivelPermiso>.unmodifiable(niveles);

  static final PermisosUsuario vacio = PermisosUsuario(
    esJefe: false,
    niveles: const {},
  );

  final bool esJefe;
  final Map<Modulo, NivelPermiso> _niveles;

  NivelPermiso nivel(Modulo m) {
    if (esJefe) return NivelPermiso.editar;
    return _niveles[m] ?? NivelPermiso.ninguno;
  }

  bool puede(Modulo m, NivelPermiso minimo) => nivel(m).alcanza(minimo);
}

final perfilActualProvider = StreamProvider<Perfil?>((ref) {
  final almacen = ref.watch(almacenLocalProvider);
  return almacen.observar(() {
    final uid = almacen.usuarioActualId;
    if (uid == null) return null;
    final p = almacen.perfiles[uid];
    if (p == null || !p.activo) return null;
    return p;
  });
});

final _permisosStreamProvider = StreamProvider<PermisosUsuario>((ref) {
  final almacen = ref.watch(almacenLocalProvider);
  return almacen.observar(() {
    final uid = almacen.usuarioActualId;
    if (uid == null) return PermisosUsuario.vacio;
    final perfil = almacen.perfiles[uid];
    if (perfil == null || !perfil.activo) return PermisosUsuario.vacio;
    final mapa = Map<Modulo, NivelPermiso>.of(almacen.permisos[uid] ?? {});
    return PermisosUsuario(esJefe: perfil.esJefe, niveles: mapa);
  });
});

final permisosActualesProvider = Provider<PermisosUsuario>((ref) {
  return ref.watch(_permisosStreamProvider).value ??
      PermisosUsuario(esJefe: true, niveles: const {});
});

class SesionController {
  SesionController(this._almacen);
  final AlmacenLocal _almacen;

  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final correo = email.trim();
    if (correo.isEmpty || password.isEmpty) {
      throw const ErrorDeNegocio('Ingresá tu email y contraseña.');
    }
    _almacen.usuarioActualId = AlmacenLocal.idJefeLocal;
  }

  Future<void> cerrarSesion() async {
    _almacen.usuarioActualId = null;
  }
}

final sesionControllerProvider = Provider<SesionController>((ref) {
  return SesionController(ref.watch(almacenLocalProvider));
});
