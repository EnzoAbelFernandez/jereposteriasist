import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class ComprasListaPantalla extends StatelessWidget {
  const ComprasListaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Compras',
      cuerpo: EstadoVacio(
        icono: Icons.shopping_cart_outlined,
        mensaje: 'Pantalla en construcción (F1-08)',
      ),
    );
  }
}
