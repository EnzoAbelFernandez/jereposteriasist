import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/formato/fechas.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';
import 'package:jereposteria/data/modelos/pedidos_modelos.dart';
import 'package:jereposteria/data/modelos/productos_modelos.dart';
import 'package:jereposteria/data/modelos/stock_modelos.dart';

@immutable
class Produccion {
  const Produccion({
    required this.id,
    required this.fecha,
    this.productoId,
    required this.descripcion,
    this.cantidad = 1,
    this.pedidoId,
    this.recetaId,
    this.estado = EstadoDocumento.registrado,
    this.anuladoEn,
    this.motivoAnulacion,
    this.notas,
  });

  final String id;
  final DateTime fecha;
  final String? productoId;
  final String descripcion;
  final int cantidad;
  final String? pedidoId;
  final String? recetaId;
  final EstadoDocumento estado;
  final DateTime? anuladoEn;
  final String? motivoAnulacion;
  final String? notas;

  bool get anulada => estado == EstadoDocumento.anulado;
}

@immutable
class ConsumoDetalle {
  const ConsumoDetalle({
    required this.movimiento,
    required this.insumoNombre,
    required this.unidad,
  });

  final MovimientoStock movimiento;
  final String insumoNombre;
  final Unidad unidad;

  String get cantidadTexto => unidad.formatear(movimiento.cantidad.abs());
}

@immutable
class ProduccionResumen {
  const ProduccionResumen({
    required this.produccion,
    this.productoNombre,
    this.pedidoNumero,
    required this.cantidadInsumos,
    this.creadoPorNombre,
  });

  final Produccion produccion;
  final String? productoNombre;
  final int? pedidoNumero;
  final int cantidadInsumos;
  final String? creadoPorNombre;
}

@immutable
class ProduccionDetalle {
  const ProduccionDetalle({
    required this.produccion,
    this.producto,
    this.pedido,
    required this.consumos,
    this.creadoPorNombre,
  });

  final Produccion produccion;
  final Producto? producto;
  final PedidoResumen? pedido;
  final List<ConsumoDetalle> consumos;
  final String? creadoPorNombre;
}

class ConsumoDatos {
  ConsumoDatos({required this.insumoId, required this.cantidad});

  final String insumoId;
  final int cantidad;
}

class ProduccionDatos {
  ProduccionDatos({
    required this.fecha,
    this.productoId,
    required this.descripcion,
    this.cantidad = 1,
    this.pedidoId,
    this.recetaId,
    this.notas,
    this.consumos = const [],
  });

  final DateTime fecha;
  final String? productoId;
  final String descripcion;
  final int cantidad;
  final String? pedidoId;
  final String? recetaId;
  final String? notas;
  final List<ConsumoDatos> consumos;
}

@immutable
class FiltroProduccion {
  const FiltroProduccion({
    required this.desde,
    required this.hasta,
    this.incluirAnuladas = false,
  });

  factory FiltroProduccion.ultimos30Dias() {
    final h = hoy();
    return FiltroProduccion(
      desde: h.subtract(const Duration(days: 30)),
      hasta: h.add(const Duration(days: 1)),
    );
  }

  final DateTime desde;
  final DateTime hasta;
  final bool incluirAnuladas;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiltroProduccion &&
          other.desde == desde &&
          other.hasta == hasta &&
          other.incluirAnuladas == incluirAnuladas);

  @override
  int get hashCode => Object.hash(desde, hasta, incluirAnuladas);
}
