import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class EquipoPermisosPantalla extends StatelessWidget {
  const EquipoPermisosPantalla({super.key, required this.perfilId});
  final String perfilId;

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Permisos del empleado',
      cuerpo: EstadoVacio(
        icono: Icons.security_outlined,
        mensaje: 'Pantalla en construcción (F1-21)',
      ),
    );
  }
}
