import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';

enum FuenteCostoInsumo {
  ultimaCompra('ultima_compra', 'Última compra'),
  referencia('referencia', 'Precio de referencia');

  const FuenteCostoInsumo(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static FuenteCostoInsumo desdeValor(String? valor) =>
      valor == 'referencia' ? referencia : ultimaCompra;
}

@immutable
class Insumo {
  const Insumo({
    required this.id,
    required this.nombre,
    required this.unidad,
    this.stockMinimo = 0,
    this.precioReferencia,
    this.cantidadReferencia,
    this.fuenteCosto = FuenteCostoInsumo.ultimaCompra,
    this.categoria,
    this.notas,
    this.archivadoEn,
  });

  final String id;
  final String nombre;
  final Unidad unidad;
  final int stockMinimo;
  final Dinero? precioReferencia;
  final int? cantidadReferencia;
  final FuenteCostoInsumo fuenteCosto;
  final String? categoria;
  final String? notas;
  final DateTime? archivadoEn;

  bool get archivado => archivadoEn != null;
}

@immutable
class InsumoConStock {
  const InsumoConStock({required this.insumo, required this.stock});

  final Insumo insumo;
  final int stock;

  bool get faltante => insumo.stockMinimo > 0 && stock < insumo.stockMinimo;

  int get cantidadFaltante {
    final diff = insumo.stockMinimo - stock;
    return diff > 0 ? diff : 0;
  }

  String get stockTexto => insumo.unidad.formatear(stock);
}

class InsumoDatos {
  InsumoDatos({
    required this.nombre,
    required this.unidad,
    this.stockMinimo = 0,
    this.precioReferencia,
    this.cantidadReferencia,
    this.fuenteCosto = FuenteCostoInsumo.ultimaCompra,
    this.categoria,
    this.notas,
  });

  factory InsumoDatos.desde(Insumo i) => InsumoDatos(
    nombre: i.nombre,
    unidad: i.unidad,
    stockMinimo: i.stockMinimo,
    precioReferencia: i.precioReferencia,
    cantidadReferencia: i.cantidadReferencia,
    fuenteCosto: i.fuenteCosto,
    categoria: i.categoria,
    notas: i.notas,
  );

  final String nombre;
  final Unidad unidad;
  final int stockMinimo;
  final Dinero? precioReferencia;
  final int? cantidadReferencia;
  final FuenteCostoInsumo fuenteCosto;
  final String? categoria;
  final String? notas;
}

@immutable
class MovimientoStock {
  const MovimientoStock({
    required this.id,
    required this.insumoId,
    required this.fecha,
    required this.cantidad,
    required this.tipo,
    this.compraId,
    this.produccionId,
    this.anulaId,
    this.nota,
    this.creadoPor,
    this.creadoPorNombre,
    this.anulado = false,
  });

  final String id;
  final String insumoId;
  final DateTime fecha;
  final int cantidad;
  final TipoMovimientoStock tipo;
  final String? compraId;
  final String? produccionId;
  final String? anulaId;
  final String? nota;
  final String? creadoPor;
  final String? creadoPorNombre;
  final bool anulado;

  bool get esEntrada => cantidad > 0;

  bool get anulable =>
      !anulado &&
      (tipo == TipoMovimientoStock.inicial ||
          tipo == TipoMovimientoStock.ajuste ||
          tipo == TipoMovimientoStock.merma);
}

@immutable
class FiltroStock {
  const FiltroStock({this.busqueda = '', this.soloFaltantes = false});

  final String busqueda;
  final bool soloFaltantes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiltroStock &&
          other.busqueda == busqueda &&
          other.soloFaltantes == soloFaltantes);

  @override
  int get hashCode => Object.hash(busqueda, soloFaltantes);
}
