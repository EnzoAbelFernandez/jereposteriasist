import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class ReportesPantalla extends StatelessWidget {
  const ReportesPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Reportes',
      cuerpo: EstadoVacio(
        icono: Icons.bar_chart_outlined,
        mensaje: 'Pantalla en construcción (F2-05)',
      ),
    );
  }
}
