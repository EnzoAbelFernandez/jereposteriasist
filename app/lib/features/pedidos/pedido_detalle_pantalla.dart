import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class PedidoDetallePantalla extends StatelessWidget {
  const PedidoDetallePantalla({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Detalle de pedido',
      cuerpo: EstadoVacio(
        icono: Icons.receipt_long_outlined,
        mensaje: 'Pantalla en construcción (F1-12)',
      ),
    );
  }
}
