import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class _ItemFormulario {
  _ItemFormulario({
    this.id,
    this.productoId,
    this.descripcion = '',
    this.cantidad = 1,
    Dinero? precioUnitario,
    this.notas,
  }) : precioUnitario = precioUnitario ?? Dinero.cero;

  final String? id;
  String? productoId;
  String descripcion;
  int cantidad;
  Dinero precioUnitario;
  String? notas;
  int version = 0;
  final UniqueKey key = UniqueKey();

  Dinero get subtotal => precioUnitario.por(cantidad);
}

class PedidoFormularioPantalla extends ConsumerStatefulWidget {
  const PedidoFormularioPantalla({super.key, this.id, this.clienteIdInicial});

  final String? id;
  final String? clienteIdInicial;

  bool get esEdicion => id != null;

  @override
  ConsumerState<PedidoFormularioPantalla> createState() =>
      _PedidoFormularioPantallaState();
}

class _PedidoFormularioPantallaState
    extends ConsumerState<PedidoFormularioPantalla> {
  final _formKey = GlobalKey<FormState>();
  bool _inicializado = false;

  String? _clienteId;
  DateTime? _fechaEntrega;
  TipoEntrega _tipoEntrega = TipoEntrega.retira;
  String _direccionEntrega = '';
  EstadoPedido _estadoInicial = EstadoPedido.confirmado;
  Dinero _descuento = Dinero.cero;
  String _motivoDescuento = '';
  String _notas = '';

  // Seña inicial (solo al crear)
  bool _cobraSena = false;
  Dinero? _montoSena;
  MedioPago _medioPagoSena = MedioPago.efectivo;

  // Ítems dinámicos (mínimo 1)
  List<_ItemFormulario> _items = [_ItemFormulario()];

  @override
  void initState() {
    super.initState();
    _clienteId = widget.clienteIdInicial;
  }

  void _precargar(PedidoDetalle d) {
    if (_inicializado) return;
    _inicializado = true;
    _clienteId = d.pedido.clienteId;
    _fechaEntrega = d.pedido.fechaEntrega;
    _tipoEntrega = d.pedido.tipoEntrega;
    _direccionEntrega = d.pedido.direccionEntrega ?? '';
    _estadoInicial = d.pedido.estado;
    _descuento = d.pedido.descuento;
    _motivoDescuento = d.pedido.motivoDescuento ?? '';
    _notas = d.pedido.notas ?? '';
    _items = d.items
        .map(
          (i) => _ItemFormulario(
            id: i.id,
            productoId: i.productoId,
            descripcion: i.descripcion,
            cantidad: i.cantidad,
            precioUnitario: i.precioUnitario,
            notas: i.notas,
          ),
        )
        .toList();
    if (_items.isEmpty) {
      _items.add(_ItemFormulario());
    }
  }

  Dinero get _subtotal =>
      _items.fold(Dinero.cero, (acc, i) => acc + i.subtotal);

  Dinero get _total {
    final t = _subtotal - _descuento;
    return t.esNegativo ? Dinero.cero : t;
  }

  void _onProductoCambiado(_ItemFormulario item, Producto? producto) {
    setState(() {
      item.productoId = producto?.id;
      if (producto != null) {
        var modificado = false;
        if (item.descripcion.trim().isEmpty) {
          item.descripcion = producto.nombre;
          modificado = true;
        }
        if (item.precioUnitario.esCero && producto.precioBase != null) {
          item.precioUnitario = producto.precioBase!;
          modificado = true;
        }
        if (modificado) {
          item.version++;
        }
      }
    });
  }

  void _agregarItem() {
    setState(() {
      _items.add(_ItemFormulario());
    });
  }

  void _eliminarItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clienteId == null || _clienteId!.trim().isEmpty) {
      throw const ErrorDeNegocio('Elegí un cliente válido.');
    }
    if (_fechaEntrega == null) {
      throw const ErrorDeNegocio('Elegí una fecha de entrega.');
    }
    if (_items.isEmpty) {
      throw const ErrorDeNegocio('Agregá al menos un ítem al pedido.');
    }

    final total = _total;

    PagoDatos? sena;
    if (!widget.esEdicion && _cobraSena) {
      final montoSena = _montoSena;
      if (montoSena == null || !montoSena.esPositivo) {
        throw const ErrorDeNegocio('La seña debe ser mayor a cero.');
      }
      if (montoSena > total) {
        throw const ErrorDeNegocio(
          'La seña no puede superar el total del pedido.',
        );
      }
      sena = PagoDatos(
        monto: montoSena,
        medioPago: _medioPagoSena,
        fecha: DateTime.now(),
      );
    }

    final datos = PedidoDatos(
      clienteId: _clienteId!,
      fechaEntrega: _fechaEntrega!,
      tipoEntrega: _tipoEntrega,
      direccionEntrega: _tipoEntrega == TipoEntrega.envio
          ? (_direccionEntrega.trim().isEmpty ? null : _direccionEntrega.trim())
          : null,
      estadoInicial: _estadoInicial,
      descuento: _descuento,
      motivoDescuento:
          _descuento.esPositivo && _motivoDescuento.trim().isNotEmpty
          ? _motivoDescuento.trim()
          : null,
      notas: _notas.trim().isEmpty ? null : _notas.trim(),
      items: _items
          .map(
            (i) => PedidoItemDatos(
              id: i.id,
              productoId: i.productoId,
              descripcion: i.descripcion.trim(),
              cantidad: i.cantidad,
              precioUnitario: i.precioUnitario,
              notas: (i.notas == null || i.notas!.trim().isEmpty)
                  ? null
                  : i.notas!.trim(),
            ),
          )
          .toList(),
    );

    final repo = ref.read(pedidosRepositorioProvider);
    if (widget.esEdicion) {
      await repo.actualizar(widget.id!, datos);
    } else {
      await repo.crear(datos, sena: sena);
    }

    if (mounted) {
      mostrarExito(context, 'Pedido guardado con éxito.');
      context.pop();
    }
  }

  Widget _construirItemCard(_ItemFormulario item, int index) {
    final tema = Theme.of(context);
    return Card(
      key: item.key,
      margin: EdgeInsets.zero,
      elevation: 0,
      color: tema.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: tema.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Ítem ${index + 1}',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Subtotal: ',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextoDinero(
                        item.subtotal,
                        estilo: tema.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_items.length > 1) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar ítem',
                    onPressed: () => _eliminarItem(index),
                  ),
                ],
              ],
            ),
            Separacion.chica,
            SelectorProducto(
              productoId: item.productoId,
              onChanged: (p) => _onProductoCambiado(item, p),
            ),
            Separacion.chica,
            CampoTexto(
              key: ValueKey('desc_${item.key}_${item.version}'),
              etiqueta: 'Descripción',
              valorInicial: item.descripcion,
              obligatorio: true,
              onChanged: (v) => item.descripcion = v,
            ),
            Separacion.chica,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoEntero(
                    key: ValueKey('cant_${item.key}'),
                    etiqueta: 'Cantidad',
                    valorInicial: item.cantidad,
                    minimo: 1,
                    obligatorio: true,
                    onChanged: (c) => setState(() => item.cantidad = c ?? 1),
                  ),
                ),
                Separacion.chica,
                Expanded(
                  child: CampoDinero(
                    key: ValueKey('precio_${item.key}_${item.version}'),
                    etiqueta: 'Precio unitario',
                    valorInicial: item.precioUnitario,
                    obligatorio: true,
                    permitirCero: true,
                    onChanged: (p) =>
                        setState(() => item.precioUnitario = p ?? Dinero.cero),
                  ),
                ),
              ],
            ),
            Separacion.chica,
            CampoTexto(
              key: ValueKey('notas_${item.key}'),
              etiqueta: 'Notas del ítem (rellenos, dedicatoria...)',
              valorInicial: item.notas,
              onChanged: (v) => item.notas = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirFormulario() {
    final tema = Theme.of(context);
    return FormularioResponsivo(
      formKey: _formKey,
      campos: [
        TarjetaSeccion(
          titulo: 'Cliente y entrega',
          icono: Icons.person_outline,
          children: [
            SelectorCliente(
              clienteId: _clienteId,
              obligatorio: true,
              permitirCrear: true,
              onChanged: (c) => setState(() => _clienteId = c?.id),
            ),
            Separacion.media,
            CampoFecha(
              etiqueta: 'Fecha y hora de entrega',
              valor: _fechaEntrega,
              conHora: true,
              obligatorio: true,
              onChanged: (f) => setState(() => _fechaEntrega = f),
            ),
            Separacion.media,
            SelectorOpcion<TipoEntrega>(
              etiqueta: 'Tipo de entrega',
              opciones: TipoEntrega.values,
              valor: _tipoEntrega,
              etiquetaDe: (t) => t.etiqueta,
              onChanged: (t) {
                if (t != null) setState(() => _tipoEntrega = t);
              },
            ),
            if (_tipoEntrega == TipoEntrega.envio) ...[
              Separacion.media,
              CampoTexto(
                key: const ValueKey('direccion_entrega'),
                etiqueta: 'Dirección de entrega',
                valorInicial: _direccionEntrega,
                obligatorio: true,
                icono: Icons.place_outlined,
                onChanged: (v) => _direccionEntrega = v,
              ),
            ],
            if (!widget.esEdicion) ...[
              Separacion.media,
              SelectorOpcion<EstadoPedido>(
                etiqueta: 'Estado inicial',
                opciones: const [
                  EstadoPedido.confirmado,
                  EstadoPedido.presupuesto,
                ],
                valor: _estadoInicial,
                etiquetaDe: (e) => e.etiqueta,
                onChanged: (e) {
                  if (e != null) setState(() => _estadoInicial = e);
                },
              ),
            ],
          ],
        ),
        TarjetaSeccion(
          titulo: 'Ítems del pedido (${_items.length})',
          icono: Icons.cake_outlined,
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) Separacion.media,
              _construirItemCard(_items[i], i),
            ],
            Separacion.media,
            OutlinedButton.icon(
              onPressed: _agregarItem,
              icon: const Icon(Icons.add),
              label: const Text('Agregar otro ítem'),
            ),
          ],
        ),
        TarjetaSeccion(
          titulo: 'Descuento y totales',
          icono: Icons.receipt_long_outlined,
          children: [
            CampoDinero(
              key: const ValueKey('descuento'),
              etiqueta: 'Descuento (opcional)',
              valorInicial: _descuento,
              permitirCero: true,
              onChanged: (d) => setState(() => _descuento = d ?? Dinero.cero),
            ),
            if (_descuento.esPositivo) ...[
              Separacion.media,
              CampoTexto(
                key: const ValueKey('motivo_descuento'),
                etiqueta: 'Motivo del descuento',
                valorInicial: _motivoDescuento,
                onChanged: (v) => _motivoDescuento = v,
              ),
            ],
            Separacion.media,
            Card(
              elevation: 0,
              color: tema.colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: tema.textTheme.bodyMedium?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextoDinero(_subtotal),
                      ],
                    ),
                    if (_descuento.esPositivo) ...[
                      Separacion.chica,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Descuento',
                            style: tema.textTheme.bodyMedium?.copyWith(
                              color: tema.colorScheme.error,
                            ),
                          ),
                          TextoDinero(-_descuento, colorear: true),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: tema.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextoDinero(
                          _total,
                          estilo: tema.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (!widget.esEdicion)
          TarjetaSeccion(
            titulo: 'Seña inicial (opcional)',
            icono: Icons.payments_outlined,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('¿Cobrar seña inicial ahora?'),
                subtitle: const Text(
                  'Registra el cobro en caja y lo descuenta del saldo',
                ),
                value: _cobraSena,
                onChanged: (v) => setState(() => _cobraSena = v),
              ),
              if (_cobraSena) ...[
                Separacion.media,
                CampoDinero(
                  key: const ValueKey('monto_sena'),
                  etiqueta: 'Monto de la seña',
                  valorInicial: _montoSena,
                  obligatorio: true,
                  onChanged: (m) => setState(() => _montoSena = m),
                ),
                Separacion.media,
                Text(
                  'Medio de pago',
                  style: tema.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Separacion.chica,
                SelectorMedioPago(
                  valor: _medioPagoSena,
                  onChanged: (mp) => setState(() => _medioPagoSena = mp),
                ),
                Separacion.media,
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saldo que restará cobrar:',
                        style: tema.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        (_total - (_montoSena ?? Dinero.cero)).formatear(),
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tema.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        TarjetaSeccion(
          titulo: 'Notas generales',
          icono: Icons.notes_outlined,
          children: [
            CampoTexto(
              key: const ValueKey('notas_generales'),
              etiqueta: 'Aclaraciones, temática o detalles especiales',
              valorInicial: _notas,
              maxLineas: 3,
              onChanged: (v) => _notas = v,
            ),
          ],
        ),
      ],
      botonGuardar: BotonGuardar(
        texto: widget.esEdicion ? 'Guardar cambios' : 'Crear pedido',
        onGuardar: _guardar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.esEdicion) {
      return PantallaBase(
        titulo: 'Nuevo pedido',
        cuerpo: _construirFormulario(),
      );
    }

    final asyncDetalle = ref.watch(pedidoDetalleProvider(widget.id!));
    return PantallaBase(
      titulo: 'Editar pedido',
      cuerpo: VistaAsync<PedidoDetalle?>(
        valor: asyncDetalle,
        builder: (context, detalle) {
          _precargar(detalle!);
          return _construirFormulario();
        },
      ),
    );
  }
}
