import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/data/local/almacen_local.dart';

@immutable
class EstadoSync {
  const EstadoSync({
    this.conectado = true,
    this.subiendo = false,
    this.bajando = false,
    this.ultimaSync,
    this.cambiosPendientes = 0,
  });

  final bool conectado;
  final bool subiendo;
  final bool bajando;
  final DateTime? ultimaSync;
  final int cambiosPendientes;
}

final estadoSyncProvider = StreamProvider<EstadoSync>((ref) {
  final almacen = ref.watch(almacenLocalProvider);
  final db = almacen.db;
  if (db == null) {
    return almacen.observar(
      () => EstadoSync(
        conectado: almacen.conectadoAInternet,
        ultimaSync: DateTime.now(),
      ),
    );
  }

  return db.statusStream.map(
    (status) => EstadoSync(
      conectado: status.connected,
      subiendo: status.uploading,
      bajando: status.downloading,
      ultimaSync: status.lastSyncedAt,
      cambiosPendientes: status.uploading ? 1 : 0,
    ),
  );
});
