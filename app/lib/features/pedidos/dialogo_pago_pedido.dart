import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

Future<void> mostrarDialogoPagoPedido(
  BuildContext context,
  PedidoDetalle detalle,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => DialogoPagoPedido(detalle: detalle),
  );
}

class DialogoPagoPedido extends ConsumerStatefulWidget {
  const DialogoPagoPedido({super.key, required this.detalle});

  final PedidoDetalle detalle;

  @override
  ConsumerState<DialogoPagoPedido> createState() => _DialogoPagoPedidoState();
}

class _DialogoPagoPedidoState extends ConsumerState<DialogoPagoPedido> {
  final _formKey = GlobalKey<FormState>();

  late Dinero? _monto = widget.detalle.saldo;
  MedioPago _medioPago = MedioPago.efectivo;
  late bool _esSena = widget.detalle.pagado.esCero;
  int _version = 0;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_monto == null || !_monto!.esPositivo) return;

    await ref
        .read(pedidosRepositorioProvider)
        .registrarPago(
          widget.detalle.pedido.id,
          PagoDatos(monto: _monto!, medioPago: _medioPago),
          esSena: _esSena,
        );

    if (mounted) {
      mostrarExito(context, 'Cobro registrado');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return AlertDialog(
      title: const Text('Registrar cobro'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CampoDinero(
                  key: ValueKey('monto_$_version'),
                  etiqueta: 'Monto a cobrar',
                  valorInicial: _monto,
                  obligatorio: true,
                  permitirCero: false,
                  onChanged: (v) => _monto = v,
                ),
                if (widget.detalle.saldo.esPositivo) ...[
                  Separacion.chica,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      avatar: const Icon(Icons.flash_on, size: 16),
                      label: Text(
                        'Total del saldo (${widget.detalle.saldo.formatear()})',
                      ),
                      onPressed: () {
                        setState(() {
                          _monto = widget.detalle.saldo;
                          _version++;
                        });
                      },
                    ),
                  ),
                ],
                Separacion.media,
                Text('Medio de pago', style: tema.textTheme.bodySmall),
                Separacion.chica,
                SelectorMedioPago(
                  valor: _medioPago,
                  onChanged: (mp) => setState(() => _medioPago = mp),
                ),
                Separacion.media,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Es seña'),
                  value: _esSena,
                  onChanged: (v) => setState(() => _esSena = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancelar'),
        ),
        BotonGuardar(texto: 'Registrar cobro', onGuardar: _guardar),
      ],
    );
  }
}
