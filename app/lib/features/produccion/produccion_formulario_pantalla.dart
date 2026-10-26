import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class ProduccionFormularioPantalla extends StatelessWidget {
  const ProduccionFormularioPantalla({super.key, this.pedidoIdInicial});
  final String? pedidoIdInicial;

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Registrar producción',
      cuerpo: EstadoVacio(
        icono: Icons.bakery_dining_outlined,
        mensaje: 'Pantalla en construcción (F1-17)',
      ),
    );
  }
}
