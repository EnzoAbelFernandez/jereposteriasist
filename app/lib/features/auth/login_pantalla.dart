import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/core/sesion/sesion.dart';

class LoginPantalla extends ConsumerStatefulWidget {
  const LoginPantalla({super.key});

  @override
  ConsumerState<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends ConsumerState<LoginPantalla> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  Future<void> _ingresar() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(sesionControllerProvider)
        .iniciarSesion(email: _email, password: _password);
    if (mounted) {
      context.go(Rutas.inicio);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Ingresar a JeRepostería',
      cuerpo: FormularioResponsivo(
        formKey: _formKey,
        campos: [
          CampoTexto(
            etiqueta: 'Email',
            obligatorio: true,
            teclado: TextInputType.emailAddress,
            icono: Icons.email_outlined,
            onChanged: (v) => _email = v,
          ),
          CampoTexto(
            etiqueta: 'Contraseña',
            obligatorio: true,
            icono: Icons.lock_outline,
            onChanged: (v) => _password = v,
          ),
        ],
        botonGuardar: BotonGuardar(texto: 'Ingresar', onGuardar: _ingresar),
      ),
    );
  }
}
