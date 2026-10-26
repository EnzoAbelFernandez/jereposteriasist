import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/formato/fechas.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/recetas_reportes_modelos.dart';

abstract class RecetasRepositorio {
  Stream<List<RecetaResumen>> observarActivas({
    String busqueda = '',
    String? productoId,
  });
  Stream<RecetaDetalle?> observarDetalle(String id);
  Stream<CostoProductoEstimado?> observarCostoDeProducto(String productoId);
  Future<String> crear(RecetaDatos datos);
  Future<void> actualizar(String id, RecetaDatos datos);
  Future<void> archivar(String id);
}

abstract class ReportesRepositorio {
  Stream<ResumenComprasSugeridas> observarComprasSugeridas({
    int diasHorizonte = 7,
  });
  Stream<ResumenFinancieroMensual> observarResumenFinanciero(
    PeriodoMensual periodo,
  );
  Stream<RankingsPeriodo> observarRankings(PeriodoMensual periodo);
}

Dinero? _estimarCostoInsumo(
  AlmacenLocal almacen,
  String insumoId,
  int cantidad,
) {
  if (cantidad <= 0) return Dinero.cero;
  DateTime? mejorFecha;
  int? ultimoCentavos;
  int? ultimaCantidad;

  for (final compra in almacen.compras.values) {
    if (compra.anulada) continue;
    final items = almacen.compraItems[compra.id] ?? const [];
    for (final it in items) {
      if (it.insumoId == insumoId && it.cantidad > 0) {
        if (mejorFecha == null || compra.fecha.isAfter(mejorFecha)) {
          mejorFecha = compra.fecha;
          ultimoCentavos = it.precioTotal.centavos;
          ultimaCantidad = it.cantidad;
        }
      }
    }
  }

  if (ultimoCentavos == null || ultimaCantidad == null || ultimaCantidad <= 0) {
    return null;
  }
  return Dinero((ultimoCentavos * cantidad) ~/ ultimaCantidad);
}

class _RecetasRepositorioLocal implements RecetasRepositorio {
  _RecetasRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  String? _limpiar(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  RecetaDetalle _armarDetalle(Receta r) {
    final prodNombre = r.productoId != null
        ? _almacen.productos[r.productoId!]?.nombre
        : null;
    final crudos = _almacen.recetaItems[r.id] ?? const <RecetaItem>[];
    final items = <RecetaItemDetalle>[];
    var completo = crudos.isNotEmpty;

    for (final it in crudos) {
      final insumo = _almacen.insumos[it.insumoId];
      final costo = _estimarCostoInsumo(_almacen, it.insumoId, it.cantidad);
      if (costo == null) completo = false;
      items.add(
        RecetaItemDetalle(
          item: it,
          insumoNombre: insumo?.nombre ?? 'Insumo',
          unidad: insumo?.unidad ?? Unidad.unidades,
          costoEstimado: costo,
        ),
      );
    }

    return RecetaDetalle(
      receta: r,
      productoNombre: prodNombre,
      items: items,
      tieneCostoCompleto: completo,
    );
  }

  @override
  Stream<List<RecetaResumen>> observarActivas({
    String busqueda = '',
    String? productoId,
  }) {
    final q = busqueda.trim().toLowerCase();
    return _almacen.observar(() {
      final res = <RecetaResumen>[];
      for (final r in _almacen.recetas.values) {
        if (r.archivada) continue;
        if (productoId != null && r.productoId != productoId) continue;
        final d = _armarDetalle(r);
        if (q.isNotEmpty) {
          final coincideNombre = r.nombre.toLowerCase().contains(q);
          final coincideProd =
              d.productoNombre?.toLowerCase().contains(q) ?? false;
          if (!coincideNombre && !coincideProd) continue;
        }
        res.add(
          RecetaResumen(
            receta: r,
            productoNombre: d.productoNombre,
            cantidadIngredientes: d.items.length,
            costoTotalEstimado: d.costoTotalEstimado,
            tieneCostoCompleto: d.tieneCostoCompleto,
          ),
        );
      }
      res.sort(
        (a, b) => a.receta.nombre.toLowerCase().compareTo(
          b.receta.nombre.toLowerCase(),
        ),
      );
      return res;
    });
  }

  @override
  Stream<RecetaDetalle?> observarDetalle(String id) {
    return _almacen.observar(() {
      final r = _almacen.recetas[id];
      if (r == null) return null;
      return _armarDetalle(r);
    });
  }

  @override
  Stream<CostoProductoEstimado?> observarCostoDeProducto(String productoId) {
    return _almacen.observar(() {
      final prod = _almacen.productos[productoId];
      if (prod == null) return null;
      Receta? vinculada;
      for (final r in _almacen.recetas.values) {
        if (!r.archivada && r.productoId == productoId) {
          vinculada = r;
          break;
        }
      }
      if (vinculada == null) return null;
      final d = _armarDetalle(vinculada);
      return CostoProductoEstimado(
        productoId: productoId,
        recetaId: vinculada.id,
        recetaNombre: vinculada.nombre,
        costoUnitario: d.costoPorUnidadRinde,
        precioVenta: prod.precioBase,
        tieneCostoCompleto: d.tieneCostoCompleto,
      );
    });
  }

  void _validar(RecetaDatos d) {
    if (d.nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre de la receta es obligatorio.');
    }
    if (d.rindeCantidad <= 0) {
      throw const ErrorDeNegocio(
        'La cantidad que rinde la receta debe ser mayor a cero.',
      );
    }
    if (d.items.isEmpty) {
      throw const ErrorDeNegocio('Agregá al menos un ingrediente a la receta.');
    }
    final vistos = <String>{};
    for (final it in d.items) {
      if (!_almacen.insumos.containsKey(it.insumoId)) {
        throw const ErrorDeNegocio('Elegí un insumo válido.');
      }
      if (it.cantidad <= 0) {
        throw const ErrorDeNegocio(
          'La cantidad de cada ingrediente debe ser mayor a cero.',
        );
      }
      if (!vistos.add(it.insumoId)) {
        throw const ErrorDeNegocio('No repitas el mismo insumo en la receta.');
      }
    }
  }

  @override
  Future<String> crear(RecetaDatos datos) async {
    _validar(datos);
    final id = _almacen.generarId();
    _almacen.recetas[id] = Receta(
      id: id,
      nombre: datos.nombre.trim(),
      productoId: datos.productoId,
      rindeCantidad: datos.rindeCantidad,
      rindeDescripcion: _limpiar(datos.rindeDescripcion),
      notas: _limpiar(datos.notas),
    );
    _almacen.recetaItems[id] = [
      for (final it in datos.items)
        RecetaItem(
          id: _almacen.generarId(),
          recetaId: id,
          insumoId: it.insumoId,
          cantidad: it.cantidad,
        ),
    ];
    _almacen.notificar();
    return id;
  }

  @override
  Future<void> actualizar(String id, RecetaDatos datos) async {
    final actual = _almacen.recetas[id];
    if (actual == null) {
      throw const ErrorDeNegocio('La receta no existe.');
    }
    _validar(datos);
    _almacen.recetas[id] = Receta(
      id: id,
      nombre: datos.nombre.trim(),
      productoId: datos.productoId,
      rindeCantidad: datos.rindeCantidad,
      rindeDescripcion: _limpiar(datos.rindeDescripcion),
      notas: _limpiar(datos.notas),
      archivadoEn: actual.archivadoEn,
    );
    _almacen.recetaItems[id] = [
      for (final it in datos.items)
        RecetaItem(
          id: _almacen.generarId(),
          recetaId: id,
          insumoId: it.insumoId,
          cantidad: it.cantidad,
        ),
    ];
    _almacen.notificar();
  }

  @override
  Future<void> archivar(String id) async {
    final actual = _almacen.recetas[id];
    if (actual == null) return;
    _almacen.recetas[id] = Receta(
      id: actual.id,
      nombre: actual.nombre,
      productoId: actual.productoId,
      rindeCantidad: actual.rindeCantidad,
      rindeDescripcion: actual.rindeDescripcion,
      notas: actual.notas,
      archivadoEn: DateTime.now(),
    );
    _almacen.notificar();
  }
}

class _ReportesRepositorioLocal implements ReportesRepositorio {
  _ReportesRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  @override
  Stream<ResumenComprasSugeridas> observarComprasSugeridas({
    int diasHorizonte = 7,
  }) {
    final dias = diasHorizonte < 1 ? 1 : diasHorizonte;
    return _almacen.observar(() {
      final desde = hoy();
      final hasta = desde.add(Duration(days: dias, hours: 23, minutes: 59));

      // Mapear productoId -> primera receta activa
      final recetaPorProducto = <String, Receta>{};
      for (final r in _almacen.recetas.values) {
        if (!r.archivada && r.productoId != null) {
          recetaPorProducto.putIfAbsent(r.productoId!, () => r);
        }
      }

      final requeridoPorInsumo = <String, int>{};
      var pedidosConsiderados = 0;

      for (final p in _almacen.pedidos.values) {
        if (!p.estado.esActivo) continue;
        if (p.fechaEntrega.isBefore(desde) || p.fechaEntrega.isAfter(hasta)) {
          continue;
        }
        pedidosConsiderados++;
        final itemsPedido = _almacen.pedidoItems[p.id] ?? const [];
        for (final ip in itemsPedido) {
          if (ip.productoId == null) continue;
          final receta = recetaPorProducto[ip.productoId!];
          if (receta == null) continue;
          final rinde = receta.rindeCantidad > 0 ? receta.rindeCantidad : 1;
          final ingredientes = _almacen.recetaItems[receta.id] ?? const [];
          for (final ing in ingredientes) {
            final cantNecesaria =
                ((ing.cantidad * ip.cantidad) + rinde - 1) ~/ rinde;
            requeridoPorInsumo[ing.insumoId] =
                (requeridoPorInsumo[ing.insumoId] ?? 0) + cantNecesaria;
          }
        }
      }

      final sugerencias = <ItemCompraSugerida>[];
      for (final ins in _almacen.insumos.values) {
        if (ins.archivado) continue;
        final stockActual = _almacen.stockDe(ins.id);
        final requerido = requeridoPorInsumo[ins.id] ?? 0;
        final objetivo = requerido + ins.stockMinimo;
        final faltante = objetivo - stockActual;
        if (faltante <= 0) continue;
        final costo = _estimarCostoInsumo(_almacen, ins.id, faltante);
        sugerencias.add(
          ItemCompraSugerida(
            insumo: ins,
            stockActual: stockActual,
            stockMinimo: ins.stockMinimo,
            requeridoPorPedidos: requerido,
            sugeridoComprar: faltante,
            costoEstimado: costo,
          ),
        );
      }

      sugerencias.sort((a, b) {
        final aConPedido = a.requeridoPorPedidos > 0;
        final bConPedido = b.requeridoPorPedidos > 0;
        if (aConPedido != bConPedido) return aConPedido ? -1 : 1;
        return a.insumo.nombre.toLowerCase().compareTo(
          b.insumo.nombre.toLowerCase(),
        );
      });

      return ResumenComprasSugeridas(
        diasHorizonte: dias,
        pedidosActivosEnHorizonte: pedidosConsiderados,
        items: sugerencias,
      );
    });
  }

  @override
  Stream<ResumenFinancieroMensual> observarResumenFinanciero(
    PeriodoMensual periodo,
  ) {
    return _almacen.observar(() {
      final refDate = DateTime(periodo.anio, periodo.mes, 1);
      final inicio = inicioDeMes(refDate);
      final fin = finDeMes(refDate);

      final idsCajaAnulados = _almacen.movimientosCaja.values
          .where((m) => m.anulaId != null)
          .map((m) => m.anulaId!)
          .toSet();

      var ingresosPedidos = Dinero.cero;
      var otrosIngresos = Dinero.cero;
      var egresosCompras = Dinero.cero;
      var egresosGastos = Dinero.cero;
      var otrosEgresos = Dinero.cero;

      for (final m in _almacen.movimientosCaja.values) {
        if (m.concepto == ConceptoCaja.anulacion) continue;
        if (idsCajaAnulados.contains(m.id)) continue;
        if (m.fecha.isBefore(inicio) || m.fecha.isAfter(fin)) continue;

        switch (m.concepto) {
          case ConceptoCaja.sena:
          case ConceptoCaja.pagoPedido:
            ingresosPedidos = ingresosPedidos + m.monto;
          case ConceptoCaja.otroIngreso:
            otrosIngresos = otrosIngresos + m.monto;
          case ConceptoCaja.compra:
            egresosCompras = egresosCompras + m.monto;
          case ConceptoCaja.gasto:
            egresosGastos = egresosGastos + m.monto;
          case ConceptoCaja.otroEgreso:
            otrosEgresos = otrosEgresos + m.monto;
          case ConceptoCaja.anulacion:
            break;
        }
      }

      var entregados = 0;
      var cancelados = 0;
      for (final p in _almacen.pedidos.values) {
        if (p.fechaEntrega.isBefore(inicio) || p.fechaEntrega.isAfter(fin)) {
          continue;
        }
        if (p.estado == EstadoPedido.entregado) entregados++;
        if (p.estado == EstadoPedido.cancelado) cancelados++;
      }

      final montoPorCat = <String, Dinero>{};
      var sumaGastosCat = Dinero.cero;
      for (final g in _almacen.gastos.values) {
        if (g.anulado) continue;
        if (g.fecha.isBefore(inicio) || g.fecha.isAfter(fin)) continue;
        montoPorCat[g.categoriaId] =
            (montoPorCat[g.categoriaId] ?? Dinero.cero) + g.monto;
        sumaGastosCat = sumaGastosCat + g.monto;
      }

      final desgloseGastos = <GastoPorCategoria>[];
      for (final entry in montoPorCat.entries) {
        final nombre =
            _almacen.categoriasGasto[entry.key]?.nombre ?? 'Categoría';
        final pct = sumaGastosCat.esPositivo
            ? (entry.value.centavos * 100) ~/ sumaGastosCat.centavos
            : 0;
        desgloseGastos.add(
          GastoPorCategoria(
            categoriaId: entry.key,
            categoriaNombre: nombre,
            monto: entry.value,
            porcentajeEntero: pct,
          ),
        );
      }
      desgloseGastos.sort((a, b) => b.monto.compareTo(a.monto));

      return ResumenFinancieroMensual(
        periodo: periodo,
        ingresosPedidos: ingresosPedidos,
        otrosIngresos: otrosIngresos,
        egresosCompras: egresosCompras,
        egresosGastos: egresosGastos,
        otrosEgresos: otrosEgresos,
        pedidosEntregados: entregados,
        pedidosCancelados: cancelados,
        gastosPorCategoria: desgloseGastos,
      );
    });
  }

  @override
  Stream<RankingsPeriodo> observarRankings(PeriodoMensual periodo) {
    return _almacen.observar(() {
      final refDate = DateTime(periodo.anio, periodo.mes, 1);
      final inicio = inicioDeMes(refDate);
      final fin = finDeMes(refDate);

      final prodUnidades = <String, int>{};
      final prodIngresos = <String, Dinero>{};
      final prodIds = <String, String?>{};

      final cliPedidos = <String, int>{};
      final cliTotales = <String, Dinero>{};

      for (final p in _almacen.pedidos.values) {
        if (p.estado == EstadoPedido.cancelado ||
            p.estado == EstadoPedido.presupuesto) {
          continue;
        }
        if (p.fechaEntrega.isBefore(inicio) || p.fechaEntrega.isAfter(fin)) {
          continue;
        }

        final items = _almacen.pedidoItems[p.id] ?? const [];
        var subtotal = Dinero.cero;
        for (final it in items) {
          subtotal = subtotal + it.subtotal;
          final clave = it.productoId != null
              ? (_almacen.productos[it.productoId!]?.nombre ?? it.descripcion)
              : it.descripcion;
          prodUnidades[clave] = (prodUnidades[clave] ?? 0) + it.cantidad;
          prodIngresos[clave] =
              (prodIngresos[clave] ?? Dinero.cero) + it.subtotal;
          prodIds.putIfAbsent(clave, () => it.productoId);
        }

        final bruto = subtotal - p.descuento;
        final totalPedido = bruto.esNegativo ? Dinero.cero : bruto;
        cliPedidos[p.clienteId] = (cliPedidos[p.clienteId] ?? 0) + 1;
        cliTotales[p.clienteId] =
            (cliTotales[p.clienteId] ?? Dinero.cero) + totalPedido;
      }

      final topProductos =
          <RankingProducto>[
            for (final clave in prodUnidades.keys)
              RankingProducto(
                nombre: clave,
                productoId: prodIds[clave],
                unidadesVendidas: prodUnidades[clave]!,
                ingresosTotales: prodIngresos[clave] ?? Dinero.cero,
              ),
          ]..sort((a, b) {
            final cmp = b.ingresosTotales.compareTo(a.ingresosTotales);
            if (cmp != 0) return cmp;
            return b.unidadesVendidas.compareTo(a.unidadesVendidas);
          });

      final topClientes =
          <RankingCliente>[
            for (final cid in cliPedidos.keys)
              RankingCliente(
                clienteId: cid,
                nombre: _almacen.clientes[cid]?.nombre ?? 'Cliente',
                esHabitual: _almacen.clientes[cid]?.esHabitual ?? false,
                cantidadPedidos: cliPedidos[cid]!,
                montoTotal: cliTotales[cid] ?? Dinero.cero,
              ),
          ]..sort((a, b) {
            final cmp = b.montoTotal.compareTo(a.montoTotal);
            if (cmp != 0) return cmp;
            return b.cantidadPedidos.compareTo(a.cantidadPedidos);
          });

      return RankingsPeriodo(
        periodo: periodo,
        productosMasVendidos: topProductos.take(10).toList(),
        mejoresClientes: topClientes.take(10).toList(),
      );
    });
  }
}

final recetasRepositorioProvider = Provider<RecetasRepositorio>((ref) {
  return _RecetasRepositorioLocal(ref.watch(almacenLocalProvider));
});

final recetasProvider = StreamProvider.autoDispose
    .family<List<RecetaResumen>, String>((ref, busqueda) {
      return ref
          .watch(recetasRepositorioProvider)
          .observarActivas(busqueda: busqueda);
    });

final recetaDetalleProvider = StreamProvider.autoDispose
    .family<RecetaDetalle?, String>((ref, id) {
      return ref.watch(recetasRepositorioProvider).observarDetalle(id);
    });

final costoProductoProvider = StreamProvider.autoDispose
    .family<CostoProductoEstimado?, String>((ref, productoId) {
      return ref
          .watch(recetasRepositorioProvider)
          .observarCostoDeProducto(productoId);
    });

final reportesRepositorioProvider = Provider<ReportesRepositorio>((ref) {
  return _ReportesRepositorioLocal(ref.watch(almacenLocalProvider));
});

final comprasSugeridasProvider = StreamProvider.autoDispose
    .family<ResumenComprasSugeridas, int>((ref, diasHorizonte) {
      return ref
          .watch(reportesRepositorioProvider)
          .observarComprasSugeridas(diasHorizonte: diasHorizonte);
    });

final resumenFinancieroMensualProvider = StreamProvider.autoDispose
    .family<ResumenFinancieroMensual, PeriodoMensual>((ref, periodo) {
      return ref
          .watch(reportesRepositorioProvider)
          .observarResumenFinanciero(periodo);
    });

final rankingsPeriodoProvider = StreamProvider.autoDispose
    .family<RankingsPeriodo, PeriodoMensual>((ref, periodo) {
      return ref.watch(reportesRepositorioProvider).observarRankings(periodo);
    });
