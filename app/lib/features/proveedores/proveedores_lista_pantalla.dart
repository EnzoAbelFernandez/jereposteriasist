import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class ProveedoresListaPantalla extends StatelessWidget {
  const ProveedoresListaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Proveedores',
      cuerpo: EstadoVacio(
        icono: Icons.local_shipping_outlined,
        mensaje: 'Pantalla en construcción (F1-01)',
      ),
    );
  }
}
