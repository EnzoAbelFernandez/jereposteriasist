import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class InsumoFormularioPantalla extends StatelessWidget {
  const InsumoFormularioPantalla({super.key, this.id});
  final String? id;

  bool get esEdicion => id != null;

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: esEdicion ? 'Editar insumo' : 'Nuevo insumo',
      cuerpo: const EstadoVacio(
        icono: Icons.inventory_2_outlined,
        mensaje: 'Pantalla en construcción (F1-02)',
      ),
    );
  }
}
