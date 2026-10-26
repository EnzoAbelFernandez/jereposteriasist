import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/data/modelos/caja_modelos.dart';
import 'package:jereposteria/data/modelos/clientes_modelos.dart';

@immutable
class Pedido {
  const Pedido({
    required this.id,
    this.numero,
    required this.clienteId,
    required this.fechaEntrega,
    this.tipoEntrega = TipoEntrega.retira,
    this.direccionEntrega,
    this.estado = EstadoPedido.confirmado,
    this.descuento = Dinero.cero,
    this.motivoDescuento,
    this.notas,
    this.entregadoEn,
    this.canceladoEn,
    this.motivoCancelacion,
    required this.creadoEn,
  });

  final String id;
  final int? numero;
  final String clienteId;
  final DateTime fechaEntrega;
  final TipoEntrega tipoEntrega;
  final String? direccionEntrega;
  final EstadoPedido estado;
  final Dinero descuento;
  final String? motivoDescuento;
  final String? notas;
  final DateTime? entregadoEn;
  final DateTime? canceladoEn;
  final String? motivoCancelacion;
  final DateTime creadoEn;

  String get numeroTexto => numero != null ? '#$numero' : 'Nº pendiente';
}

@immutable
class PedidoItem {
  const PedidoItem({
    required this.id,
    required this.pedidoId,
    this.productoId,
    required this.descripcion,
    this.cantidad = 1,
    required this.precioUnitario,
    this.notas,
    this.orden = 0,
  });

  final String id;
  final String pedidoId;
  final String? productoId;
  final String descripcion;
  final int cantidad;
  final Dinero precioUnitario;
  final String? notas;
  final int orden;

  Dinero get subtotal => precioUnitario.por(cantidad);
}

@immutable
class PedidoResumen {
  const PedidoResumen({
    required this.pedido,
    required this.clienteNombre,
    this.clienteTelefono,
    required this.total,
    required this.pagado,
    required this.cantidadItems,
    this.primerItem,
  });

  final Pedido pedido;
  final String clienteNombre;
  final String? clienteTelefono;
  final Dinero total;
  final Dinero pagado;
  final int cantidadItems;
  final String? primerItem;

  Dinero get saldo {
    final s = total - pagado;
    return s.esNegativo ? Dinero.cero : s;
  }

  bool get pagadoCompleto => saldo.esCero;
}

@immutable
class PedidoDetalle {
  const PedidoDetalle({
    required this.pedido,
    required this.cliente,
    required this.items,
    required this.pagos,
  });

  final Pedido pedido;
  final Cliente cliente;
  final List<PedidoItem> items;
  final List<MovimientoCaja> pagos;

  Dinero get subtotal => items.fold(Dinero.cero, (acc, i) => acc + i.subtotal);

  Dinero get total {
    final t = subtotal - pedido.descuento;
    return t.esNegativo ? Dinero.cero : t;
  }

  Dinero get pagado =>
      pagos.fold(Dinero.cero, (acc, p) => acc + p.montoConSigno);

  Dinero get saldo {
    final s = total - pagado;
    return s.esNegativo ? Dinero.cero : s;
  }
}

class PedidoItemDatos {
  PedidoItemDatos({
    this.id,
    this.productoId,
    required this.descripcion,
    this.cantidad = 1,
    required this.precioUnitario,
    this.notas,
  });

  final String? id;
  final String? productoId;
  final String descripcion;
  final int cantidad;
  final Dinero precioUnitario;
  final String? notas;

  Dinero get subtotal => precioUnitario.por(cantidad);
}

class PedidoDatos {
  PedidoDatos({
    required this.clienteId,
    required this.fechaEntrega,
    this.tipoEntrega = TipoEntrega.retira,
    this.direccionEntrega,
    this.estadoInicial = EstadoPedido.confirmado,
    this.descuento = Dinero.cero,
    this.motivoDescuento,
    this.notas,
    required this.items,
  });

  factory PedidoDatos.desde(PedidoDetalle d) => PedidoDatos(
    clienteId: d.pedido.clienteId,
    fechaEntrega: d.pedido.fechaEntrega,
    tipoEntrega: d.pedido.tipoEntrega,
    direccionEntrega: d.pedido.direccionEntrega,
    estadoInicial: d.pedido.estado,
    descuento: d.pedido.descuento,
    motivoDescuento: d.pedido.motivoDescuento,
    notas: d.pedido.notas,
    items: d.items
        .map(
          (i) => PedidoItemDatos(
            id: i.id,
            productoId: i.productoId,
            descripcion: i.descripcion,
            cantidad: i.cantidad,
            precioUnitario: i.precioUnitario,
            notas: i.notas,
          ),
        )
        .toList(),
  );

  final String clienteId;
  final DateTime fechaEntrega;
  final TipoEntrega tipoEntrega;
  final String? direccionEntrega;
  final EstadoPedido estadoInicial;
  final Dinero descuento;
  final String? motivoDescuento;
  final String? notas;
  final List<PedidoItemDatos> items;

  Dinero get subtotal => items.fold(Dinero.cero, (acc, i) => acc + i.subtotal);

  Dinero get total {
    final t = subtotal - descuento;
    return t.esNegativo ? Dinero.cero : t;
  }
}

class PagoDatos {
  PagoDatos({required this.monto, required this.medioPago, this.fecha});

  final Dinero monto;
  final MedioPago medioPago;
  final DateTime? fecha;
}

@immutable
class FiltroPedidos {
  const FiltroPedidos({
    this.estados,
    this.desde,
    this.hasta,
    this.busqueda = '',
  });

  static const FiltroPedidos activos = FiltroPedidos(
    estados: {
      EstadoPedido.presupuesto,
      EstadoPedido.confirmado,
      EstadoPedido.enProduccion,
      EstadoPedido.listo,
    },
  );

  static const FiltroPedidos todos = FiltroPedidos();

  final Set<EstadoPedido>? estados;
  final DateTime? desde;
  final DateTime? hasta;
  final String busqueda;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiltroPedidos &&
          setEquals(other.estados, estados) &&
          other.desde == desde &&
          other.hasta == hasta &&
          other.busqueda == busqueda);

  @override
  int get hashCode => Object.hash(
    estados == null ? null : Object.hashAllUnordered(estados!),
    desde,
    hasta,
    busqueda,
  );
}
