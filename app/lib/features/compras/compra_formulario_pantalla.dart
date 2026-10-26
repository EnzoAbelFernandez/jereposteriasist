import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class CompraFormularioPantalla extends StatelessWidget {
  const CompraFormularioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Nueva compra',
      cuerpo: EstadoVacio(
        icono: Icons.shopping_cart_outlined,
        mensaje: 'Pantalla en construcción (F1-09)',
      ),
    );
  }
}
