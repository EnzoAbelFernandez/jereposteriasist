import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class StockMovimientosPantalla extends StatelessWidget {
  const StockMovimientosPantalla({super.key, required this.insumoId});
  final String insumoId;

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Movimientos de stock',
      cuerpo: EstadoVacio(
        icono: Icons.history,
        mensaje: 'Pantalla en construcción (F1-07)',
      ),
    );
  }
}
