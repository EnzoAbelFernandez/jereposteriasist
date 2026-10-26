import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/formato/fechas.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';

@immutable
class Cliente {
  const Cliente({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.direccion,
    this.cumpleDia,
    this.cumpleMes,
    this.cumpleAnio,
    this.preferencias,
    this.alergias,
    this.notas,
    this.habitualModo = HabitualModo.auto,
    this.habitualAuto = false,
    this.archivadoEn,
    required this.creadoEn,
  });

  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final int? cumpleDia;
  final int? cumpleMes;
  final int? cumpleAnio;
  final String? preferencias;
  final String? alergias;
  final String? notas;
  final HabitualModo habitualModo;
  final bool habitualAuto;
  final DateTime? archivadoEn;
  final DateTime creadoEn;

  bool get esHabitual {
    switch (habitualModo) {
      case HabitualModo.si:
        return true;
      case HabitualModo.no:
        return false;
      case HabitualModo.auto:
        return habitualAuto;
    }
  }

  bool get archivado => archivadoEn != null;

  bool get tieneCumple => cumpleDia != null && cumpleMes != null;

  DateTime? proximoCumple(DateTime desde) {
    if (!tieneCumple) return null;
    return proximoCumpleanos(dia: cumpleDia!, mes: cumpleMes!, desde: desde);
  }

  int? diasParaCumple(DateTime desde) {
    final prox = proximoCumple(desde);
    if (prox == null) return null;
    return prox.difference(soloFecha(desde)).inDays;
  }

  String? get cumpleTexto {
    if (!tieneCumple) return null;
    return formatearDiaMesLargo(cumpleDia!, cumpleMes!);
  }
}

class ClienteDatos {
  ClienteDatos({
    required this.nombre,
    this.telefono,
    this.email,
    this.direccion,
    this.cumpleDia,
    this.cumpleMes,
    this.cumpleAnio,
    this.preferencias,
    this.alergias,
    this.notas,
    this.habitualModo = HabitualModo.auto,
  });

  factory ClienteDatos.desde(Cliente c) => ClienteDatos(
    nombre: c.nombre,
    telefono: c.telefono,
    email: c.email,
    direccion: c.direccion,
    cumpleDia: c.cumpleDia,
    cumpleMes: c.cumpleMes,
    cumpleAnio: c.cumpleAnio,
    preferencias: c.preferencias,
    alergias: c.alergias,
    notas: c.notas,
    habitualModo: c.habitualModo,
  );

  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final int? cumpleDia;
  final int? cumpleMes;
  final int? cumpleAnio;
  final String? preferencias;
  final String? alergias;
  final String? notas;
  final HabitualModo habitualModo;
}

@immutable
class ClienteConCumple {
  const ClienteConCumple({
    required this.cliente,
    required this.fecha,
    required this.dias,
  });

  final Cliente cliente;
  final DateTime fecha;
  final int dias;
}
