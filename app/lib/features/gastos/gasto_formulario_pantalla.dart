import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class GastoFormularioPantalla extends StatelessWidget {
  const GastoFormularioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Nuevo gasto',
      cuerpo: EstadoVacio(
        icono: Icons.receipt_outlined,
        mensaje: 'Pantalla en construcción (F1-16)',
      ),
    );
  }
}
