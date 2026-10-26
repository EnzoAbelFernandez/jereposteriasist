import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class CompraDetallePantalla extends StatelessWidget {
  const CompraDetallePantalla({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Detalle de compra',
      cuerpo: EstadoVacio(
        icono: Icons.shopping_cart_outlined,
        mensaje: 'Pantalla en construcción (F1-08)',
      ),
    );
  }
}
