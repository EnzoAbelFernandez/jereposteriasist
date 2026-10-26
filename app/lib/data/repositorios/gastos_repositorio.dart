import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/formato/fechas.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/caja_modelos.dart';
import 'package:jereposteria/data/modelos/gastos_modelos.dart';

abstract class GastosRepositorio {
  Stream<List<GastoResumen>> observarResumenes(FiltroGastos filtro);
  Stream<Dinero> observarTotal(FiltroGastos filtro);
  Future<String> registrar(GastoDatos datos);
  Future<void> anular(String id, {required String motivo});
  Stream<List<CategoriaGasto>> observarCategorias({
    bool incluirArchivadas = false,
  });
  Future<String> crearCategoria(String nombre);
  Future<void> renombrarCategoria(String id, String nombre);
  Future<void> archivarCategoria(String id);
  Future<void> desarchivarCategoria(String id);
}

class _GastosRepositorioLocal implements GastosRepositorio {
  _GastosRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  List<GastoResumen> _filtrar(FiltroGastos filtro) {
    final desde = soloFecha(filtro.desde);
    final hasta = soloFecha(filtro.hasta);
    final res = <GastoResumen>[];
    for (final g in _almacen.gastos.values) {
      if (!filtro.incluirAnulados && g.anulado) continue;
      final fg = soloFecha(g.fecha);
      if (fg.isBefore(desde) || fg.isAfter(hasta)) continue;
      if (filtro.categoriaId != null && g.categoriaId != filtro.categoriaId) {
        continue;
      }
      final cat =
          _almacen.categoriasGasto[g.categoriaId]?.nombre ?? 'Categoría';
      res.add(
        GastoResumen(
          gasto: g,
          categoriaNombre: cat,
          creadoPorNombre: _almacen.nombreDePerfil(_almacen.usuarioActualId),
        ),
      );
    }
    res.sort((a, b) => b.gasto.fecha.compareTo(a.gasto.fecha));
    return res;
  }

  @override
  Stream<List<GastoResumen>> observarResumenes(FiltroGastos filtro) {
    return _almacen.observar(() => _filtrar(filtro));
  }

  @override
  Stream<Dinero> observarTotal(FiltroGastos filtro) {
    return _almacen.observar(() {
      var suma = Dinero.cero;
      for (final r in _filtrar(filtro)) {
        if (!r.gasto.anulado) {
          suma = suma + r.gasto.monto;
        }
      }
      return suma;
    });
  }

  @override
  Future<String> registrar(GastoDatos datos) async {
    if (datos.descripcion.trim().isEmpty) {
      throw const ErrorDeNegocio('Indicá la descripción del gasto.');
    }
    if (!datos.monto.esPositivo) {
      throw const ErrorDeNegocio('El monto del gasto debe ser mayor a cero.');
    }
    if (!_almacen.categoriasGasto.containsKey(datos.categoriaId)) {
      throw const ErrorDeNegocio('Elegí una categoría de gasto.');
    }

    final id = _almacen.generarId();
    final uid = _almacen.usuarioActualId;
    _almacen.gastos[id] = Gasto(
      id: id,
      fecha: soloFecha(datos.fecha),
      categoriaId: datos.categoriaId,
      descripcion: datos.descripcion.trim(),
      monto: datos.monto,
      medioPago: datos.medioPago,
      notas: datos.notas?.trim().isEmpty == true ? null : datos.notas?.trim(),
    );

    final movCajaId = _almacen.generarId();
    _almacen.movimientosCaja[movCajaId] = MovimientoCaja(
      id: movCajaId,
      fecha: datos.fecha,
      tipo: TipoMovimientoCaja.egreso,
      monto: datos.monto,
      medioPago: datos.medioPago,
      concepto: ConceptoCaja.gasto,
      descripcion: datos.descripcion.trim(),
      gastoId: id,
      creadoPor: uid,
      creadoPorNombre: _almacen.nombreDePerfil(uid),
    );

    _almacen.notificar();
    return id;
  }

  @override
  Future<void> anular(String id, {required String motivo}) async {
    final g = _almacen.gastos[id];
    if (g == null) {
      throw const ErrorDeNegocio('El gasto no existe.');
    }
    if (g.anulado) {
      throw const ErrorDeNegocio('Este gasto ya fue anulado.');
    }
    if (motivo.trim().isEmpty) {
      throw const ErrorDeNegocio('Indicá el motivo de la anulación.');
    }

    final uid = _almacen.usuarioActualId;
    _almacen.gastos[id] = Gasto(
      id: g.id,
      fecha: g.fecha,
      categoriaId: g.categoriaId,
      descripcion: g.descripcion,
      monto: g.monto,
      medioPago: g.medioPago,
      estado: EstadoDocumento.anulado,
      anuladoEn: DateTime.now(),
      motivoAnulacion: motivo.trim(),
      notas: g.notas,
    );

    final movsCaja = _almacen.movimientosCaja.values
        .where((m) => m.gastoId == id && m.concepto != ConceptoCaja.anulacion)
        .toList();
    for (final orig in movsCaja) {
      final anulId = _almacen.generarId();
      _almacen.movimientosCaja[anulId] = MovimientoCaja(
        id: anulId,
        fecha: DateTime.now(),
        tipo: TipoMovimientoCaja.ingreso,
        monto: orig.monto,
        medioPago: orig.medioPago,
        concepto: ConceptoCaja.anulacion,
        descripcion: 'Anulación gasto: ${g.descripcion}',
        gastoId: id,
        anulaId: orig.id,
        creadoPor: uid,
        creadoPorNombre: _almacen.nombreDePerfil(uid),
      );
    }

    _almacen.notificar();
  }

  @override
  Stream<List<CategoriaGasto>> observarCategorias({
    bool incluirArchivadas = false,
  }) {
    return _almacen.observar(() {
      final lista =
          _almacen.categoriasGasto.values
              .where((c) => incluirArchivadas || !c.archivada)
              .toList()
            ..sort(
              (a, b) =>
                  a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
            );
      return lista;
    });
  }

  @override
  Future<String> crearCategoria(String nombre) async {
    if (nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre de la categoría es obligatorio.');
    }
    final id = _almacen.generarId();
    _almacen.categoriasGasto[id] = CategoriaGasto(
      id: id,
      nombre: nombre.trim(),
    );
    _almacen.notificar();
    return id;
  }

  @override
  Future<void> renombrarCategoria(String id, String nombre) async {
    if (nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre de la categoría es obligatorio.');
    }
    final actual = _almacen.categoriasGasto[id];
    if (actual == null) return;
    _almacen.categoriasGasto[id] = CategoriaGasto(
      id: id,
      nombre: nombre.trim(),
      archivadoEn: actual.archivadoEn,
    );
    _almacen.notificar();
  }

  @override
  Future<void> archivarCategoria(String id) async {
    final actual = _almacen.categoriasGasto[id];
    if (actual == null) return;
    _almacen.categoriasGasto[id] = CategoriaGasto(
      id: id,
      nombre: actual.nombre,
      archivadoEn: DateTime.now(),
    );
    _almacen.notificar();
  }

  @override
  Future<void> desarchivarCategoria(String id) async {
    final actual = _almacen.categoriasGasto[id];
    if (actual == null) return;
    _almacen.categoriasGasto[id] = CategoriaGasto(
      id: id,
      nombre: actual.nombre,
    );
    _almacen.notificar();
  }
}

final gastosRepositorioProvider = Provider<GastosRepositorio>((ref) {
  return _GastosRepositorioLocal(ref.watch(almacenLocalProvider));
});

final gastosProvider = StreamProvider.autoDispose
    .family<List<GastoResumen>, FiltroGastos>((ref, filtro) {
      return ref.watch(gastosRepositorioProvider).observarResumenes(filtro);
    });

final totalGastosProvider = StreamProvider.autoDispose
    .family<Dinero, FiltroGastos>((ref, filtro) {
      return ref.watch(gastosRepositorioProvider).observarTotal(filtro);
    });

final categoriasGastoProvider = StreamProvider.autoDispose
    .family<List<CategoriaGasto>, bool>((ref, incluirArchivadas) {
      return ref
          .watch(gastosRepositorioProvider)
          .observarCategorias(incluirArchivadas: incluirArchivadas);
    });
