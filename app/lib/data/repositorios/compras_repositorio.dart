import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/caja_modelos.dart';
import 'package:jereposteria/data/modelos/compras_modelos.dart';
import 'package:jereposteria/data/modelos/stock_modelos.dart';

abstract class ComprasRepositorio {
  Stream<List<CompraResumen>> observarResumenes(FiltroCompras filtro);
  Stream<CompraDetalle?> observarDetalle(String id);
  Future<String> registrar(CompraDatos datos);
  Future<void> anular(String id, {required String motivo});
}

class _ComprasRepositorioLocal implements ComprasRepositorio {
  _ComprasRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  @override
  Stream<List<CompraResumen>> observarResumenes(FiltroCompras filtro) {
    return _almacen.observar(() {
      final res = <CompraResumen>[];
      for (final c in _almacen.compras.values) {
        if (!filtro.incluirAnuladas && c.anulada) continue;
        if (filtro.desde != null && c.fecha.isBefore(filtro.desde!)) continue;
        if (filtro.hasta != null && c.fecha.isAfter(filtro.hasta!)) continue;
        final items = _almacen.compraItems[c.id] ?? const [];
        final total = items.fold(Dinero.cero, (acc, i) => acc + i.precioTotal);
        final prov = c.proveedorId == null
            ? null
            : _almacen.proveedores[c.proveedorId!]?.nombre;
        res.add(
          CompraResumen(
            compra: c,
            proveedorNombre: prov,
            total: total,
            cantidadItems: items.length,
            creadoPorNombre: _almacen.nombreDePerfil(c.creadoPor),
          ),
        );
      }
      res.sort((a, b) => b.compra.fecha.compareTo(a.compra.fecha));
      return res;
    });
  }

  @override
  Stream<CompraDetalle?> observarDetalle(String id) {
    return _almacen.observar(() {
      final c = _almacen.compras[id];
      if (c == null) return null;
      final prov = c.proveedorId == null
          ? null
          : _almacen.proveedores[c.proveedorId!];
      final items = (_almacen.compraItems[id] ?? const []).map((item) {
        final ins = _almacen.insumos[item.insumoId];
        return CompraItemDetalle(
          item: item,
          insumoNombre: ins?.nombre ?? 'Insumo',
          unidad: ins?.unidad ?? Unidad.unidades,
        );
      }).toList();
      return CompraDetalle(
        compra: c,
        proveedor: prov,
        items: items,
        creadoPorNombre: _almacen.nombreDePerfil(c.creadoPor),
      );
    });
  }

  @override
  Future<String> registrar(CompraDatos datos) async {
    if (datos.items.isEmpty) {
      throw const ErrorDeNegocio('Agregá al menos un insumo a la compra.');
    }
    for (final item in datos.items) {
      if (item.insumoId.trim().isEmpty ||
          !_almacen.insumos.containsKey(item.insumoId)) {
        throw const ErrorDeNegocio('Seleccioná un insumo válido.');
      }
      if (item.cantidad <= 0) {
        throw const ErrorDeNegocio(
          'La cantidad comprada debe ser mayor a cero.',
        );
      }
      if (item.precioTotal.esNegativo) {
        throw const ErrorDeNegocio('El precio no puede ser negativo.');
      }
    }

    final id = _almacen.generarId();
    final uid = _almacen.usuarioActualId;
    final notasLimpias = datos.notas?.trim().isEmpty == true
        ? null
        : datos.notas?.trim();

    final compra = Compra(
      id: id,
      proveedorId: datos.proveedorId,
      fecha: datos.fecha,
      medioPago: datos.medioPago,
      notas: notasLimpias,
      creadoPor: uid,
    );

    final listaItems = <CompraItem>[];
    final movsStock = <MovimientoStock>[];
    for (final i in datos.items) {
      final itemId = _almacen.generarId();
      listaItems.add(
        CompraItem(
          id: itemId,
          compraId: id,
          insumoId: i.insumoId,
          cantidad: i.cantidad,
          precioTotal: i.precioTotal,
        ),
      );

      final movStockId = _almacen.generarId();
      movsStock.add(
        MovimientoStock(
          id: movStockId,
          insumoId: i.insumoId,
          fecha: datos.fecha,
          cantidad: i.cantidad,
          tipo: TipoMovimientoStock.compra,
          compraId: id,
          creadoPor: uid,
          creadoPorNombre: _almacen.nombreDePerfil(uid),
        ),
      );
    }

    final total = datos.total;
    final provNombre = datos.proveedorId == null
        ? null
        : _almacen.proveedores[datos.proveedorId!]?.nombre;
    final movCaja = MovimientoCaja(
      id: _almacen.generarId(),
      fecha: datos.fecha,
      tipo: TipoMovimientoCaja.egreso,
      monto: total,
      medioPago: datos.medioPago,
      concepto: ConceptoCaja.compra,
      descripcion: provNombre != null
          ? 'Compra a $provNombre'
          : 'Compra de insumos',
      compraId: id,
      creadoPor: uid,
      creadoPorNombre: _almacen.nombreDePerfil(uid),
    );

    await _almacen.persistirCompra(compra, listaItems, movsStock, movCaja);
    return id;
  }

  @override
  Future<void> anular(String id, {required String motivo}) async {
    final c = _almacen.compras[id];
    if (c == null) {
      throw const ErrorDeNegocio('La compra no existe.');
    }
    if (c.anulada) {
      throw const ErrorDeNegocio('Esta compra ya fue anulada.');
    }
    if (motivo.trim().isEmpty) {
      throw const ErrorDeNegocio('Indicá el motivo de la anulación.');
    }

    final uid = _almacen.usuarioActualId;
    final compraAnulada = Compra(
      id: c.id,
      proveedorId: c.proveedorId,
      fecha: c.fecha,
      medioPago: c.medioPago,
      estado: EstadoDocumento.anulado,
      anuladoEn: DateTime.now(),
      motivoAnulacion: motivo.trim(),
      notas: c.notas,
      creadoPor: c.creadoPor,
    );

    final contraMovsStock = <MovimientoStock>[];
    final movsStock = _almacen.movimientosStock.values
        .where(
          (m) => m.compraId == id && m.tipo != TipoMovimientoStock.anulacion,
        )
        .toList();
    for (final orig in movsStock) {
      final anulId = _almacen.generarId();
      contraMovsStock.add(
        MovimientoStock(
          id: anulId,
          insumoId: orig.insumoId,
          fecha: DateTime.now(),
          cantidad: -orig.cantidad,
          tipo: TipoMovimientoStock.anulacion,
          compraId: id,
          anulaId: orig.id,
          nota: 'Anulación compra: ${motivo.trim()}',
          creadoPor: uid,
          creadoPorNombre: _almacen.nombreDePerfil(uid),
        ),
      );
    }

    final origCaja = _almacen.movimientosCaja.values.firstWhere(
      (m) => m.compraId == id && m.concepto != ConceptoCaja.anulacion,
      orElse: () => MovimientoCaja(
        id: _almacen.generarId(),
        fecha: DateTime.now(),
        tipo: TipoMovimientoCaja.egreso,
        monto: Dinero.cero,
        medioPago: c.medioPago,
        concepto: ConceptoCaja.compra,
      ),
    );

    final contraCaja = MovimientoCaja(
      id: _almacen.generarId(),
      fecha: DateTime.now(),
      tipo: TipoMovimientoCaja.ingreso,
      monto: origCaja.monto,
      medioPago: origCaja.medioPago,
      concepto: ConceptoCaja.anulacion,
      descripcion: 'Anulación compra (${motivo.trim()})',
      compraId: id,
      anulaId: origCaja.id,
      creadoPor: uid,
      creadoPorNombre: _almacen.nombreDePerfil(uid),
    );

    await _almacen.persistirAnulacionCompra(
      compraAnulada,
      contraMovsStock,
      contraCaja,
    );
  }
}

final comprasRepositorioProvider = Provider<ComprasRepositorio>((ref) {
  return _ComprasRepositorioLocal(ref.watch(almacenLocalProvider));
});

final comprasProvider = StreamProvider.autoDispose
    .family<List<CompraResumen>, FiltroCompras>((ref, filtro) {
      return ref.watch(comprasRepositorioProvider).observarResumenes(filtro);
    });

final compraDetalleProvider = StreamProvider.autoDispose
    .family<CompraDetalle?, String>((ref, id) {
      return ref.watch(comprasRepositorioProvider).observarDetalle(id);
    });
