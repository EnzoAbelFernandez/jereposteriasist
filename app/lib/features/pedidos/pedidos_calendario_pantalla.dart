import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class PedidosCalendarioPantalla extends StatelessWidget {
  const PedidosCalendarioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Calendario de entregas',
      cuerpo: EstadoVacio(
        icono: Icons.calendar_month_outlined,
        mensaje: 'Pantalla en construcción (F1-13)',
      ),
    );
  }
}
