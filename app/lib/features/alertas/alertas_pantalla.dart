import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class AlertasPantalla extends StatelessWidget {
  const AlertasPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Alertas y avisos',
      cuerpo: EstadoVacio(
        icono: Icons.notifications_outlined,
        mensaje: 'Pantalla en construcción (F1-22)',
      ),
    );
  }
}
