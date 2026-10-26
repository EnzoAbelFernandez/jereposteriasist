import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class ConfiguracionPantalla extends StatelessWidget {
  const ConfiguracionPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Configuración',
      cuerpo: EstadoVacio(
        icono: Icons.settings_outlined,
        mensaje: 'Pantalla en construcción (F1-20)',
      ),
    );
  }
}
