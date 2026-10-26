import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class GastosListaPantalla extends StatelessWidget {
  const GastosListaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Gastos',
      cuerpo: EstadoVacio(
        icono: Icons.receipt_outlined,
        mensaje: 'Pantalla en construcción (F1-16)',
      ),
    );
  }
}
