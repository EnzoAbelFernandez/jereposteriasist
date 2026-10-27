import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/core/sync/estado_sync.dart';

abstract final class Separacion {
  static const SizedBox chica = SizedBox(height: 8, width: 8);
  static const SizedBox media = SizedBox(height: 16, width: 16);
  static const SizedBox grande = SizedBox(height: 24, width: 24);
}

class PantallaBase extends ConsumerWidget {
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

  Widget? _construirIndicadorSync(BuildContext context, EstadoSync? sync) {
    if (sync == null) return null;
    final cs = Theme.of(context).colorScheme;

    if (!sync.conectado) {
      return Tooltip(
        message: 'Modo sin conexión (los cambios se guardan localmente)',
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 15, color: cs.outline),
              const SizedBox(width: 4),
              Text(
                'Offline',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (sync.cambiosPendientes > 0) {
      return Tooltip(
        message:
            '${sync.cambiosPendientes} cambio(s) pendiente(s) de sincronizar',
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync, size: 15, color: cs.onSecondaryContainer),
              const SizedBox(width: 4),
              Text(
                '${sync.cambiosPendientes}',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(estadoSyncProvider).value;
    final indicadorSync = _construirIndicadorSync(context, sync);

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [?indicadorSync, ...acciones],
      ),
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
    this.icono,
    required this.children,
  });

  final String? titulo;
  final Widget? accion;
  final IconData? icono;
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
                  if (icono != null) ...[
                    Icon(icono, size: 20, color: tema.colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  if (titulo != null)
                    Expanded(
                      child: Text(
                        titulo!,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tema.colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ?accion,
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 1,
                color: tema.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
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
