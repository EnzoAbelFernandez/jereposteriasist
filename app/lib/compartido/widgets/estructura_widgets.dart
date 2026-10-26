import 'package:flutter/material.dart';

abstract final class Separacion {
  static const SizedBox chica = SizedBox(height: 8, width: 8);
  static const SizedBox media = SizedBox(height: 16, width: 16);
  static const SizedBox grande = SizedBox(height: 24, width: 24);
}

class PantallaBase extends StatelessWidget {
  const PantallaBase({
    super.key,
    required this.titulo,
    this.acciones = const [],
    required this.cuerpo,
    this.botonFlotante,
    this.pie,
  });

  final String titulo;
  final List<Widget> acciones;
  final Widget cuerpo;
  final Widget? botonFlotante;
  final Widget? pie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo), actions: acciones),
      floatingActionButton: botonFlotante,
      bottomNavigationBar: pie,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: cuerpo,
          ),
        ),
      ),
    );
  }
}

class FormularioResponsivo extends StatelessWidget {
  const FormularioResponsivo({
    super.key,
    required this.formKey,
    required this.campos,
    required this.botonGuardar,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> campos;
  final Widget botonGuardar;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < campos.length; i++) ...[
                  if (i > 0) Separacion.media,
                  campos[i],
                ],
                Separacion.grande,
                botonGuardar,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TarjetaSeccion extends StatelessWidget {
  const TarjetaSeccion({
    super.key,
    this.titulo,
    this.accion,
    required this.children,
  });

  final String? titulo;
  final Widget? accion;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titulo != null || accion != null) ...[
              Row(
                children: [
                  if (titulo != null)
                    Expanded(
                      child: Text(
                        titulo!,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ?accion,
                ],
              ),
              Separacion.chica,
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class FilaDato extends StatelessWidget {
  const FilaDato({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.icono,
    this.onTap,
  });

  final String etiqueta;
  final String? valor;
  final IconData? icono;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final texto = valor?.trim();
    if (texto == null || texto.isEmpty) {
      return const SizedBox.shrink();
    }
    final tema = Theme.of(context);
    final contenido = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 18, color: tema.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 140,
            child: Text(
              etiqueta,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              texto,
              style: tema.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return contenido;
    return InkWell(onTap: onTap, child: contenido);
  }
}

class EncabezadoGrupo extends StatelessWidget {
  const EncabezadoGrupo({super.key, required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        texto,
        style: tema.textTheme.titleSmall?.copyWith(
          color: tema.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
