import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class RecetaFormularioPantalla extends ConsumerStatefulWidget {
  const RecetaFormularioPantalla({super.key, this.id});
  final String? id;

  bool get esEdicion => id != null;

  @override
  ConsumerState<RecetaFormularioPantalla> createState() =>
      _RecetaFormularioPantallaState();
}

class _RenglonReceta {
  _RenglonReceta({
    this.insumoId,
    this.unidad,
    this.cantidad,
    this.costoEstimado,
  });

  String? insumoId;
  Unidad? unidad;
  int? cantidad;
  Dinero? costoEstimado;
}

class _RecetaFormularioPantallaState
    extends ConsumerState<RecetaFormularioPantalla> {
  final _formKey = GlobalKey<FormState>();
  bool _inicializado = false;

  String _nombre = '';
  int _nombreKeyVersion = 0;
  String? _productoId;
  int _rindeCantidad = 1;
  String _rindeDescripcion = '';
  String _notas = '';
  Dinero _costoTotal = Dinero.cero;
  bool _tieneCostoCompleto = true;
  final List<_RenglonReceta> _renglones = [];

  @override
  void initState() {
    super.initState();
    if (!widget.esEdicion) {
      _renglones.add(_RenglonReceta());
    }
  }

  void _precargar(RecetaDetalle detalle) {
    if (_inicializado) return;
    _inicializado = true;
    _nombre = detalle.receta.nombre;
    _productoId = detalle.receta.productoId;
    _rindeCantidad = detalle.receta.rindeCantidad;
    _rindeDescripcion = detalle.receta.rindeDescripcion ?? '';
    _notas = detalle.receta.notas ?? '';
    _costoTotal = detalle.costoTotalEstimado;
    _tieneCostoCompleto = detalle.tieneCostoCompleto;
    _renglones.clear();
    for (final it in detalle.items) {
      _renglones.add(
        _RenglonReceta(
          insumoId: it.item.insumoId,
          unidad: it.unidad,
          cantidad: it.item.cantidad,
          costoEstimado: it.costoEstimado,
        ),
      );
    }
    if (_renglones.isEmpty) {
      _renglones.add(_RenglonReceta());
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final items = <RecetaItemDatos>[];
    final vistos = <String>{};

    for (final r in _renglones) {
      if (r.insumoId == null || r.cantidad == null || r.cantidad! <= 0) {
        throw const ErrorDeNegocio(
          'Completá los datos de todos los ingredientes.',
        );
      }
      if (!vistos.add(r.insumoId!)) {
        throw const ErrorDeNegocio('No repitas el mismo insumo en la receta.');
      }
      items.add(RecetaItemDatos(insumoId: r.insumoId!, cantidad: r.cantidad!));
    }

    if (items.isEmpty) {
      throw const ErrorDeNegocio('Agregá al menos un ingrediente a la receta.');
    }

    final datos = RecetaDatos(
      nombre: _nombre.trim(),
      productoId: _productoId,
      rindeCantidad: _rindeCantidad,
      rindeDescripcion: _rindeDescripcion.trim().isEmpty
          ? null
          : _rindeDescripcion.trim(),
      notas: _notas.trim().isEmpty ? null : _notas.trim(),
      items: items,
    );

    final repo = ref.read(recetasRepositorioProvider);
    if (widget.esEdicion) {
      await repo.actualizar(widget.id!, datos);
    } else {
      await repo.crear(datos);
    }

    if (mounted) {
      mostrarExito(context, 'Receta guardada');
      context.pop();
    }
  }

  Future<void> _archivar() async {
    final ok = await confirmar(
      context,
      titulo: 'Archivar receta',
      mensaje: '¿Querés archivar esta receta?',
      textoConfirmar: 'Archivar',
      peligroso: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(recetasRepositorioProvider).archivar(widget.id!);
      if (mounted) {
        mostrarExito(context, 'Receta archivada');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        mostrarError(context, e);
      }
    }
  }

  Widget _construirRenglonIngrediente(int index) {
    final item = _renglones[index];
    final tema = Theme.of(context);
    return Card(
      key: ObjectKey(item),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: tema.colorScheme.primaryContainer,
                  foregroundColor: tema.colorScheme.onPrimaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ingrediente ${index + 1}',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_renglones.length > 1)
                  IconButton(
                    tooltip: 'Quitar ingrediente',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _renglones.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SelectorInsumo(
              insumoId: item.insumoId,
              obligatorio: true,
              excluir: {
                for (var j = 0; j < _renglones.length; j++)
                  if (j != index && _renglones[j].insumoId != null)
                    _renglones[j].insumoId!,
              },
              onChanged: (nuevoInsumo) {
                setState(() {
                  if (item.insumoId != nuevoInsumo?.id) {
                    item.insumoId = nuevoInsumo?.id;
                    item.unidad = nuevoInsumo?.unidad;
                    item.cantidad = null;
                    item.costoEstimado = null;
                  }
                });
              },
            ),
            if (item.insumoId != null && item.unidad != null) ...[
              Separacion.chica,
              CampoCantidad(
                key: ValueKey(
                  'cant_${identityHashCode(item)}_${item.insumoId}',
                ),
                etiqueta: 'Cantidad',
                unidad: item.unidad!,
                valorInicial: item.cantidad,
                obligatorio: true,
                permitirCero: false,
                onChanged: (c) => item.cantidad = c,
              ),
              if (item.costoEstimado != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 14,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Costo proporcional: ',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextoDinero(
                      item.costoEstimado!,
                      estilo: tema.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirFormulario() {
    return FormularioResponsivo(
      formKey: _formKey,
      campos: [
        CampoTexto(
          key: ValueKey('nombre_receta_$_nombreKeyVersion'),
          etiqueta: 'Nombre de la receta',
          valorInicial: _nombre,
          obligatorio: true,
          icono: Icons.menu_book_outlined,
          onChanged: (v) => _nombre = v,
        ),
        SelectorProducto(
          productoId: _productoId,
          obligatorio: false,
          onChanged: (p) {
            setState(() {
              _productoId = p?.id;
              if (p != null && _nombre.trim().isEmpty) {
                _nombre = p.nombre;
                _nombreKeyVersion++;
              }
            });
          },
        ),
        CampoEntero(
          etiqueta: 'Rinde (unidades/lotes)',
          valorInicial: _rindeCantidad,
          minimo: 1,
          obligatorio: true,
          onChanged: (v) => _rindeCantidad = v ?? 1,
        ),
        CampoTexto(
          etiqueta: 'Descripción del rendimiento (opcional)',
          valorInicial: _rindeDescripcion,
          obligatorio: false,
          onChanged: (v) => _rindeDescripcion = v,
        ),
        TarjetaSeccion(
          titulo: 'Ingredientes',
          icono: Icons.kitchen_outlined,
          children: [
            for (var i = 0; i < _renglones.length; i++) ...[
              if (i > 0) Separacion.chica,
              _construirRenglonIngrediente(i),
            ],
            Separacion.chica,
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _renglones.add(_RenglonReceta());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar ingrediente'),
            ),
            if (_costoTotal.esPositivo) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Costo total de insumos',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        if (_rindeCantidad > 1)
                          Text(
                            'Por unidad de rinde: ${Dinero(_costoTotal.centavos ~/ _rindeCantidad).formatear()}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                    TextoDinero(
                      _costoTotal,
                      estilo: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (!_tieneCostoCompleto) ...[
                const SizedBox(height: 6),
                Text(
                  'Costo parcial: algunos ingredientes aún no registran compras.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ],
          ],
        ),
        CampoTexto(
          etiqueta: 'Preparación / notas (opcional)',
          valorInicial: _notas,
          maxLineas: 3,
          icono: Icons.notes_outlined,
          obligatorio: false,
          onChanged: (v) => _notas = v,
        ),
      ],
      botonGuardar: BotonGuardar(
        texto: widget.esEdicion ? 'Guardar cambios' : 'Crear receta',
        onGuardar: _guardar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.esEdicion) {
      return PantallaBase(
        titulo: 'Nueva receta',
        cuerpo: _construirFormulario(),
      );
    }

    final asyncReceta = ref.watch(recetaDetalleProvider(widget.id!));
    return PantallaBase(
      titulo: 'Editar receta',
      acciones: [
        RequierePermiso(
          modulo: Modulo.produccion,
          nivel: NivelPermiso.editar,
          child: IconButton(
            tooltip: 'Archivar',
            icon: const Icon(Icons.archive_outlined),
            onPressed: _archivar,
          ),
        ),
      ],
      cuerpo: VistaAsync<RecetaDetalle?>(
        valor: asyncReceta,
        builder: (context, detalle) {
          _precargar(detalle!);
          return _construirFormulario();
        },
      ),
    );
  }
}
