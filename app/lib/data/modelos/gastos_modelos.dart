import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/formato/fechas.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';

@immutable
class CategoriaGasto {
  const CategoriaGasto({
    required this.id,
    required this.nombre,
    this.archivadoEn,
  });

  final String id;
  final String nombre;
  final DateTime? archivadoEn;

  bool get archivada => archivadoEn != null;
}

@immutable
class Gasto {
  const Gasto({
    required this.id,
    required this.fecha,
    required this.categoriaId,
    required this.descripcion,
    required this.monto,
    required this.medioPago,
    this.estado = EstadoDocumento.registrado,
    this.anuladoEn,
    this.motivoAnulacion,
    this.notas,
  });

  final String id;
  final DateTime fecha;
  final String categoriaId;
  final String descripcion;
  final Dinero monto;
  final MedioPago medioPago;
  final EstadoDocumento estado;
  final DateTime? anuladoEn;
  final String? motivoAnulacion;
  final String? notas;

  bool get anulado => estado == EstadoDocumento.anulado;
}

@immutable
class GastoResumen {
  const GastoResumen({
    required this.gasto,
    required this.categoriaNombre,
    this.creadoPorNombre,
  });

  final Gasto gasto;
  final String categoriaNombre;
  final String? creadoPorNombre;
}

class GastoDatos {
  GastoDatos({
    required this.fecha,
    required this.categoriaId,
    required this.descripcion,
    required this.monto,
    required this.medioPago,
    this.notas,
  });

  final DateTime fecha;
  final String categoriaId;
  final String descripcion;
  final Dinero monto;
  final MedioPago medioPago;
  final String? notas;
}

@immutable
class FiltroGastos {
  const FiltroGastos({
    required this.desde,
    required this.hasta,
    this.categoriaId,
    this.incluirAnulados = false,
  });

  factory FiltroGastos.mesActual() {
    final ahora = DateTime.now();
    return FiltroGastos(desde: inicioDeMes(ahora), hasta: finDeMes(ahora));
  }

  final DateTime desde;
  final DateTime hasta;
  final String? categoriaId;
  final bool incluirAnulados;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiltroGastos &&
          other.desde == desde &&
          other.hasta == hasta &&
          other.categoriaId == categoriaId &&
          other.incluirAnulados == incluirAnulados);

  @override
  int get hashCode => Object.hash(desde, hasta, categoriaId, incluirAnulados);
}
