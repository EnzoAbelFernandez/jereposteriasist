import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class RecetasListaPantalla extends StatelessWidget {
  const RecetasListaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Recetas',
      cuerpo: EstadoVacio(
        icono: Icons.menu_book_outlined,
        mensaje: 'Pantalla en construcción (F2-01)',
      ),
    );
  }
}
