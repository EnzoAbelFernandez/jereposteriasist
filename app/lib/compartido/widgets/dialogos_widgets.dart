import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoConfirmar = 'Confirmar',
  bool peligroso = false,
}) async {
  final cs = Theme.of(context).colorScheme;
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: peligroso
              ? FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                )
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  return res ?? false;
}

Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  required String etiqueta,
  bool obligatorio = true,
  String textoConfirmar = 'Aceptar',
}) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final res = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: obligatorio ? '$etiqueta *' : etiqueta,
          ),
          validator: (v) {
            if (obligatorio && (v == null || v.trim().isEmpty)) {
              return 'Completá este campo.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(ctx).pop(controller.text.trim());
            }
          },
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  controller.dispose();
  return res;
}

void mostrarExito(BuildContext context, String mensaje) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
  );
}

void mostrarError(BuildContext context, Object error) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final cs = Theme.of(context).colorScheme;
  final String texto;
  if (error is ErrorDeNegocio) {
    texto = error.mensaje;
  } else {
    texto = 'Ocurrió un error inesperado';
  }
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(texto),
      backgroundColor: cs.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> ejecutarConManejo(
  BuildContext context,
  Future<void> Function() accion, {
  String? mensajeExito,
}) async {
  try {
    await accion();
    if (context.mounted && mensajeExito != null) {
      mostrarExito(context, mensajeExito);
    }
  } catch (e) {
    if (context.mounted) {
      mostrarError(context, e);
    }
  }
}
