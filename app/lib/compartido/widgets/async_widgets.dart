import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/compartido/widgets/estructura_widgets.dart';

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.mensaje,
    this.textoAccion,
    this.onAccion,
  });

  final IconData icono;
  final String mensaje;
  final String? textoAccion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tema.colorScheme.primaryContainer.withValues(alpha: 0.4),
              ),
              child: Icon(icono, size: 38, color: tema.colorScheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyLarge?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (textoAccion != null && onAccion != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: onAccion,
                child: Text(textoAccion!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ListaAsync<T> extends StatelessWidget {
  const ListaAsync({
    super.key,
    required this.valor,
    required this.itemBuilder,
    required this.vacio,
    this.onRefresh,
    this.encabezado,
    this.separadores = true,
  });

  final AsyncValue<List<T>> valor;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget vacio;
  final Future<void> Function()? onRefresh;
  final Widget? encabezado;
  final bool separadores;

  @override
  Widget build(BuildContext context) {
    return valor.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) {
        final msg = err is ErrorDeNegocio
            ? err.mensaje
            : 'No se pudo cargar la lista.';
        return EstadoVacio(icono: Icons.error_outline, mensaje: msg);
      },
      data: (items) {
        if (items.isEmpty) {
          if (encabezado == null) return vacio;
          return Column(
            children: [
              encabezado!,
              Expanded(child: vacio),
            ],
          );
        }
        final total = items.length + (encabezado != null ? 1 : 0);
        final listView = ListView.separated(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: total,
          separatorBuilder: (context, index) {
            if (!separadores) return const SizedBox.shrink();
            if (encabezado != null && index == 0) {
              return const SizedBox.shrink();
            }
            return Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant
                  .withValues(alpha: 0.45),
            );
          },
          itemBuilder: (context, index) {
            if (encabezado != null) {
              if (index == 0) return encabezado!;
              return itemBuilder(context, items[index - 1]);
            }
            return itemBuilder(context, items[index]);
          },
        );
        if (onRefresh != null) {
          return RefreshIndicator(onRefresh: onRefresh!, child: listView);
        }
        return listView;
      },
    );
  }
}

class VistaAsync<T> extends StatelessWidget {
  const VistaAsync({super.key, required this.valor, required this.builder});

  final AsyncValue<T> valor;
  final Widget Function(BuildContext context, T datos) builder;

  @override
  Widget build(BuildContext context) {
    return valor.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) {
        final msg = err is ErrorDeNegocio
            ? err.mensaje
            : 'No se pudo cargar la información.';
        return EstadoVacio(icono: Icons.error_outline, mensaje: msg);
      },
      data: (datos) {
        if (datos == null) {
          return const EstadoVacio(
            icono: Icons.search_off_outlined,
            mensaje: 'No encontrado',
          );
        }
        return builder(context, datos);
      },
    );
  }
}

class CampoBusqueda extends StatefulWidget {
  const CampoBusqueda({
    super.key,
    required this.onChanged,
    this.hint = 'Buscar...',
  });

  final ValueChanged<String> onChanged;
  final String hint;

  @override
  State<CampoBusqueda> createState() => _CampoBusquedaState();
}

class _CampoBusquedaState extends State<CampoBusqueda> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _alCambiar(String valor) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onChanged(valor.trim());
      }
    });
  }

  void _limpiar() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {});
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _controller,
        onChanged: _alCambiar,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: tema.textTheme.bodyMedium?.copyWith(
            color: tema.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: tema.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Limpiar búsqueda',
                  onPressed: _limpiar,
                )
              : null,
          filled: true,
          fillColor: tema.colorScheme.surfaceContainerLowest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: tema.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: tema.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: tema.colorScheme.primary, width: 1.8),
          ),
        ),
      ),
    );
  }
}

class ChipsFiltro<T> extends StatelessWidget {
  const ChipsFiltro({
    super.key,
    required this.opciones,
    required this.seleccionados,
    required this.etiqueta,
    required this.onChanged,
    this.multiple = true,
  });

  final List<T> opciones;
  final Set<T> seleccionados;
  final String Function(T) etiqueta;
  final ValueChanged<Set<T>> onChanged;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          for (var i = 0; i < opciones.length; i++) ...[
            if (i > 0) Separacion.chica,
            FilterChip(
              label: Text(etiqueta(opciones[i])),
              selected: seleccionados.contains(opciones[i]),
              onSelected: (activo) {
                final copia = Set<T>.of(seleccionados);
                if (multiple) {
                  if (activo) {
                    copia.add(opciones[i]);
                  } else {
                    copia.remove(opciones[i]);
                  }
                } else {
                  copia.clear();
                  if (activo) {
                    copia.add(opciones[i]);
                  }
                }
                onChanged(copia);
              },
            ),
          ],
        ],
      ),
    );
  }
}
