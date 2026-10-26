import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/pedidos_modelos.dart';
import 'package:jereposteria/data/modelos/produccion_modelos.dart';
import 'package:jereposteria/data/modelos/stock_modelos.dart';

abstract class ProduccionRepositorio {
  Stream<List<ProduccionResumen>> observarResumenes(FiltroProduccion filtro);
  Stream<ProduccionDetalle?> observarDetalle(String id);
  Future<String> registrar(ProduccionDatos datos);
  Future<void> anular(String id, {required String motivo});
}

class _ProduccionRepositorioLocal implements ProduccionRepositorio {
  _ProduccionRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  @override
  Stream<List<ProduccionResumen>> observarResumenes(FiltroProduccion filtro) {
    return _almacen.observar(() {
      final res = <ProduccionResumen>[];
      for (final p in _almacen.producciones.values) {
        if (!filtro.incluirAnuladas && p.anulada) continue;
        if (p.fecha.isBefore(filtro.desde) || p.fecha.isAfter(filtro.hasta)) {
          continue;
        }
        final prodNombre = p.productoId == null
            ? null
            : _almacen.productos[p.productoId!]?.nombre;
        final pedidoNum = p.pedidoId == null
            ? null
            : _almacen.pedidos[p.pedidoId!]?.numero;
        final cantInsumos = _almacen.movimientosStock.values
            .where(
              (m) =>
                  m.produccionId == p.id &&
                  m.tipo == TipoMovimientoStock.produccion,
            )
            .length;
        res.add(
          ProduccionResumen(
            produccion: p,
            productoNombre: prodNombre,
            pedidoNumero: pedidoNum,
            cantidadInsumos: cantInsumos,
            creadoPorNombre: _almacen.nombreDePerfil(_almacen.usuarioActualId),
          ),
        );
      }
      res.sort((a, b) => b.produccion.fecha.compareTo(a.produccion.fecha));
      return res;
    });
  }

  @override
  Stream<ProduccionDetalle?> observarDetalle(String id) {
    return _almacen.observar(() {
      final p = _almacen.producciones[id];
      if (p == null) return null;
      final prod = p.productoId == null
          ? null
          : _almacen.productos[p.productoId!];
      PedidoResumen? pedidoRes;
      if (p.pedidoId != null && _almacen.pedidos.containsKey(p.pedidoId)) {
        final ped = _almacen.pedidos[p.pedidoId!]!;
        final cli = _almacen.clientes[ped.clienteId];
        pedidoRes = PedidoResumen(
          pedido: ped,
          clienteNombre: cli?.nombre ?? 'Cliente',
          clienteTelefono: cli?.telefono,
          total: Dinero.cero,
          pagado: Dinero.cero,
          cantidadItems: (_almacen.pedidoItems[ped.id] ?? const []).length,
        );
      }
      final consumos = _almacen.movimientosStock.values
          .where(
            (m) =>
                m.produccionId == id &&
                m.tipo == TipoMovimientoStock.produccion,
          )
          .map((m) {
            final ins = _almacen.insumos[m.insumoId];
            return ConsumoDetalle(
              movimiento: m,
              insumoNombre: ins?.nombre ?? 'Insumo',
              unidad: ins?.unidad ?? Unidad.unidades,
            );
          })
          .toList();
      return ProduccionDetalle(
        produccion: p,
        producto: prod,
        pedido: pedidoRes,
        consumos: consumos,
        creadoPorNombre: _almacen.nombreDePerfil(_almacen.usuarioActualId),
      );
    });
  }

  @override
  Future<String> registrar(ProduccionDatos datos) async {
    if (datos.descripcion.trim().isEmpty) {
      throw const ErrorDeNegocio('Indicá qué se produjo.');
    }
    if (datos.cantidad <= 0) {
      throw const ErrorDeNegocio(
        'La cantidad producida debe ser mayor a cero.',
      );
    }
    for (final c in datos.consumos) {
      if (c.insumoId.trim().isEmpty ||
          !_almacen.insumos.containsKey(c.insumoId)) {
        throw const ErrorDeNegocio('Elegí un insumo válido.');
      }
      if (c.cantidad <= 0) {
        throw const ErrorDeNegocio(
          'La cantidad consumida debe ser mayor a cero.',
        );
      }
    }

    final id = _almacen.generarId();
    final uid = _almacen.usuarioActualId;
    _almacen.producciones[id] = Produccion(
      id: id,
      fecha: datos.fecha,
      productoId: datos.productoId,
      descripcion: datos.descripcion.trim(),
      cantidad: datos.cantidad,
      pedidoId: datos.pedidoId,
      recetaId: datos.recetaId,
      notas: datos.notas?.trim().isEmpty == true ? null : datos.notas?.trim(),
    );

    for (final c in datos.consumos) {
      final movId = _almacen.generarId();
      _almacen.movimientosStock[movId] = MovimientoStock(
        id: movId,
        insumoId: c.insumoId,
        fecha: datos.fecha,
        cantidad: -c.cantidad,
        tipo: TipoMovimientoStock.produccion,
        produccionId: id,
        creadoPor: uid,
        creadoPorNombre: _almacen.nombreDePerfil(uid),
      );
      _almacen.evaluarAlertaStockBajo(c.insumoId);
    }

    _almacen.notificar();
    return id;
  }

  @override
  Future<void> anular(String id, {required String motivo}) async {
    final p = _almacen.producciones[id];
    if (p == null) {
      throw const ErrorDeNegocio('La producción no existe.');
    }
    if (p.anulada) {
      throw const ErrorDeNegocio('Esta producción ya fue anulada.');
    }
    if (motivo.trim().isEmpty) {
      throw const ErrorDeNegocio('Indicá el motivo de la anulación.');
    }

    final uid = _almacen.usuarioActualId;
    _almacen.producciones[id] = Produccion(
      id: p.id,
      fecha: p.fecha,
      productoId: p.productoId,
      descripcion: p.descripcion,
      cantidad: p.cantidad,
      pedidoId: p.pedidoId,
      recetaId: p.recetaId,
      estado: EstadoDocumento.anulado,
      anuladoEn: DateTime.now(),
      motivoAnulacion: motivo.trim(),
      notas: p.notas,
    );

    final movs = _almacen.movimientosStock.values
        .where(
          (m) =>
              m.produccionId == id && m.tipo != TipoMovimientoStock.anulacion,
        )
        .toList();
    for (final orig in movs) {
      final anulId = _almacen.generarId();
      _almacen.movimientosStock[anulId] = MovimientoStock(
        id: anulId,
        insumoId: orig.insumoId,
        fecha: DateTime.now(),
        cantidad: -orig.cantidad,
        tipo: TipoMovimientoStock.anulacion,
        produccionId: id,
        anulaId: orig.id,
        nota: 'Anulación producción: ${motivo.trim()}',
        creadoPor: uid,
        creadoPorNombre: _almacen.nombreDePerfil(uid),
      );
    }

    _almacen.notificar();
  }
}

final produccionRepositorioProvider = Provider<ProduccionRepositorio>((ref) {
  return _ProduccionRepositorioLocal(ref.watch(almacenLocalProvider));
});

final produccionesProvider = StreamProvider.autoDispose
    .family<List<ProduccionResumen>, FiltroProduccion>((ref, filtro) {
      return ref.watch(produccionRepositorioProvider).observarResumenes(filtro);
    });

final produccionDetalleProvider = StreamProvider.autoDispose
    .family<ProduccionDetalle?, String>((ref, id) {
      return ref.watch(produccionRepositorioProvider).observarDetalle(id);
    });
