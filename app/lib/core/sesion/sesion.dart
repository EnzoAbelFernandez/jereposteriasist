import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/core/notificaciones/notificaciones_push.dart';
import 'package:jereposteria/core/sync/sincronizacion_directa.dart';
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
  return ref.watch(_permisosStreamProvider).value ?? PermisosUsuario.vacio;
});

class SesionController {
  SesionController(this._almacen, {this.supabase});
  final AlmacenLocal _almacen;
  final SupabaseClient? supabase;

  SupabaseClient? get _supabaseOrNull {
    if (supabase != null) return supabase;
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
    if (client == null) {
      throw const ErrorDeNegocio('No pudimos inicializar el inicio de sesión.');
    }
    // La conexión de PowerSync no es un requisito para autenticar en Supabase.
    final AuthResponse res;
    try {
      res = await client.auth.signInWithPassword(
        email: correo,
        password: password,
      );
    } on AuthException catch (e) {
      throw ErrorDeNegocio(
        e.message.isNotEmpty
            ? 'No pudimos iniciar sesión: ${e.message}'
            : 'Credenciales inválidas.',
      );
    } catch (_) {
      _almacen.conectadoAInternet = false;
      throw const ErrorDeNegocio(
        'No pudimos conectar para iniciar sesión. Revisá la conexión e intentá de nuevo.',
      );
    }
    final user = res.user;
    if (user != null && res.session != null) {
      _almacen.conectadoAInternet = true;
      _almacen.usuarioActualId = user.id;
      await SincronizacionDirectaSupabase.cargarAcceso(_almacen, client);
      // El listener de autenticación inicia PowerSync. La vía directa solo
      // se usa si no se pudo abrir la base, sin duplicar su cola persistente.
      if (_almacen.db == null) {
        unawaited(
          SincronizacionDirectaSupabase.sincronizarTodo(_almacen, client),
        );
        SincronizacionDirectaSupabase.suscribirRealtime(_almacen, client);
      }
      unawaited(ServicioNotificacionesPush.registrarTokenEnSupabase());
      ServicioNotificacionesPush.suscribirAlertasTiempoReal();
      return;
    }
    throw const ErrorDeNegocio('No pudimos iniciar sesión. Intentá de nuevo.');
  }

  Future<void> cerrarSesion() async {
    final client = _supabaseOrNull;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    if (_almacen.db != null) {
      unawaited(_almacen.db!.disconnect());
    }
    _almacen.usuarioActualId = null;
  }
}

final sesionControllerProvider = Provider<SesionController>((ref) {
  return SesionController(ref.watch(almacenLocalProvider));
});
