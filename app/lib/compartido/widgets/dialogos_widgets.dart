import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<void> mostrarDialogoExportacion(
  BuildContext context, {
  required String titulo,
  required String nombreArchivo,
  required String contenido,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Archivo sugerido: $nombreArchivo',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    contenido,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: contenido));
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
            }
            if (context.mounted) {
              mostrarExito(context, 'Copiado al portapapeles');
            }
          },
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: const Text('Copiar al portapapeles'),
        ),
      ],
    ),
  );
}
