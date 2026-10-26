import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/compartido.dart';

class PedidoFormularioPantalla extends StatelessWidget {
  const PedidoFormularioPantalla({super.key, this.id, this.clienteIdInicial});

  final String? id;
  final String? clienteIdInicial;

  bool get esEdicion => id != null;

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: esEdicion ? 'Editar pedido' : 'Nuevo pedido',
      cuerpo: const EstadoVacio(
        icono: Icons.receipt_long_outlined,
        mensaje: 'Pantalla en construcción (F1-11)',
      ),
    );
  }
}
