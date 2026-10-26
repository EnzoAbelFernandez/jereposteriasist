import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class CajaPantalla extends StatelessWidget {
  const CajaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Caja',
      cuerpo: EstadoVacio(
        icono: Icons.point_of_sale_outlined,
        mensaje: 'Pantalla en construcción (F1-14)',
      ),
    );
  }
}
