import 'package:flutter/material.dart';

/// Color semántico que los widgets traducen al `ColorScheme` del tema.
/// Prohibido usar `Colors.xxx` directamente en las pantallas.
enum ColorEstado { neutro, info, exito, advertencia, peligro }

enum MedioPago {
  efectivo('efectivo', 'Efectivo', Icons.payments_outlined),
  transferencia(
    'transferencia',
    'Transferencia',
    Icons.account_balance_outlined,
  ),
  mercadoPago('mercado_pago', 'Mercado Pago', Icons.qr_code_2_outlined);

  const MedioPago(this.valor, this.etiqueta, this.icono);
  final String valor;
  final String etiqueta;
  final IconData icono;

  static MedioPago desdeValor(String v) => MedioPago.values.firstWhere(
    (e) => e.valor == v,
    orElse: () => MedioPago.efectivo,
  );
}

enum EstadoPedido {
  presupuesto('presupuesto', 'Presupuesto', ColorEstado.neutro),
  confirmado('confirmado', 'Confirmado', ColorEstado.info),
  enProduccion('en_produccion', 'En producción', ColorEstado.advertencia),
  listo('listo', 'Listo', ColorEstado.exito),
  entregado('entregado', 'Entregado', ColorEstado.exito),
  cancelado('cancelado', 'Cancelado', ColorEstado.peligro);

  const EstadoPedido(this.valor, this.etiqueta, this.color);
  final String valor;
  final String etiqueta;
  final ColorEstado color;

  bool get esFinal =>
      this == EstadoPedido.entregado || this == EstadoPedido.cancelado;

  bool get esActivo => !esFinal && this != EstadoPedido.presupuesto;

  List<EstadoPedido> get siguientes {
    switch (this) {
      case EstadoPedido.presupuesto:
        return const [EstadoPedido.confirmado, EstadoPedido.cancelado];
      case EstadoPedido.confirmado:
        return const [
          EstadoPedido.enProduccion,
          EstadoPedido.listo,
          EstadoPedido.cancelado,
        ];
      case EstadoPedido.enProduccion:
        return const [EstadoPedido.listo, EstadoPedido.cancelado];
      case EstadoPedido.listo:
        return const [EstadoPedido.entregado, EstadoPedido.cancelado];
      case EstadoPedido.entregado:
      case EstadoPedido.cancelado:
        return const [];
    }
  }

  static EstadoPedido desdeValor(String v) => EstadoPedido.values.firstWhere(
    (e) => e.valor == v,
    orElse: () => EstadoPedido.confirmado,
  );
}

enum TipoEntrega {
  retira('retira', 'Retira en el local'),
  envio('envio', 'Envío');

  const TipoEntrega(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static TipoEntrega desdeValor(String v) => TipoEntrega.values.firstWhere(
    (e) => e.valor == v,
    orElse: () => TipoEntrega.retira,
  );
}

enum CategoriaProducto {
  torta('torta', 'Torta'),
  tarta('tarta', 'Tarta'),
  mesaDulce('mesa_dulce', 'Mesa dulce'),
  otro('otro', 'Otro');

  const CategoriaProducto(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static CategoriaProducto desdeValor(String v) => CategoriaProducto.values
      .firstWhere((e) => e.valor == v, orElse: () => CategoriaProducto.otro);
}

enum EstadoDocumento {
  registrado('registrado', 'Registrado'),
  anulado('anulado', 'Anulado');

  const EstadoDocumento(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static EstadoDocumento desdeValor(String v) =>
      EstadoDocumento.values.firstWhere(
        (e) => e.valor == v,
        orElse: () => EstadoDocumento.registrado,
      );
}

enum TipoMovimientoStock {
  inicial('inicial', 'Stock inicial'),
  compra('compra', 'Compra'),
  produccion('produccion', 'Producción'),
  ajuste('ajuste', 'Ajuste por conteo'),
  merma('merma', 'Merma / pérdida'),
  anulacion('anulacion', 'Anulación');

  const TipoMovimientoStock(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static TipoMovimientoStock desdeValor(String v) =>
      TipoMovimientoStock.values.firstWhere(
        (e) => e.valor == v,
        orElse: () => TipoMovimientoStock.ajuste,
      );
}

enum TipoMovimientoCaja {
  ingreso('ingreso', 'Ingreso'),
  egreso('egreso', 'Egreso');

  const TipoMovimientoCaja(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static TipoMovimientoCaja desdeValor(String v) =>
      TipoMovimientoCaja.values.firstWhere(
        (e) => e.valor == v,
        orElse: () => TipoMovimientoCaja.ingreso,
      );
}

enum ConceptoCaja {
  sena('sena', 'Seña'),
  pagoPedido('pago_pedido', 'Pago de pedido'),
  compra('compra', 'Compra'),
  gasto('gasto', 'Gasto'),
  otroIngreso('otro_ingreso', 'Otro ingreso'),
  otroEgreso('otro_egreso', 'Otro egreso'),
  anulacion('anulacion', 'Anulación');

  const ConceptoCaja(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  bool get esManual =>
      this == ConceptoCaja.otroIngreso || this == ConceptoCaja.otroEgreso;

  static ConceptoCaja desdeValor(String v) => ConceptoCaja.values.firstWhere(
    (e) => e.valor == v,
    orElse: () => ConceptoCaja.otroIngreso,
  );
}

enum TipoTarea {
  compra('compra', 'Compra', Icons.shopping_cart_outlined),
  produccion('produccion', 'Producción', Icons.bakery_dining_outlined),
  stock('stock', 'Control de stock', Icons.inventory_2_outlined),
  gasto('gasto', 'Gasto / pago', Icons.receipt_outlined),
  pedido('pedido', 'Pedido', Icons.cake_outlined),
  limpieza('limpieza', 'Limpieza y orden', Icons.cleaning_services_outlined),
  otro('otro', 'Otro', Icons.task_alt_outlined);

  const TipoTarea(this.valor, this.etiqueta, this.icono);
  final String valor;
  final String etiqueta;
  final IconData icono;

  static TipoTarea desdeValor(String v) => TipoTarea.values.firstWhere(
    (e) => e.valor == v,
    orElse: () => TipoTarea.otro,
  );
}

enum PrioridadTarea {
  baja('baja', 'Baja', ColorEstado.neutro),
  media('media', 'Media', ColorEstado.info),
  alta('alta', 'Alta', ColorEstado.peligro);

  const PrioridadTarea(this.valor, this.etiqueta, this.color);
  final String valor;
  final String etiqueta;
  final ColorEstado color;

  static PrioridadTarea desdeValor(String v) => PrioridadTarea.values
      .firstWhere((e) => e.valor == v, orElse: () => PrioridadTarea.media);
}

enum EstadoTarea {
  pendiente('pendiente', 'Pendiente'),
  enProgreso('en_progreso', 'En progreso'),
  hecha('hecha', 'Hecha'),
  cancelada('cancelada', 'Cancelada');

  const EstadoTarea(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  bool get esFinal =>
      this == EstadoTarea.hecha || this == EstadoTarea.cancelada;

  static EstadoTarea desdeValor(String v) => EstadoTarea.values.firstWhere(
    (e) => e.valor == v,
    orElse: () => EstadoTarea.pendiente,
  );
}

enum TipoAlerta {
  cumpleanos('cumpleanos', 'Cumpleaños', Icons.cake_outlined),
  stockBajo('stock_bajo', 'Faltante de stock', Icons.warning_amber_rounded),
  entregaProxima('entrega_proxima', 'Entrega próxima', Icons.event_outlined),
  tareaAsignada(
    'tarea_asignada',
    'Tarea asignada',
    Icons.assignment_ind_outlined,
  ),
  tareaVencida('tarea_vencida', 'Tarea vencida', Icons.alarm_outlined);

  const TipoAlerta(this.valor, this.etiqueta, this.icono);
  final String valor;
  final String etiqueta;
  final IconData icono;

  static TipoAlerta desdeValor(String v) => TipoAlerta.values.firstWhere(
    (e) => e.valor == v,
    orElse: () => TipoAlerta.tareaAsignada,
  );
}

enum HabitualModo {
  auto('auto', 'Automático'),
  si('si', 'Siempre habitual'),
  no('no', 'Nunca habitual');

  const HabitualModo(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static HabitualModo desdeValor(String v) => HabitualModo.values.firstWhere(
    (e) => e.valor == v,
    orElse: () => HabitualModo.auto,
  );
}

enum Rol {
  jefe('jefe', 'Jefe'),
  empleado('empleado', 'Empleado');

  const Rol(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static Rol desdeValor(String v) =>
      Rol.values.firstWhere((e) => e.valor == v, orElse: () => Rol.empleado);
}

enum Modulo {
  clientes('clientes', 'Clientes', Icons.people_outline),
  pedidos('pedidos', 'Pedidos', Icons.receipt_long_outlined),
  catalogo('catalogo', 'Catálogo', Icons.cake_outlined),
  stock('stock', 'Stock e insumos', Icons.inventory_2_outlined),
  compras('compras', 'Compras y proveedores', Icons.shopping_cart_outlined),
  produccion('produccion', 'Producción', Icons.bakery_dining_outlined),
  gastos('gastos', 'Gastos', Icons.receipt_outlined),
  caja('caja', 'Caja', Icons.point_of_sale_outlined),
  reportes('reportes', 'Reportes', Icons.bar_chart_outlined);

  const Modulo(this.valor, this.etiqueta, this.icono);
  final String valor;
  final String etiqueta;
  final IconData icono;

  static Modulo desdeValor(String v) => Modulo.values.firstWhere(
    (e) => e.valor == v,
    orElse: () => Modulo.pedidos,
  );
}

enum NivelPermiso {
  ninguno('ninguno', 'Sin acceso', 'No ve este módulo', 0),
  ver('ver', 'Ver', 'Solo consulta', 1),
  cargar('cargar', 'Cargar', 'Ve y registra nuevos datos', 2),
  editar('editar', 'Editar', 'Control total (editar y anular)', 3);

  const NivelPermiso(this.valor, this.etiqueta, this.descripcion, this.orden);
  final String valor;
  final String etiqueta;
  final String descripcion;
  final int orden;

  bool alcanza(NivelPermiso minimo) => orden >= minimo.orden;

  static NivelPermiso desdeValor(String v) => NivelPermiso.values.firstWhere(
    (e) => e.valor == v,
    orElse: () => NivelPermiso.ninguno,
  );
}

enum AlcanceAvisoCumple {
  todos('todos', 'Todos los clientes'),
  habituales('habituales', 'Solo clientes habituales');

  const AlcanceAvisoCumple(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static AlcanceAvisoCumple desdeValor(String v) => AlcanceAvisoCumple.values
      .firstWhere((e) => e.valor == v, orElse: () => AlcanceAvisoCumple.todos);
}
