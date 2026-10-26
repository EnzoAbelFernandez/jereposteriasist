import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class RecetaFormularioPantalla extends StatelessWidget {
  const RecetaFormularioPantalla({super.key, this.id});
  final String? id;

  bool get esEdicion => id != null;

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: esEdicion ? 'Editar receta' : 'Nueva receta',
      cuerpo: const EstadoVacio(
        icono: Icons.menu_book_outlined,
        mensaje: 'Pantalla en construcción (F2-01)',
      ),
    );
  }
}
