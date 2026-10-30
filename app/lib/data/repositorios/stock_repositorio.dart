import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/stock_modelos.dart';

abstract class InsumosRepositorio {
  Stream<List<Insumo>> observarActivos({String busqueda = ''});
  Stream<List<InsumoConStock>> observarConStock({
    String busqueda = '',
    bool soloFaltantes = false,
  });
  Stream<InsumoConStock?> observarPorId(String id);
  Stream<int> observarCantidadFaltantes();
  Future<String> crear(InsumoDatos datos, {int stockInicial = 0});
  Future<void> actualizar(String id, InsumoDatos datos);
  Future<void> archivar(String id);
}

abstract class StockRepositorio {
  Stream<List<MovimientoStock>> observarMovimientos(String insumoId);
  Future<int> ajustarAConteo({
    required String insumoId,
    required int cantidadContada,
    String? nota,
  });
  Future<void> registrarMerma({
    required String insumoId,
    required int cantidad,
    String? nota,
  });
  Future<void> anularMovimiento(String movimientoId);
}

class _InsumosRepositorioLocal implements InsumosRepositorio {
  _InsumosRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  String? _limpiar(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  Stream<List<Insumo>> observarActivos({String busqueda = ''}) {
    final q = busqueda.trim().toLowerCase();
    return _almacen.observar(() {
      final lista =
          _almacen.insumos.values.where((i) {
            if (i.archivado) return false;
            if (q.isEmpty) return true;
            return i.nombre.toLowerCase().contains(q) ||
                (i.categoria?.toLowerCase().contains(q) ?? false);
          }).toList()..sort(
            (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
          );
      return lista;
    });
  }

  @override
  Stream<List<InsumoConStock>> observarConStock({
    String busqueda = '',
    bool soloFaltantes = false,
  }) {
    final q = busqueda.trim().toLowerCase();
    return _almacen.observar(() {
      final lista = <InsumoConStock>[];
      for (final i in _almacen.insumos.values) {
        if (i.archivado) continue;
        if (q.isNotEmpty &&
            !i.nombre.toLowerCase().contains(q) &&
            !(i.categoria?.toLowerCase().contains(q) ?? false)) {
          continue;
        }
        final item = InsumoConStock(insumo: i, stock: _almacen.stockDe(i.id));
        if (soloFaltantes && !item.faltante) continue;
        lista.add(item);
      }
      lista.sort((a, b) {
        if (a.faltante != b.faltante) return a.faltante ? -1 : 1;
        return a.insumo.nombre.toLowerCase().compareTo(
          b.insumo.nombre.toLowerCase(),
        );
      });
      return lista;
    });
  }

  @override
  Stream<InsumoConStock?> observarPorId(String id) {
    return _almacen.observar(() {
      final i = _almacen.insumos[id];
      if (i == null) return null;
      return InsumoConStock(insumo: i, stock: _almacen.stockDe(id));
    });
  }

  @override
  Stream<int> observarCantidadFaltantes() {
    return _almacen.observar(() {
      var n = 0;
      for (final i in _almacen.insumos.values) {
        if (i.archivado || i.stockMinimo <= 0) continue;
        if (_almacen.stockDe(i.id) < i.stockMinimo) n++;
      }
      return n;
    });
  }

  @override
  Future<String> crear(InsumoDatos datos, {int stockInicial = 0}) async {
    if ((datos.precioReferencia == null) !=
            (datos.cantidadReferencia == null) ||
        (datos.precioReferencia != null &&
            !datos.precioReferencia!.esPositivo) ||
        (datos.cantidadReferencia != null && datos.cantidadReferencia! <= 0)) {
      throw const ErrorDeNegocio(
        'Ingresá el precio y la cantidad de referencia, ambos mayores a cero.',
      );
    }
    if (datos.nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre del insumo es obligatorio.');
    }
    if (datos.stockMinimo < 0 || stockInicial < 0) {
      throw const ErrorDeNegocio('Las cantidades no pueden ser negativas.');
    }
    final id = _almacen.generarId();
    final insumo = Insumo(
      id: id,
      nombre: datos.nombre.trim(),
      unidad: datos.unidad,
      stockMinimo: datos.stockMinimo,
      precioReferencia: datos.precioReferencia,
      cantidadReferencia: datos.cantidadReferencia,
      fuenteCosto: datos.fuenteCosto,
      categoria: _limpiar(datos.categoria),
      notas: _limpiar(datos.notas),
    );
    MovimientoStock? movInicial;
    if (stockInicial > 0) {
      final movId = _almacen.generarId();
      movInicial = MovimientoStock(
        id: movId,
        insumoId: id,
        fecha: DateTime.now(),
        cantidad: stockInicial,
        tipo: TipoMovimientoStock.inicial,
        creadoPor: _almacen.usuarioActualId,
        creadoPorNombre: _almacen.nombreDePerfil(_almacen.usuarioActualId),
      );
    }
    await _almacen.persistirInsumo(insumo, movimientoInicial: movInicial);
    return id;
  }

  @override
  Future<void> actualizar(String id, InsumoDatos datos) async {
    if ((datos.precioReferencia == null) !=
            (datos.cantidadReferencia == null) ||
        (datos.precioReferencia != null &&
            !datos.precioReferencia!.esPositivo) ||
        (datos.cantidadReferencia != null && datos.cantidadReferencia! <= 0)) {
      throw const ErrorDeNegocio(
        'Ingresá el precio y la cantidad de referencia, ambos mayores a cero.',
      );
    }
    if (datos.nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre del insumo es obligatorio.');
    }
    final actual = _almacen.insumos[id];
    if (actual == null) {
      throw const ErrorDeNegocio('El insumo no existe.');
    }
    if (datos.unidad != actual.unidad) {
      final tieneMovimientos = _almacen.movimientosStock.values.any(
        (m) => m.insumoId == id,
      );
      if (tieneMovimientos) {
        throw const ErrorDeNegocio(
          'No se puede cambiar la unidad de medida de un insumo que ya tiene movimientos.',
        );
      }
    }
    final actualizado = Insumo(
      id: id,
      nombre: datos.nombre.trim(),
      unidad: datos.unidad,
      stockMinimo: datos.stockMinimo,
      precioReferencia: datos.precioReferencia,
      cantidadReferencia: datos.cantidadReferencia,
      fuenteCosto: datos.fuenteCosto,
      categoria: _limpiar(datos.categoria),
      notas: _limpiar(datos.notas),
      archivadoEn: actual.archivadoEn,
    );
    await _almacen.persistirInsumo(actualizado);
  }

  @override
  Future<void> archivar(String id) async {
    final i = _almacen.insumos[id];
    if (i == null) return;
    final archivado = Insumo(
      id: i.id,
      nombre: i.nombre,
      unidad: i.unidad,
      stockMinimo: i.stockMinimo,
      precioReferencia: i.precioReferencia,
      cantidadReferencia: i.cantidadReferencia,
      fuenteCosto: i.fuenteCosto,
      categoria: i.categoria,
      notas: i.notas,
      archivadoEn: DateTime.now(),
    );
    await _almacen.persistirInsumo(archivado);
  }
}

class _StockRepositorioLocal implements StockRepositorio {
  _StockRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  @override
  Stream<List<MovimientoStock>> observarMovimientos(String insumoId) {
    return _almacen.observar(() {
      final idsAnulados = _almacen.movimientosStock.values
          .where((m) => m.anulaId != null)
          .map((m) => m.anulaId!)
          .toSet();
      final lista =
          _almacen.movimientosStock.values
              .where((m) => m.insumoId == insumoId)
              .map(
                (m) => MovimientoStock(
                  id: m.id,
                  insumoId: m.insumoId,
                  fecha: m.fecha,
                  cantidad: m.cantidad,
                  tipo: m.tipo,
                  compraId: m.compraId,
                  produccionId: m.produccionId,
                  anulaId: m.anulaId,
                  nota: m.nota,
                  creadoPor: m.creadoPor,
                  creadoPorNombre:
                      m.creadoPorNombre ?? _almacen.nombreDePerfil(m.creadoPor),
                  anulado: idsAnulados.contains(m.id),
                ),
              )
              .toList()
            ..sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  @override
  Future<int> ajustarAConteo({
    required String insumoId,
    required int cantidadContada,
    String? nota,
  }) async {
    if (cantidadContada < 0) {
      throw const ErrorDeNegocio('La cantidad contada no puede ser negativa.');
    }
    final actual = _almacen.stockDe(insumoId);
    final diff = cantidadContada - actual;
    if (diff == 0) return 0;
    final id = _almacen.generarId();
    final mov = MovimientoStock(
      id: id,
      insumoId: insumoId,
      fecha: DateTime.now(),
      cantidad: diff,
      tipo: TipoMovimientoStock.ajuste,
      nota: nota?.trim().isEmpty == true ? null : nota?.trim(),
      creadoPor: _almacen.usuarioActualId,
      creadoPorNombre: _almacen.nombreDePerfil(_almacen.usuarioActualId),
    );
    await _almacen.persistirMovimientoStock(mov);
    return diff;
  }

  @override
  Future<void> registrarMerma({
    required String insumoId,
    required int cantidad,
    String? nota,
  }) async {
    if (cantidad <= 0) {
      throw const ErrorDeNegocio('La cantidad de merma debe ser mayor a cero.');
    }
    final id = _almacen.generarId();
    final mov = MovimientoStock(
      id: id,
      insumoId: insumoId,
      fecha: DateTime.now(),
      cantidad: -cantidad,
      tipo: TipoMovimientoStock.merma,
      nota: nota?.trim().isEmpty == true ? null : nota?.trim(),
      creadoPor: _almacen.usuarioActualId,
      creadoPorNombre: _almacen.nombreDePerfil(_almacen.usuarioActualId),
    );
    await _almacen.persistirMovimientoStock(mov);
  }

  @override
  Future<void> anularMovimiento(String movimientoId) async {
    final orig = _almacen.movimientosStock[movimientoId];
    if (orig == null) {
      throw const ErrorDeNegocio('El movimiento no existe.');
    }
    final yaAnulado = _almacen.movimientosStock.values.any(
      (m) => m.anulaId == movimientoId,
    );
    if (yaAnulado) {
      throw const ErrorDeNegocio('Este movimiento ya fue anulado.');
    }
    if (orig.tipo != TipoMovimientoStock.inicial &&
        orig.tipo != TipoMovimientoStock.ajuste &&
        orig.tipo != TipoMovimientoStock.merma) {
      throw const ErrorDeNegocio(
        'Este movimiento pertenece a una compra o producción: anulalo desde ahí.',
      );
    }
    final id = _almacen.generarId();
    final contra = MovimientoStock(
      id: id,
      insumoId: orig.insumoId,
      fecha: DateTime.now(),
      cantidad: -orig.cantidad,
      tipo: TipoMovimientoStock.anulacion,
      anulaId: orig.id,
      nota: 'Anulación',
      creadoPor: _almacen.usuarioActualId,
      creadoPorNombre: _almacen.nombreDePerfil(_almacen.usuarioActualId),
    );
    await _almacen.persistirMovimientoStock(contra);
  }
}

final insumosRepositorioProvider = Provider<InsumosRepositorio>((ref) {
  return _InsumosRepositorioLocal(ref.watch(almacenLocalProvider));
});

final stockRepositorioProvider = Provider<StockRepositorio>((ref) {
  return _StockRepositorioLocal(ref.watch(almacenLocalProvider));
});

final insumosProvider = StreamProvider.autoDispose.family<List<Insumo>, String>(
  (ref, busqueda) {
    return ref
        .watch(insumosRepositorioProvider)
        .observarActivos(busqueda: busqueda);
  },
);

final insumosConStockProvider = StreamProvider.autoDispose
    .family<List<InsumoConStock>, FiltroStock>((ref, filtro) {
      return ref
          .watch(insumosRepositorioProvider)
          .observarConStock(
            busqueda: filtro.busqueda,
            soloFaltantes: filtro.soloFaltantes,
          );
    });

final insumoConStockProvider = StreamProvider.autoDispose
    .family<InsumoConStock?, String>((ref, id) {
      return ref.watch(insumosRepositorioProvider).observarPorId(id);
    });

final cantidadFaltantesProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(insumosRepositorioProvider).observarCantidadFaltantes();
});

final movimientosStockProvider = StreamProvider.autoDispose
    .family<List<MovimientoStock>, String>((ref, insumoId) {
      return ref.watch(stockRepositorioProvider).observarMovimientos(insumoId);
    });
