import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/formato/fechas.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';

@immutable
class MovimientoCaja {
  const MovimientoCaja({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.monto,
    required this.medioPago,
    required this.concepto,
    this.descripcion,
    this.pedidoId,
    this.compraId,
    this.gastoId,
    this.anulaId,
    this.creadoPor,
    this.creadoPorNombre,
    this.anulado = false,
  });

  final String id;
  final DateTime fecha;
  final TipoMovimientoCaja tipo;
  final Dinero monto;
  final MedioPago medioPago;
  final ConceptoCaja concepto;
  final String? descripcion;
  final String? pedidoId;
  final String? compraId;
  final String? gastoId;
  final String? anulaId;
  final String? creadoPor;
  final String? creadoPorNombre;
  final bool anulado;

  Dinero get montoConSigno =>
      tipo == TipoMovimientoCaja.ingreso ? monto : -monto;

  bool get anulable => concepto.esManual && !anulado;

  String get descripcionTexto {
    if (descripcion != null && descripcion!.trim().isNotEmpty) {
      return descripcion!;
    }
    return concepto.etiqueta;
  }
}

@immutable
class ResumenCaja {
  const ResumenCaja({
    required this.ingresos,
    required this.egresos,
    required this.saldoPorMedio,
  });

  final Dinero ingresos;
  final Dinero egresos;
  final Map<MedioPago, Dinero> saldoPorMedio;

  Dinero get saldo => ingresos - egresos;
}

@immutable
class FiltroCaja {
  const FiltroCaja({
    required this.desde,
    required this.hasta,
    this.tipo,
    this.medio,
  });

  factory FiltroCaja.mesActual() {
    final ahora = DateTime.now();
    return FiltroCaja(desde: inicioDeMes(ahora), hasta: finDeMes(ahora));
  }

  final DateTime desde;
  final DateTime hasta;
  final TipoMovimientoCaja? tipo;
  final MedioPago? medio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiltroCaja &&
          other.desde == desde &&
          other.hasta == hasta &&
          other.tipo == tipo &&
          other.medio == medio);

  @override
  int get hashCode => Object.hash(desde, hasta, tipo, medio);
}
