import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class StockListaPantalla extends StatelessWidget {
  const StockListaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Stock e insumos',
      cuerpo: EstadoVacio(
        icono: Icons.inventory_2_outlined,
        mensaje: 'Pantalla en construcción (F1-05)',
      ),
    );
  }
}
