import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class PedidosListaPantalla extends StatelessWidget {
  const PedidosListaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Pedidos',
      cuerpo: EstadoVacio(
        icono: Icons.receipt_long_outlined,
        mensaje: 'Pantalla en construcción (F1-10)',
      ),
    );
  }
}
