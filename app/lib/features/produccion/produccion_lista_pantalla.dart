import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class ProduccionListaPantalla extends StatelessWidget {
  const ProduccionListaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Producción',
      cuerpo: EstadoVacio(
        icono: Icons.bakery_dining_outlined,
        mensaje: 'Pantalla en construcción (F1-17)',
      ),
    );
  }
}
