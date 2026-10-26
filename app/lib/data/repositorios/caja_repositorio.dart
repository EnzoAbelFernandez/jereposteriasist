import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/formato/fechas.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/caja_modelos.dart';

abstract class CajaRepositorio {
  Stream<List<MovimientoCaja>> observarMovimientos(FiltroCaja filtro);
  Stream<ResumenCaja> observarResumen(FiltroCaja filtro);
  Future<String> registrarManual({
    required TipoMovimientoCaja tipo,
    required Dinero monto,
    required MedioPago medioPago,
    required String descripcion,
    DateTime? fecha,
  });
  Future<void> anularMovimiento(String id);
  Future<String> exportarCsv(FiltroCaja filtro);
}

class _CajaRepositorioLocal implements CajaRepositorio {
  _CajaRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  List<MovimientoCaja> _filtrar(FiltroCaja filtro) {
    final idsAnulados = _almacen.movimientosCaja.values
        .where((m) => m.anulaId != null)
        .map((m) => m.anulaId!)
        .toSet();
    final lista = <MovimientoCaja>[];
    for (final m in _almacen.movimientosCaja.values) {
      if (m.fecha.isBefore(filtro.desde) || m.fecha.isAfter(filtro.hasta)) {
        continue;
      }
      if (filtro.tipo != null && m.tipo != filtro.tipo) continue;
      if (filtro.medio != null && m.medioPago != filtro.medio) continue;
      lista.add(
        MovimientoCaja(
          id: m.id,
          fecha: m.fecha,
          tipo: m.tipo,
          monto: m.monto,
          medioPago: m.medioPago,
          concepto: m.concepto,
          descripcion: m.descripcion,
          pedidoId: m.pedidoId,
          compraId: m.compraId,
          gastoId: m.gastoId,
          anulaId: m.anulaId,
          creadoPor: m.creadoPor,
          creadoPorNombre:
              m.creadoPorNombre ?? _almacen.nombreDePerfil(m.creadoPor),
          anulado: idsAnulados.contains(m.id),
        ),
      );
    }
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  @override
  Stream<List<MovimientoCaja>> observarMovimientos(FiltroCaja filtro) {
    return _almacen.observar(() => _filtrar(filtro));
  }

  @override
  Stream<ResumenCaja> observarResumen(FiltroCaja filtro) {
    return _almacen.observar(() {
      var ingresos = Dinero.cero;
      var egresos = Dinero.cero;
      final porMedio = <MedioPago, Dinero>{
        for (final m in MedioPago.values) m: Dinero.cero,
      };
      for (final m in _almacen.movimientosCaja.values) {
        if (m.fecha.isBefore(filtro.desde) || m.fecha.isAfter(filtro.hasta)) {
          continue;
        }
        if (filtro.medio != null && m.medioPago != filtro.medio) continue;
        if (m.tipo == TipoMovimientoCaja.ingreso) {
          ingresos = ingresos + m.monto;
          porMedio[m.medioPago] =
              (porMedio[m.medioPago] ?? Dinero.cero) + m.monto;
        } else {
          egresos = egresos + m.monto;
          porMedio[m.medioPago] =
              (porMedio[m.medioPago] ?? Dinero.cero) - m.monto;
        }
      }
      return ResumenCaja(
        ingresos: ingresos,
        egresos: egresos,
        saldoPorMedio: porMedio,
      );
    });
  }

  @override
  Future<String> registrarManual({
    required TipoMovimientoCaja tipo,
    required Dinero monto,
    required MedioPago medioPago,
    required String descripcion,
    DateTime? fecha,
  }) async {
    if (!monto.esPositivo) {
      throw const ErrorDeNegocio('El monto debe ser mayor a cero.');
    }
    if (descripcion.trim().isEmpty) {
      throw const ErrorDeNegocio('Indicá una descripción para el movimiento.');
    }
    final id = _almacen.generarId();
    final uid = _almacen.usuarioActualId;
    _almacen.movimientosCaja[id] = MovimientoCaja(
      id: id,
      fecha: fecha ?? DateTime.now(),
      tipo: tipo,
      monto: monto,
      medioPago: medioPago,
      concepto: tipo == TipoMovimientoCaja.ingreso
          ? ConceptoCaja.otroIngreso
          : ConceptoCaja.otroEgreso,
      descripcion: descripcion.trim(),
      creadoPor: uid,
      creadoPorNombre: _almacen.nombreDePerfil(uid),
    );
    _almacen.notificar();
    return id;
  }

  @override
  Future<void> anularMovimiento(String id) async {
    final orig = _almacen.movimientosCaja[id];
    if (orig == null) {
      throw const ErrorDeNegocio('El movimiento no existe.');
    }
    final yaAnulado = _almacen.movimientosCaja.values.any(
      (m) => m.anulaId == id,
    );
    if (yaAnulado) {
      throw const ErrorDeNegocio('Este movimiento ya fue anulado.');
    }
    if (!orig.concepto.esManual) {
      throw const ErrorDeNegocio(
        'Este movimiento pertenece a un pedido, compra o gasto: anulalo desde su módulo.',
      );
    }
    final anulId = _almacen.generarId();
    final uid = _almacen.usuarioActualId;
    _almacen.movimientosCaja[anulId] = MovimientoCaja(
      id: anulId,
      fecha: DateTime.now(),
      tipo: orig.tipo == TipoMovimientoCaja.ingreso
          ? TipoMovimientoCaja.egreso
          : TipoMovimientoCaja.ingreso,
      monto: orig.monto,
      medioPago: orig.medioPago,
      concepto: ConceptoCaja.anulacion,
      descripcion: 'Anulación: ${orig.descripcionTexto}',
      anulaId: orig.id,
      creadoPor: uid,
      creadoPorNombre: _almacen.nombreDePerfil(uid),
    );
    _almacen.notificar();
  }

  String _escaparCsv(String valor) {
    final limpio = valor.replaceAll('"', '""');
    return '"$limpio"';
  }

  @override
  Future<String> exportarCsv(FiltroCaja filtro) async {
    final movs = _filtrar(filtro);
    final sb = StringBuffer();
    sb.writeln('Fecha;Tipo;Concepto;Medio de pago;Descripción;Monto;Estado');
    for (final m in movs) {
      sb.writeln(
        [
          _escaparCsv(formatearFechaHora(m.fecha)),
          _escaparCsv(m.tipo.etiqueta),
          _escaparCsv(m.concepto.etiqueta),
          _escaparCsv(m.medioPago.etiqueta),
          _escaparCsv(m.descripcionTexto),
          _escaparCsv(m.montoConSigno.formatear(conSigno: true)),
          _escaparCsv(m.anulado ? 'Anulado' : 'Registrado'),
        ].join(';'),
      );
    }
    return sb.toString();
  }
}

final cajaRepositorioProvider = Provider<CajaRepositorio>((ref) {
  return _CajaRepositorioLocal(ref.watch(almacenLocalProvider));
});

final movimientosCajaProvider = StreamProvider.autoDispose
    .family<List<MovimientoCaja>, FiltroCaja>((ref, filtro) {
      return ref.watch(cajaRepositorioProvider).observarMovimientos(filtro);
    });

final resumenCajaProvider = StreamProvider.autoDispose
    .family<ResumenCaja, FiltroCaja>((ref, filtro) {
      return ref.watch(cajaRepositorioProvider).observarResumen(filtro);
    });
