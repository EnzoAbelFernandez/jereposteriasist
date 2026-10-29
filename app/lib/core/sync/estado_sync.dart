import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/core/sync/supabase_connector.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:powersync/powersync.dart';

@immutable
class EstadoSync {
  const EstadoSync({
    this.conectado = false,
    this.conectando = false,
    this.subiendo = false,
    this.bajando = false,
    this.ultimaSync,
    this.cambiosPendientes,
    this.sincronizoAlgunaVez = false,
    this.baseDisponible = true,
    this.modoWeb = false,
    this.sesionIniciada = true,
    this.error,
  });

  factory EstadoSync.desdePowerSync(
    SyncStatus status, {
    int? cambiosPendientes,
    required bool sesionIniciada,
    String? errorCola,
  }) => EstadoSync(
    conectado: status.connected,
    conectando: status.connecting,
    subiendo: status.uploading,
    bajando: status.downloading,
    ultimaSync: status.lastSyncedAt,
    cambiosPendientes: cambiosPendientes,
    sincronizoAlgunaVez: status.hasSynced == true,
    sesionIniciada: sesionIniciada,
    error: errorCola ?? _describirError(status),
  );

  final bool conectado;
  final bool conectando;
  final bool subiendo;
  final bool bajando;
  final DateTime? ultimaSync;
  // null significa que todavía no se pudo consultar la cola persistente.
  final int? cambiosPendientes;
  final bool sincronizoAlgunaVez;
  final bool baseDisponible;
  final bool modoWeb;
  final bool sesionIniciada;
  final String? error;

  bool get tieneError => error != null || (!baseDisponible && !modoWeb);

  bool get alDia =>
      baseDisponible &&
      sesionIniciada &&
      conectado &&
      sincronizoAlgunaVez &&
      ultimaSync != null &&
      cambiosPendientes == 0 &&
      !subiendo &&
      !bajando &&
      error == null;

  String get textoEstado {
    if (!baseDisponible && !modoWeb) return 'Sin base local';
    if (!sesionIniciada) return 'Sin sesión';
    if (error != null) return 'Error de sincronización';
    if (modoWeb) return 'Modo web';
    if (!conectado) return conectando ? 'Conectando' : 'Sin sincronización';
    if (cambiosPendientes != null && cambiosPendientes! > 0) {
      return '$cambiosPendientes pendientes';
    }
    if (subiendo || bajando) return 'Sincronizando';
    return alDia ? 'Al día' : 'Verificando sincronización';
  }

  String get detalle {
    if (!baseDisponible && !modoWeb) {
      return 'No se pudo abrir la base local. No se puede garantizar que los cambios sobrevivan al cierre de la app.';
    }
    if (!sesionIniciada) {
      return 'Iniciá sesión para sincronizar con tu usuario.';
    }
    if (modoWeb && error == null) {
      return 'En el navegador, los cambios se guardan directamente en la nube. Necesitás conexión para guardar; si falla, el formulario te avisa.';
    }
    final pendientes = cambiosPendientes == null
        ? 'La cantidad de pendientes todavía no está disponible.'
        : 'Operaciones pendientes: $cambiosPendientes.';
    if (error != null) return '$error $pendientes';
    if (!conectado) {
      return 'PowerSync no está conectado. Los cambios se conservan en la cola local. $pendientes';
    }
    return textoEstado;
  }

  static String? _describirError(SyncStatus status) {
    final descarga = status.downloadError;
    if (descarga != null) {
      final texto = descarga.toString();
      final codigo = RegExp(r'PSYNC_[A-Z0-9]+').firstMatch(texto)?.group(0);
      if (codigo == 'PSYNC_S2103') {
        return 'La sesión de sincronización venció (PSYNC_S2103). Revisá la conexión y esperá la renovación de la sesión.';
      }
      if (codigo == 'PSYNC_S2101' || RegExp(r'\b401\b').hasMatch(texto)) {
        return 'PowerSync rechazó la autenticación${codigo == null ? '' : ' ($codigo)'}. Revisá la sesión y las claves configuradas en PowerSync Cloud.';
      }
      return 'No se pudieron descargar los cambios${codigo == null ? '' : ' ($codigo)'}. Revisá la conexión y la configuración de PowerSync.';
    }
    final subida = status.uploadError;
    if (subida is ErrorSubidaSync) return subida.mensaje;
    if (subida != null) {
      return 'No se pudieron subir los cambios. Siguen en la cola local; revisá la conexión, los permisos y los datos rechazados.';
    }
    return null;
  }
}

final estadoSyncProvider = StreamProvider<EstadoSync>((ref) {
  final almacen = ref.watch(almacenLocalProvider);
  final db = almacen.db;
  bool tieneSesion() =>
      almacen.usuarioActualId != null &&
      almacen.usuarioActualId != AlmacenLocal.idJefeLocal;
  if (db == null) {
    return almacen.observar(
      () => EstadoSync(
        baseDisponible: false,
        modoWeb: kIsWeb,
        sesionIniciada: tieneSesion(),
      ),
    );
  }

  return Stream<EstadoSync>.multi((controller) {
    var status = db.currentStatus;
    int? pendientes;
    String? errorCola;
    void emitir() {
      if (controller.isClosed) return;
      controller.add(
        EstadoSync.desdePowerSync(
          status,
          cambiosPendientes: pendientes,
          sesionIniciada: tieneSesion(),
          errorCola: errorCola,
        ),
      );
    }

    final estadoSub = db.statusStream.listen((valor) {
      status = valor;
      emitir();
    });
    // La misma tabla que consulta getUploadQueueStats(). Observarla permite
    // contar cambios nuevos aun cuando no hay conexión ni eventos de subida.
    final colaSub = db
        .watch('SELECT COUNT(*) AS cantidad FROM ps_crud')
        .listen(
          (rows) {
            pendientes = rows.first['cantidad'] as int;
            errorCola = null;
            emitir();
          },
          onError: (Object error) {
            pendientes = null;
            errorCola = 'No se pudo consultar la cola local de cambios.';
            emitir();
          },
        );
    final sesionSub = almacen
        .observar(() => almacen.usuarioActualId)
        .distinct()
        .listen((_) => emitir());
    emitir();
    controller.onCancel = () async {
      await Future.wait([
        estadoSub.cancel(),
        colaSub.cancel(),
        sesionSub.cancel(),
      ]);
    };
  });
});
