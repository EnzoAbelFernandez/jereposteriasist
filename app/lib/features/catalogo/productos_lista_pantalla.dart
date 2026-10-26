import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class ProductosListaPantalla extends StatelessWidget {
  const ProductosListaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Productos',
      cuerpo: EstadoVacio(
        icono: Icons.cake_outlined,
        mensaje: 'Pantalla en construcción (F1-03)',
      ),
    );
  }
}
