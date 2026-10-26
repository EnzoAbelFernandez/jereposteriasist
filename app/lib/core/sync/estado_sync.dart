import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class EstadoSync {
  const EstadoSync({
    this.conectado = false,
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
  return Stream.value(const EstadoSync());
});
