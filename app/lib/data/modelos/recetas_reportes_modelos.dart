import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';
import 'package:jereposteria/data/modelos/produccion_modelos.dart';
import 'package:jereposteria/data/modelos/stock_modelos.dart';

@immutable
class Receta {
  const Receta({
    required this.id,
    required this.nombre,
    this.productoId,
    this.rindeCantidad = 1,
    this.rindeDescripcion,
    this.notas,
    this.archivadoEn,
  });

  final String id;
  final String nombre;
  final String? productoId;
  final int rindeCantidad;
  final String? rindeDescripcion;
  final String? notas;
  final DateTime? archivadoEn;

  bool get archivada => archivadoEn != null;

  String get rindeTexto {
    if (rindeDescripcion != null && rindeDescripcion!.trim().isNotEmpty) {
      return '${rindeCantidad}x (${rindeDescripcion!.trim()})';
    }
    return 'Rinde $rindeCantidad u.';
  }
}

@immutable
class RecetaItem {
  const RecetaItem({
    required this.id,
    required this.recetaId,
    required this.insumoId,
    required this.cantidad,
  });

  final String id;
  final String recetaId;
  final String insumoId;
  final int cantidad;
}

@immutable
class RecetaItemDetalle {
  const RecetaItemDetalle({
    required this.item,
    required this.insumoNombre,
    required this.unidad,
    this.costoEstimado,
  });

  final RecetaItem item;
  final String insumoNombre;
  final Unidad unidad;
  final Dinero? costoEstimado;

  String get cantidadTexto => unidad.formatear(item.cantidad);
}

@immutable
class RecetaResumen {
  const RecetaResumen({
    required this.receta,
    this.productoNombre,
    required this.cantidadIngredientes,
    required this.costoTotalEstimado,
    required this.tieneCostoCompleto,
  });

  final Receta receta;
  final String? productoNombre;
  final int cantidadIngredientes;
  final Dinero costoTotalEstimado;
  final bool tieneCostoCompleto;

  Dinero get costoPorUnidadRinde => receta.rindeCantidad > 0
      ? Dinero(costoTotalEstimado.centavos ~/ receta.rindeCantidad)
      : costoTotalEstimado;
}

@immutable
class RecetaDetalle {
  const RecetaDetalle({
    required this.receta,
    this.productoNombre,
    required this.items,
    required this.tieneCostoCompleto,
  });

  final Receta receta;
  final String? productoNombre;
  final List<RecetaItemDetalle> items;
  final bool tieneCostoCompleto;

  Dinero get costoTotalEstimado => items.fold(
    Dinero.cero,
    (acc, i) => acc + (i.costoEstimado ?? Dinero.cero),
  );

  Dinero get costoPorUnidadRinde => receta.rindeCantidad > 0
      ? Dinero(costoTotalEstimado.centavos ~/ receta.rindeCantidad)
      : costoTotalEstimado;

  /// Escala los ingredientes de la receta para producir [lotes] veces la receta.
  List<ConsumoDatos> escalarConsumos({int lotes = 1}) {
    final factor = lotes < 1 ? 1 : lotes;
    return items
        .map(
          (i) => ConsumoDatos(
            insumoId: i.item.insumoId,
            cantidad: i.item.cantidad * factor,
          ),
        )
        .toList();
  }
}

class RecetaItemDatos {
  RecetaItemDatos({required this.insumoId, required this.cantidad});

  final String insumoId;
  final int cantidad;
}

class RecetaDatos {
  RecetaDatos({
    required this.nombre,
    this.productoId,
    this.rindeCantidad = 1,
    this.rindeDescripcion,
    this.notas,
    required this.items,
  });

  factory RecetaDatos.desde(RecetaDetalle d) => RecetaDatos(
    nombre: d.receta.nombre,
    productoId: d.receta.productoId,
    rindeCantidad: d.receta.rindeCantidad,
    rindeDescripcion: d.receta.rindeDescripcion,
    notas: d.receta.notas,
    items: d.items
        .map(
          (i) => RecetaItemDatos(
            insumoId: i.item.insumoId,
            cantidad: i.item.cantidad,
          ),
        )
        .toList(),
  );

  final String nombre;
  final String? productoId;
  final int rindeCantidad;
  final String? rindeDescripcion;
  final String? notas;
  final List<RecetaItemDatos> items;
}

@immutable
class CostoProductoEstimado {
  const CostoProductoEstimado({
    required this.productoId,
    required this.recetaId,
    required this.recetaNombre,
    required this.costoUnitario,
    this.precioVenta,
    required this.tieneCostoCompleto,
  });

  final String productoId;
  final String recetaId;
  final String recetaNombre;
  final Dinero costoUnitario;
  final Dinero? precioVenta;
  final bool tieneCostoCompleto;

  Dinero? get margenUnitario =>
      precioVenta != null ? precioVenta! - costoUnitario : null;

  /// Porcentaje entero de ganancia sobre el precio de venta (0 a 100).
  int? get margenPorcentaje {
    if (precioVenta == null || !precioVenta!.esPositivo) return null;
    final ganancia = precioVenta!.centavos - costoUnitario.centavos;
    return (ganancia * 100) ~/ precioVenta!.centavos;
  }

  /// Precio sugerido aplicando un multiplicador entero o porcentaje sobre el costo
  /// (por defecto x3 = +200% sobre costo de materia prima).
  Dinero precioSugerido({int multiplicadorCosto = 3}) =>
      costoUnitario.por(multiplicadorCosto);
}

@immutable
class ItemCompraSugerida {
  const ItemCompraSugerida({
    required this.insumo,
    required this.stockActual,
    required this.stockMinimo,
    required this.requeridoPorPedidos,
    required this.sugeridoComprar,
    this.costoEstimado,
  });

  final Insumo insumo;
  final int stockActual;
  final int stockMinimo;
  final int requeridoPorPedidos;
  final int sugeridoComprar;
  final Dinero? costoEstimado;

  String get stockActualTexto => insumo.unidad.formatear(stockActual);
  String get stockMinimoTexto => insumo.unidad.formatear(stockMinimo);
  String get requeridoTexto => insumo.unidad.formatear(requeridoPorPedidos);
  String get sugeridoTexto => insumo.unidad.formatear(sugeridoComprar);
}

@immutable
class ResumenComprasSugeridas {
  const ResumenComprasSugeridas({
    required this.diasHorizonte,
    required this.pedidosActivosEnHorizonte,
    required this.items,
  });

  final int diasHorizonte;
  final int pedidosActivosEnHorizonte;
  final List<ItemCompraSugerida> items;

  Dinero get costoTotalEstimado => items.fold(
    Dinero.cero,
    (acc, i) => acc + (i.costoEstimado ?? Dinero.cero),
  );
}

@immutable
class PeriodoMensual {
  const PeriodoMensual({required this.anio, required this.mes});

  factory PeriodoMensual.actual() {
    final ahora = DateTime.now();
    return PeriodoMensual(anio: ahora.year, mes: ahora.month);
  }

  final int anio;
  final int mes;

  PeriodoMensual get anterior => mes == 1
      ? PeriodoMensual(anio: anio - 1, mes: 12)
      : PeriodoMensual(anio: anio, mes: mes - 1);

  PeriodoMensual get siguiente => mes == 12
      ? PeriodoMensual(anio: anio + 1, mes: 1)
      : PeriodoMensual(anio: anio, mes: mes + 1);

  static const List<String> _nombresMes = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  String get etiqueta => '${_nombresMes[(mes - 1).clamp(0, 11)]} $anio';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodoMensual && other.anio == anio && other.mes == mes);

  @override
  int get hashCode => Object.hash(anio, mes);
}

@immutable
class GastoPorCategoria {
  const GastoPorCategoria({
    required this.categoriaId,
    required this.categoriaNombre,
    required this.monto,
    required this.porcentajeEntero,
  });

  final String categoriaId;
  final String categoriaNombre;
  final Dinero monto;
  final int porcentajeEntero;
}

@immutable
class ResumenFinancieroMensual {
  const ResumenFinancieroMensual({
    required this.periodo,
    required this.ingresosPedidos,
    required this.otrosIngresos,
    required this.egresosCompras,
    required this.egresosGastos,
    required this.otrosEgresos,
    required this.pedidosEntregados,
    required this.pedidosCancelados,
    required this.gastosPorCategoria,
  });

  final PeriodoMensual periodo;
  final Dinero ingresosPedidos;
  final Dinero otrosIngresos;
  final Dinero egresosCompras;
  final Dinero egresosGastos;
  final Dinero otrosEgresos;
  final int pedidosEntregados;
  final int pedidosCancelados;
  final List<GastoPorCategoria> gastosPorCategoria;

  Dinero get totalIngresos => ingresosPedidos + otrosIngresos;
  Dinero get totalEgresos => egresosCompras + egresosGastos + otrosEgresos;
  Dinero get resultadoNeto => totalIngresos - totalEgresos;
}

@immutable
class RankingProducto {
  const RankingProducto({
    required this.nombre,
    this.productoId,
    required this.unidadesVendidas,
    required this.ingresosTotales,
  });

  final String nombre;
  final String? productoId;
  final int unidadesVendidas;
  final Dinero ingresosTotales;
}

@immutable
class RankingCliente {
  const RankingCliente({
    required this.clienteId,
    required this.nombre,
    required this.esHabitual,
    required this.cantidadPedidos,
    required this.montoTotal,
  });

  final String clienteId;
  final String nombre;
  final bool esHabitual;
  final int cantidadPedidos;
  final Dinero montoTotal;
}

@immutable
class RankingsPeriodo {
  const RankingsPeriodo({
    required this.periodo,
    required this.productosMasVendidos,
    required this.mejoresClientes,
  });

  final PeriodoMensual periodo;
  final List<RankingProducto> productosMasVendidos;
  final List<RankingCliente> mejoresClientes;
}
