import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/caja_modelos.dart';
import 'package:jereposteria/data/modelos/clientes_modelos.dart';
import 'package:jereposteria/data/modelos/pedidos_modelos.dart';

abstract class PedidosRepositorio {
  Stream<List<PedidoResumen>> observarResumenes(FiltroPedidos filtro);
  Stream<List<PedidoResumen>> observarPorCliente(String clienteId);
  Stream<PedidoDetalle?> observarDetalle(String id);
  Future<String> crear(PedidoDatos datos, {PagoDatos? sena});
  Future<void> actualizar(String id, PedidoDatos datos);
  Future<void> cambiarEstado(
    String id,
    EstadoPedido nuevo, {
    String? motivoCancelacion,
  });
  Future<void> registrarPago(
    String pedidoId,
    PagoDatos pago, {
    bool esSena = false,
  });
  Future<void> anularPago(String movimientoCajaId);
}

class _PedidosRepositorioLocal implements PedidosRepositorio {
  _PedidosRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;
  int _secuenciaLocal = 1;

  String? _limpiar(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  PedidoResumen _armarResumen(Pedido p) {
    final cliente = _almacen.clientes[p.clienteId];
    final items = _almacen.pedidoItems[p.id] ?? const [];
    final subtotal = items.fold(Dinero.cero, (acc, i) => acc + i.subtotal);
    final totalBruto = subtotal - p.descuento;
    final total = totalBruto.esNegativo ? Dinero.cero : totalBruto;

    var pagado = Dinero.cero;
    for (final m in _almacen.movimientosCaja.values) {
      if (m.pedidoId == p.id) {
        pagado = pagado + m.montoConSigno;
      }
    }

    return PedidoResumen(
      pedido: p,
      clienteNombre: cliente?.nombre ?? 'Cliente',
      clienteTelefono: cliente?.telefono,
      total: total,
      pagado: pagado,
      cantidadItems: items.length,
      primerItem: items.isEmpty ? null : items.first.descripcion,
    );
  }

  @override
  Stream<List<PedidoResumen>> observarResumenes(FiltroPedidos filtro) {
    final q = filtro.busqueda.trim().toLowerCase();
    return _almacen.observar(() {
      final res = <PedidoResumen>[];
      for (final p in _almacen.pedidos.values) {
        if (filtro.estados != null &&
            filtro.estados!.isNotEmpty &&
            !filtro.estados!.contains(p.estado)) {
          continue;
        }
        if (filtro.desde != null && p.fechaEntrega.isBefore(filtro.desde!)) {
          continue;
        }
        if (filtro.hasta != null && p.fechaEntrega.isAfter(filtro.hasta!)) {
          continue;
        }
        final r = _armarResumen(p);
        if (q.isNotEmpty) {
          final coincideCliente = r.clienteNombre.toLowerCase().contains(q);
          final coincideNumero =
              p.numero?.toString().contains(q) == true ||
              p.numeroTexto.toLowerCase().contains(q);
          if (!coincideCliente && !coincideNumero) continue;
        }
        res.add(r);
      }
      res.sort(
        (a, b) => a.pedido.fechaEntrega.compareTo(b.pedido.fechaEntrega),
      );
      return res;
    });
  }

  @override
  Stream<List<PedidoResumen>> observarPorCliente(String clienteId) {
    return _almacen.observar(() {
      final res =
          _almacen.pedidos.values
              .where((p) => p.clienteId == clienteId)
              .map(_armarResumen)
              .toList()
            ..sort(
              (a, b) => b.pedido.fechaEntrega.compareTo(a.pedido.fechaEntrega),
            );
      return res;
    });
  }

  @override
  Stream<PedidoDetalle?> observarDetalle(String id) {
    return _almacen.observar(() {
      final p = _almacen.pedidos[id];
      if (p == null) return null;
      final cliente =
          _almacen.clientes[p.clienteId] ??
          Cliente(id: p.clienteId, nombre: 'Cliente', creadoEn: p.creadoEn);
      final items = List<PedidoItem>.of(_almacen.pedidoItems[id] ?? const []);
      final idsAnulados = _almacen.movimientosCaja.values
          .where((m) => m.anulaId != null)
          .map((m) => m.anulaId!)
          .toSet();
      final pagos =
          _almacen.movimientosCaja.values
              .where((m) => m.pedidoId == id)
              .map(
                (m) => MovimientoCaja(
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
              )
              .toList()
            ..sort((a, b) => a.fecha.compareTo(b.fecha));
      return PedidoDetalle(
        pedido: p,
        cliente: cliente,
        items: items,
        pagos: pagos,
      );
    });
  }

  void _validarDatos(PedidoDatos d, {required bool esNuevo}) {
    if (d.clienteId.trim().isEmpty ||
        !_almacen.clientes.containsKey(d.clienteId)) {
      throw const ErrorDeNegocio('Elegí un cliente válido.');
    }
    if (d.items.isEmpty) {
      throw const ErrorDeNegocio('Agregá al menos un ítem al pedido.');
    }
    for (final item in d.items) {
      if (item.descripcion.trim().isEmpty) {
        throw const ErrorDeNegocio('Todos los ítems deben tener descripción.');
      }
      if (item.cantidad <= 0) {
        throw const ErrorDeNegocio(
          'La cantidad de cada ítem debe ser mayor a cero.',
        );
      }
      if (item.precioUnitario.esNegativo) {
        throw const ErrorDeNegocio('El precio no puede ser negativo.');
      }
    }
    if (d.descuento.esNegativo) {
      throw const ErrorDeNegocio('El descuento no puede ser negativo.');
    }
    if (d.tipoEntrega == TipoEntrega.envio &&
        (d.direccionEntrega == null || d.direccionEntrega!.trim().isEmpty)) {
      throw const ErrorDeNegocio('Indicá la dirección de entrega.');
    }
    if (esNuevo &&
        d.estadoInicial != EstadoPedido.presupuesto &&
        d.estadoInicial != EstadoPedido.confirmado) {
      throw const ErrorDeNegocio(
        'El estado inicial debe ser Presupuesto o Confirmado.',
      );
    }
  }

  @override
  Future<String> crear(PedidoDatos datos, {PagoDatos? sena}) async {
    _validarDatos(datos, esNuevo: true);
    if (sena != null) {
      if (!sena.monto.esPositivo) {
        throw const ErrorDeNegocio('La seña debe ser mayor a cero.');
      }
      if (sena.monto > datos.total) {
        throw const ErrorDeNegocio(
          'La seña no puede superar el total del pedido.',
        );
      }
    }

    final id = _almacen.generarId();
    final numero = _secuenciaLocal++;
    _almacen.pedidos[id] = Pedido(
      id: id,
      numero: numero,
      clienteId: datos.clienteId,
      fechaEntrega: datos.fechaEntrega,
      tipoEntrega: datos.tipoEntrega,
      direccionEntrega: _limpiar(datos.direccionEntrega),
      estado: datos.estadoInicial,
      descuento: datos.descuento,
      motivoDescuento: _limpiar(datos.motivoDescuento),
      notas: _limpiar(datos.notas),
      creadoEn: DateTime.now(),
    );

    final listaItems = <PedidoItem>[];
    for (var idx = 0; idx < datos.items.length; idx++) {
      final i = datos.items[idx];
      listaItems.add(
        PedidoItem(
          id: i.id ?? _almacen.generarId(),
          pedidoId: id,
          productoId: i.productoId,
          descripcion: i.descripcion.trim(),
          cantidad: i.cantidad,
          precioUnitario: i.precioUnitario,
          notas: _limpiar(i.notas),
          orden: idx,
        ),
      );
    }
    _almacen.pedidoItems[id] = listaItems;

    if (sena != null) {
      final movId = _almacen.generarId();
      _almacen.movimientosCaja[movId] = MovimientoCaja(
        id: movId,
        fecha: sena.fecha ?? DateTime.now(),
        tipo: TipoMovimientoCaja.ingreso,
        monto: sena.monto,
        medioPago: sena.medioPago,
        concepto: ConceptoCaja.sena,
        descripcion: 'Seña pedido #$numero',
        pedidoId: id,
        creadoPor: _almacen.usuarioActualId,
        creadoPorNombre: _almacen.nombreDePerfil(_almacen.usuarioActualId),
      );
    }

    _almacen.notificar();
    return id;
  }

  @override
  Future<void> actualizar(String id, PedidoDatos datos) async {
    final actual = _almacen.pedidos[id];
    if (actual == null) {
      throw const ErrorDeNegocio('El pedido no existe.');
    }
    if (actual.estado.esFinal) {
      throw const ErrorDeNegocio(
        'No se puede editar un pedido entregado o cancelado.',
      );
    }
    _validarDatos(datos, esNuevo: false);

    _almacen.pedidos[id] = Pedido(
      id: id,
      numero: actual.numero,
      clienteId: datos.clienteId,
      fechaEntrega: datos.fechaEntrega,
      tipoEntrega: datos.tipoEntrega,
      direccionEntrega: _limpiar(datos.direccionEntrega),
      estado: actual.estado,
      descuento: datos.descuento,
      motivoDescuento: _limpiar(datos.motivoDescuento),
      notas: _limpiar(datos.notas),
      entregadoEn: actual.entregadoEn,
      canceladoEn: actual.canceladoEn,
      motivoCancelacion: actual.motivoCancelacion,
      creadoEn: actual.creadoEn,
    );

    final listaItems = <PedidoItem>[];
    for (var idx = 0; idx < datos.items.length; idx++) {
      final i = datos.items[idx];
      listaItems.add(
        PedidoItem(
          id: i.id ?? _almacen.generarId(),
          pedidoId: id,
          productoId: i.productoId,
          descripcion: i.descripcion.trim(),
          cantidad: i.cantidad,
          precioUnitario: i.precioUnitario,
          notas: _limpiar(i.notas),
          orden: idx,
        ),
      );
    }
    _almacen.pedidoItems[id] = listaItems;
    _almacen.recalcularHabitual(datos.clienteId);
    if (actual.clienteId != datos.clienteId) {
      _almacen.recalcularHabitual(actual.clienteId);
    }
    _almacen.notificar();
  }

  @override
  Future<void> cambiarEstado(
    String id,
    EstadoPedido nuevo, {
    String? motivoCancelacion,
  }) async {
    final actual = _almacen.pedidos[id];
    if (actual == null) {
      throw const ErrorDeNegocio('El pedido no existe.');
    }
    if (!actual.estado.siguientes.contains(nuevo)) {
      throw ErrorDeNegocio(
        'No se puede pasar de ${actual.estado.etiqueta} a ${nuevo.etiqueta}.',
      );
    }
    if (nuevo == EstadoPedido.cancelado &&
        (motivoCancelacion == null || motivoCancelacion.trim().isEmpty)) {
      throw const ErrorDeNegocio('Indicá el motivo de la cancelación.');
    }

    _almacen.pedidos[id] = Pedido(
      id: actual.id,
      numero: actual.numero,
      clienteId: actual.clienteId,
      fechaEntrega: actual.fechaEntrega,
      tipoEntrega: actual.tipoEntrega,
      direccionEntrega: actual.direccionEntrega,
      estado: nuevo,
      descuento: actual.descuento,
      motivoDescuento: actual.motivoDescuento,
      notas: actual.notas,
      entregadoEn: nuevo == EstadoPedido.entregado
          ? DateTime.now()
          : actual.entregadoEn,
      canceladoEn: nuevo == EstadoPedido.cancelado
          ? DateTime.now()
          : actual.canceladoEn,
      motivoCancelacion: nuevo == EstadoPedido.cancelado
          ? motivoCancelacion?.trim()
          : actual.motivoCancelacion,
      creadoEn: actual.creadoEn,
    );
    _almacen.recalcularHabitual(actual.clienteId);
    _almacen.notificar();
  }

  @override
  Future<void> registrarPago(
    String pedidoId,
    PagoDatos pago, {
    bool esSena = false,
  }) async {
    final p = _almacen.pedidos[pedidoId];
    if (p == null) {
      throw const ErrorDeNegocio('El pedido no existe.');
    }
    if (p.estado == EstadoPedido.cancelado) {
      throw const ErrorDeNegocio(
        'No se pueden registrar pagos en un pedido cancelado.',
      );
    }
    if (!pago.monto.esPositivo) {
      throw const ErrorDeNegocio('El monto debe ser mayor a cero.');
    }
    final resumen = _armarResumen(p);
    if (pago.monto > resumen.saldo) {
      throw const ErrorDeNegocio(
        'El monto supera el saldo pendiente del pedido.',
      );
    }

    final movId = _almacen.generarId();
    _almacen.movimientosCaja[movId] = MovimientoCaja(
      id: movId,
      fecha: pago.fecha ?? DateTime.now(),
      tipo: TipoMovimientoCaja.ingreso,
      monto: pago.monto,
      medioPago: pago.medioPago,
      concepto: esSena ? ConceptoCaja.sena : ConceptoCaja.pagoPedido,
      descripcion: '${esSena ? 'Seña' : 'Pago'} pedido ${p.numeroTexto}',
      pedidoId: pedidoId,
      creadoPor: _almacen.usuarioActualId,
      creadoPorNombre: _almacen.nombreDePerfil(_almacen.usuarioActualId),
    );
    _almacen.notificar();
  }

  @override
  Future<void> anularPago(String movimientoCajaId) async {
    final orig = _almacen.movimientosCaja[movimientoCajaId];
    if (orig == null || orig.pedidoId == null) {
      throw const ErrorDeNegocio('El pago no existe.');
    }
    final yaAnulado = _almacen.movimientosCaja.values.any(
      (m) => m.anulaId == movimientoCajaId,
    );
    if (yaAnulado || orig.concepto == ConceptoCaja.anulacion) {
      throw const ErrorDeNegocio('Este pago ya fue anulado.');
    }
    final id = _almacen.generarId();
    _almacen.movimientosCaja[id] = MovimientoCaja(
      id: id,
      fecha: DateTime.now(),
      tipo: orig.tipo == TipoMovimientoCaja.ingreso
          ? TipoMovimientoCaja.egreso
          : TipoMovimientoCaja.ingreso,
      monto: orig.monto,
      medioPago: orig.medioPago,
      concepto: ConceptoCaja.anulacion,
      descripcion: 'Anulación de ${orig.descripcionTexto}',
      pedidoId: orig.pedidoId,
      anulaId: orig.id,
      creadoPor: _almacen.usuarioActualId,
      creadoPorNombre: _almacen.nombreDePerfil(_almacen.usuarioActualId),
    );
    _almacen.notificar();
  }
}

final pedidosRepositorioProvider = Provider<PedidosRepositorio>((ref) {
  return _PedidosRepositorioLocal(ref.watch(almacenLocalProvider));
});

final pedidosProvider = StreamProvider.autoDispose
    .family<List<PedidoResumen>, FiltroPedidos>((ref, filtro) {
      return ref.watch(pedidosRepositorioProvider).observarResumenes(filtro);
    });

final pedidosPorClienteProvider = StreamProvider.autoDispose
    .family<List<PedidoResumen>, String>((ref, clienteId) {
      return ref
          .watch(pedidosRepositorioProvider)
          .observarPorCliente(clienteId);
    });

final pedidoDetalleProvider = StreamProvider.autoDispose
    .family<PedidoDetalle?, String>((ref, id) {
      return ref.watch(pedidosRepositorioProvider).observarDetalle(id);
    });
