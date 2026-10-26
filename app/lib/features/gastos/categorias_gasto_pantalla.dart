import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class CategoriasGastoPantalla extends StatelessWidget {
  const CategoriasGastoPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Categorías de gasto',
      cuerpo: EstadoVacio(
        icono: Icons.category_outlined,
        mensaje: 'Pantalla en construcción (F1-04)',
      ),
    );
  }
}
