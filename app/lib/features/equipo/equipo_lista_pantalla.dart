import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class EquipoListaPantalla extends StatelessWidget {
  const EquipoListaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Equipo',
      cuerpo: EstadoVacio(
        icono: Icons.badge_outlined,
        mensaje: 'Pantalla en construcción (F1-20)',
      ),
    );
  }
}
