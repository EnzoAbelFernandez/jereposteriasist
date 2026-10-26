import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class ComprasSugeridasPantalla extends StatelessWidget {
  const ComprasSugeridasPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaBase(
      titulo: 'Compras sugeridas',
      cuerpo: EstadoVacio(
        icono: Icons.playlist_add_check_outlined,
        mensaje: 'Pantalla en construcción (F2-04)',
      ),
    );
  }
}
