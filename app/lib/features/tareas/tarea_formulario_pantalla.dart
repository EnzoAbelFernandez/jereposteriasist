import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class TareaFormularioPantalla extends StatelessWidget {
  const TareaFormularioPantalla({super.key, this.id});
  final String? id;

  bool get esEdicion => id != null;

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: esEdicion ? 'Editar tarea' : 'Nueva tarea',
      cuerpo: const EstadoVacio(
        icono: Icons.task_alt_outlined,
        mensaje: 'Pantalla en construcción (F1-19)',
      ),
    );
  }
}
