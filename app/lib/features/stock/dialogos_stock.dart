import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

Future<void> mostrarDialogoAjusteStock(
  BuildContext context,
  InsumoConStock item,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _DialogoAjusteStock(item: item),
  );
}

Future<void> mostrarDialogoMerma(BuildContext context, InsumoConStock item) {
  return showDialog<void>(
    context: context,
    builder: (context) => _DialogoMerma(item: item),
  );
}

class _DialogoAjusteStock extends ConsumerStatefulWidget {
  const _DialogoAjusteStock({required this.item});

  final InsumoConStock item;

  @override
  ConsumerState<_DialogoAjusteStock> createState() =>
      _DialogoAjusteStockState();
}

class _DialogoAjusteStockState extends ConsumerState<_DialogoAjusteStock> {
  final _formKey = GlobalKey<FormState>();
  late int? _cantidadContada;
  String _nota = '';

  @override
  void initState() {
    super.initState();
    _cantidadContada = widget.item.stock >= 0 ? widget.item.stock : 0;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cantidadContada == null) return;

    await ref
        .read(stockRepositorioProvider)
        .ajustarAConteo(
          insumoId: widget.item.insumo.id,
          cantidadContada: _cantidadContada!,
          nota: _nota.trim().isEmpty ? null : _nota.trim(),
        );

    if (mounted) {
      mostrarExito(context, 'Stock ajustado');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajustar stock de ${widget.item.insumo.nombre}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock registrado hoy: ${widget.item.stockTexto}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Separacion.media,
                CampoCantidad(
                  etiqueta: 'Cantidad real contada',
                  unidad: widget.item.insumo.unidad,
                  valorInicial: widget.item.stock >= 0 ? widget.item.stock : 0,
                  obligatorio: true,
                  permitirCero: true,
                  onChanged: (v) => _cantidadContada = v,
                ),
                Separacion.media,
                CampoTexto(
                  etiqueta: 'Motivo / nota (opcional)',
                  maxLineas: 2,
                  onChanged: (v) => _nota = v,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancelar'),
        ),
        BotonGuardar(texto: 'Aplicar ajuste', onGuardar: _guardar),
      ],
    );
  }
}

class _DialogoMerma extends ConsumerStatefulWidget {
  const _DialogoMerma({required this.item});

  final InsumoConStock item;

  @override
  ConsumerState<_DialogoMerma> createState() => _DialogoMermaState();
}

class _DialogoMermaState extends ConsumerState<_DialogoMerma> {
  final _formKey = GlobalKey<FormState>();
  int? _cantidad;
  String _motivo = '';

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cantidad == null || _cantidad! <= 0) return;

    await ref
        .read(stockRepositorioProvider)
        .registrarMerma(
          insumoId: widget.item.insumo.id,
          cantidad: _cantidad!,
          nota: _motivo.trim().isEmpty ? null : _motivo.trim(),
        );

    if (mounted) {
      mostrarExito(context, 'Merma registrada');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Registrar merma de ${widget.item.insumo.nombre}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CampoCantidad(
                  etiqueta: 'Cantidad que se descartó o perdió',
                  unidad: widget.item.insumo.unidad,
                  obligatorio: true,
                  permitirCero: false,
                  onChanged: (v) => _cantidad = v,
                ),
                Separacion.media,
                CampoTexto(
                  etiqueta: 'Motivo (opcional)',
                  maxLineas: 2,
                  onChanged: (v) => _motivo = v,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancelar'),
        ),
        BotonGuardar(texto: 'Registrar merma', onGuardar: _guardar),
      ],
    );
  }
}
