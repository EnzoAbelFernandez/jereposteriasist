import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/alertas_equipo_modelos.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  SupabaseClient? get _supabaseOrNull {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final correo = email.trim();
    if (correo.isEmpty || password.isEmpty) {
      throw const ErrorDeNegocio('Ingresá tu email y contraseña.');
    }
    final client = _supabaseOrNull;
    if (client != null && _almacen.conectadoAInternet) {
      try {
        final res = await client.auth.signInWithPassword(
          email: correo,
          password: password,
        );
        final user = res.user;
        if (user != null) {
          _almacen.perfiles.putIfAbsent(
            user.id,
            () => Perfil(
              id: user.id,
              nombre:
                  (user.userMetadata?['nombre'] as String?)
                          ?.trim()
                          .isNotEmpty ==
                      true
                  ? (user.userMetadata!['nombre'] as String).trim()
                  : correo.split('@').first,
              rol: Rol.jefe,
              activo: true,
            ),
          );
          _almacen.permisos.putIfAbsent(
            user.id,
            () => {for (final m in Modulo.values) m: NivelPermiso.editar},
          );
          _almacen.usuarioActualId = user.id;
          return;
        }
      } on AuthException catch (e) {
        throw ErrorDeNegocio(
          e.message.isNotEmpty
              ? 'No pudimos iniciar sesión: ${e.message}'
              : 'Credenciales inválidas.',
        );
      } catch (_) {
        // Si falla la conexión de red, continúa en el almacén local.
      }
    }
    _almacen.usuarioActualId = AlmacenLocal.idJefeLocal;
  }

  Future<void> cerrarSesion() async {
    final client = _supabaseOrNull;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    _almacen.usuarioActualId = null;
  }
}

final sesionControllerProvider = Provider<SesionController>((ref) {
  return SesionController(ref.watch(almacenLocalProvider));
});
