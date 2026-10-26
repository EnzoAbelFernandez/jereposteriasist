import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class ProductoFormularioPantalla extends StatelessWidget {
  const ProductoFormularioPantalla({super.key, this.id});
  final String? id;

  bool get esEdicion => id != null;

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: esEdicion ? 'Editar producto' : 'Nuevo producto',
      cuerpo: const EstadoVacio(
        icono: Icons.cake_outlined,
        mensaje: 'Pantalla en construcción (F1-03)',
      ),
    );
  }
}
