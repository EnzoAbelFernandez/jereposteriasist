import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class ProduccionDetallePantalla extends StatelessWidget {
  const ProduccionDetallePantalla({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Detalle de producción',
      cuerpo: EstadoVacio(
        icono: Icons.bakery_dining_outlined,
        mensaje: 'Pantalla en construcción (F1-17)',
      ),
    );
  }
}
