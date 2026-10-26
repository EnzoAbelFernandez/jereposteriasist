import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class TareasPantalla extends StatelessWidget {
  const TareasPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Tareas',
      cuerpo: EstadoVacio(
        icono: Icons.task_alt_outlined,
        mensaje: 'Pantalla en construcción (F1-18)',
      ),
    );
  }
}
