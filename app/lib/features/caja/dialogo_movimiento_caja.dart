import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

Future<void> mostrarDialogoMovimientoCaja(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const DialogoMovimientoCaja(),
  );
}

class DialogoMovimientoCaja extends ConsumerStatefulWidget {
  const DialogoMovimientoCaja({super.key});

  @override
  ConsumerState<DialogoMovimientoCaja> createState() =>
      _DialogoMovimientoCajaState();
}

class _DialogoMovimientoCajaState extends ConsumerState<DialogoMovimientoCaja> {
  final _formKey = GlobalKey<FormState>();

  TipoMovimientoCaja _tipo = TipoMovimientoCaja.ingreso;
  Dinero? _monto;
  MedioPago _medioPago = MedioPago.efectivo;
  String _descripcion = '';

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_monto == null || !_monto!.esPositivo) return;

    await ref
        .read(cajaRepositorioProvider)
        .registrarManual(
          tipo: _tipo,
          monto: _monto!,
          medioPago: _medioPago,
          descripcion: _descripcion.trim(),
        );

    if (mounted) {
      mostrarExito(context, 'Movimiento registrado');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo movimiento'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<TipoMovimientoCaja>(
                  segments: const [
                    ButtonSegment<TipoMovimientoCaja>(
                      value: TipoMovimientoCaja.ingreso,
                      icon: Icon(Icons.arrow_downward),
                      label: Text('Ingreso'),
                    ),
                    ButtonSegment<TipoMovimientoCaja>(
                      value: TipoMovimientoCaja.egreso,
                      icon: Icon(Icons.arrow_upward),
                      label: Text('Egreso'),
                    ),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (sel) =>
                      setState(() => _tipo = sel.first),
                ),
                Separacion.media,
                CampoDinero(
                  etiqueta: 'Monto',
                  obligatorio: true,
                  permitirCero: false,
                  onChanged: (v) => _monto = v,
                ),
                Separacion.media,
                SelectorMedioPago(
                  valor: _medioPago,
                  onChanged: (v) => setState(() => _medioPago = v),
                ),
                Separacion.media,
                CampoTexto(
                  etiqueta: 'Descripción / concepto',
                  obligatorio: true,
                  onChanged: (v) => _descripcion = v,
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
        BotonGuardar(texto: 'Registrar movimiento', onGuardar: _guardar),
      ],
    );
  }
}
