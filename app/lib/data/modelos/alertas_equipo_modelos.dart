import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/core/router/rutas.dart';

@immutable
class Alerta {
  const Alerta({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.entidadTipo,
    this.entidadId,
    this.leidaEn,
    required this.creadoEn,
  });

  final String id;
  final TipoAlerta tipo;
  final String titulo;
  final String mensaje;
  final String? entidadTipo;
  final String? entidadId;
  final DateTime? leidaEn;
  final DateTime creadoEn;

  bool get leida => leidaEn != null;

  String? get rutaDestino {
    final id = entidadId;
    switch (entidadTipo) {
      case 'cliente':
        return id != null ? Rutas.cliente(id) : Rutas.clientes;
      case 'insumo':
        return id != null ? Rutas.stockMovimientos(id) : Rutas.stock;
      case 'pedido':
        return id != null ? Rutas.pedido(id) : Rutas.pedidos;
      case 'tarea':
        return Rutas.tareas;
      default:
        return null;
    }
  }
}

@immutable
class Perfil {
  const Perfil({
    required this.id,
    required this.nombre,
    this.rol = Rol.empleado,
    this.telefono,
    this.activo = true,
  });

  final String id;
  final String nombre;
  final Rol rol;
  final String? telefono;
  final bool activo;

  bool get esJefe => rol == Rol.jefe;
}

@immutable
class Configuracion {
  const Configuracion({
    this.nombreNegocio = 'Mi repostería',
    this.diasAvisoCumple = 7,
    this.avisoCumpleAlcance = AlcanceAvisoCumple.todos,
    this.habitualMinPedidos = 3,
    this.habitualMeses = 12,
  });

  final String nombreNegocio;
  final int diasAvisoCumple;
  final AlcanceAvisoCumple avisoCumpleAlcance;
  final int habitualMinPedidos;
  final int habitualMeses;

  Configuracion copyWith({
    String? nombreNegocio,
    int? diasAvisoCumple,
    AlcanceAvisoCumple? avisoCumpleAlcance,
    int? habitualMinPedidos,
    int? habitualMeses,
  }) => Configuracion(
    nombreNegocio: nombreNegocio ?? this.nombreNegocio,
    diasAvisoCumple: diasAvisoCumple ?? this.diasAvisoCumple,
    avisoCumpleAlcance: avisoCumpleAlcance ?? this.avisoCumpleAlcance,
    habitualMinPedidos: habitualMinPedidos ?? this.habitualMinPedidos,
    habitualMeses: habitualMeses ?? this.habitualMeses,
  );
}
