import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class InicioPantalla extends StatelessWidget {
  const InicioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Inicio',
      cuerpo: EstadoVacio(
        icono: Icons.home_outlined,
        mensaje: 'Pantalla en construcción (F1-23)',
      ),
    );
  }
}
