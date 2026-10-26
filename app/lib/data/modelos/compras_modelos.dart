import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';
import 'package:jereposteria/data/modelos/proveedores_modelos.dart';

@immutable
class Compra {
  const Compra({
    required this.id,
    this.proveedorId,
    required this.fecha,
    required this.medioPago,
    this.estado = EstadoDocumento.registrado,
    this.anuladoEn,
    this.motivoAnulacion,
    this.notas,
    this.creadoPor,
  });

  final String id;
  final String? proveedorId;
  final DateTime fecha;
  final MedioPago medioPago;
  final EstadoDocumento estado;
  final DateTime? anuladoEn;
  final String? motivoAnulacion;
  final String? notas;
  final String? creadoPor;

  bool get anulada => estado == EstadoDocumento.anulado;
}

@immutable
class CompraItem {
  const CompraItem({
    required this.id,
    required this.compraId,
    required this.insumoId,
    required this.cantidad,
    required this.precioTotal,
  });

  final String id;
  final String compraId;
  final String insumoId;
  final int cantidad;
  final Dinero precioTotal;
}

@immutable
class CompraItemDetalle {
  const CompraItemDetalle({
    required this.item,
    required this.insumoNombre,
    required this.unidad,
  });

  final CompraItem item;
  final String insumoNombre;
  final Unidad unidad;

  String get cantidadTexto => unidad.formatear(item.cantidad);
}

@immutable
class CompraResumen {
  const CompraResumen({
    required this.compra,
    this.proveedorNombre,
    required this.total,
    required this.cantidadItems,
    this.creadoPorNombre,
  });

  final Compra compra;
  final String? proveedorNombre;
  final Dinero total;
  final int cantidadItems;
  final String? creadoPorNombre;
}

@immutable
class CompraDetalle {
  const CompraDetalle({
    required this.compra,
    this.proveedor,
    required this.items,
    this.creadoPorNombre,
  });

  final Compra compra;
  final Proveedor? proveedor;
  final List<CompraItemDetalle> items;
  final String? creadoPorNombre;

  Dinero get total =>
      items.fold(Dinero.cero, (acc, i) => acc + i.item.precioTotal);
}

class CompraItemDatos {
  CompraItemDatos({
    required this.insumoId,
    required this.cantidad,
    required this.precioTotal,
  });

  final String insumoId;
  final int cantidad;
  final Dinero precioTotal;
}

class CompraDatos {
  CompraDatos({
    this.proveedorId,
    required this.fecha,
    required this.medioPago,
    this.notas,
    required this.items,
  });

  final String? proveedorId;
  final DateTime fecha;
  final MedioPago medioPago;
  final String? notas;
  final List<CompraItemDatos> items;

  Dinero get total => items.fold(Dinero.cero, (acc, i) => acc + i.precioTotal);
}

@immutable
class FiltroCompras {
  const FiltroCompras({this.desde, this.hasta, this.incluirAnuladas = false});

  final DateTime? desde;
  final DateTime? hasta;
  final bool incluirAnuladas;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiltroCompras &&
          other.desde == desde &&
          other.hasta == hasta &&
          other.incluirAnuladas == incluirAnuladas);

  @override
  int get hashCode => Object.hash(desde, hasta, incluirAnuladas);
}
