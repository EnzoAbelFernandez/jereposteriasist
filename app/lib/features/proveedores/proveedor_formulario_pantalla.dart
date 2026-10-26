import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class ProveedorFormularioPantalla extends StatelessWidget {
  const ProveedorFormularioPantalla({super.key, this.id});
  final String? id;

  bool get esEdicion => id != null;

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: esEdicion ? 'Editar proveedor' : 'Nuevo proveedor',
      cuerpo: const EstadoVacio(
        icono: Icons.local_shipping_outlined,
        mensaje: 'Pantalla en construcción (F1-01)',
      ),
    );
  }
}
