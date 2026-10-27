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
  bool _ocultarPassword = true;

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
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    return PantallaBase(
      titulo: 'Ingresar a JeRepostería',
      cuerpo: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              color: cs.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.bakery_dining,
                            size: 42,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                      Separacion.media,
                      Text(
                        'JeRepostería',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gestión de repostería artesanal',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Separacion.grande,
                      CampoTexto(
                        etiqueta: 'Correo electrónico',
                        obligatorio: true,
                        teclado: TextInputType.emailAddress,
                        icono: Icons.email_outlined,
                        onChanged: (v) => _email = v,
                      ),
                      Separacion.media,
                      TextFormField(
                        obscureText: _ocultarPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            tooltip: _ocultarPassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () => setState(
                              () => _ocultarPassword = !_ocultarPassword,
                            ),
                          ),
                        ),
                        onChanged: (v) => _password = v.trim(),
                        onFieldSubmitted: (_) => _ingresar(),
                        validator: (v) {
                          final limpio = (v ?? '').trim();
                          if (limpio.isEmpty) {
                            return 'Completá este campo.';
                          }
                          return null;
                        },
                      ),
                      Separacion.grande,
                      BotonGuardar(texto: 'Ingresar', onGuardar: _ingresar),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
