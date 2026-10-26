import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/widgets/dialogos_widgets.dart';
import 'package:jereposteria/compartido/widgets/estructura_widgets.dart';
import 'package:jereposteria/data/data.dart';

class _SelectorEntidadBase<T> extends StatelessWidget {
  const _SelectorEntidadBase({
    required this.etiqueta,
    required this.obligatorio,
    required this.asyncOpciones,
    required this.idSeleccionado,
    required this.idDe,
    required this.textoDe,
    required this.onChanged,
    this.accionExtra,
  });

  final String etiqueta;
  final bool obligatorio;
  final AsyncValue<List<T>> asyncOpciones;
  final String? idSeleccionado;
  final String Function(T) idDe;
  final String Function(T) textoDe;
  final ValueChanged<T?> onChanged;
  final Widget? accionExtra;

  @override
  Widget build(BuildContext context) {
    final opciones = asyncOpciones.value ?? <T>[];
    T? actual;
    if (idSeleccionado != null) {
      for (final op in opciones) {
        if (idDe(op) == idSeleccionado) {
          actual = op;
          break;
        }
      }
    }
    final valorInicial = actual != null ? idSeleccionado : null;
    final campo = DropdownButtonFormField<String?>(
      key: ValueKey('${etiqueta}_${valorInicial}_${opciones.length}'),
      initialValue: valorInicial,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: obligatorio ? '$etiqueta *' : etiqueta,
      ),
      items: [
        if (!obligatorio)
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Sin seleccionar'),
          ),
        for (final op in opciones)
          DropdownMenuItem<String?>(
            value: idDe(op),
            child: Text(textoDe(op), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (nuevoId) {
        if (nuevoId == null) {
          onChanged(null);
          return;
        }
        for (final op in opciones) {
          if (idDe(op) == nuevoId) {
            onChanged(op);
            return;
          }
        }
      },
      validator: (v) {
        if (obligatorio && (v == null || v.isEmpty)) {
          return 'Elegí una opción.';
        }
        return null;
      },
    );
    if (accionExtra == null) return campo;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: campo),
        Separacion.chica,
        Padding(padding: const EdgeInsets.only(top: 4), child: accionExtra!),
      ],
    );
  }
}

class SelectorCliente extends ConsumerStatefulWidget {
  const SelectorCliente({
    super.key,
    this.clienteId,
    required this.onChanged,
    this.obligatorio = false,
    this.permitirCrear = true,
  });

  final String? clienteId;
  final ValueChanged<Cliente?> onChanged;
  final bool obligatorio;
  final bool permitirCrear;

  @override
  ConsumerState<SelectorCliente> createState() => _SelectorClienteState();
}

class _SelectorClienteState extends ConsumerState<SelectorCliente> {
  String? _seleccionadoId;

  @override
  void initState() {
    super.initState();
    _seleccionadoId = widget.clienteId;
  }

  @override
  void didUpdateWidget(covariant SelectorCliente oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clienteId != widget.clienteId) {
      _seleccionadoId = widget.clienteId;
    }
  }

  Future<void> _crearRapido(BuildContext context) async {
    final nombreCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo cliente rápido'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresá el nombre.'
                    : null,
              ),
              Separacion.chica,
              TextFormField(
                controller: telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      nombreCtrl.dispose();
      telCtrl.dispose();
      return;
    }
    try {
      final repo = ref.read(clientesRepositorioProvider);
      final nuevoId = await repo.crear(
        ClienteDatos(
          nombre: nombreCtrl.text.trim(),
          telefono: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
        ),
      );
      final creado = await repo.observarPorId(nuevoId).first;
      if (mounted && creado != null) {
        setState(() => _seleccionadoId = creado.id);
        widget.onChanged(creado);
      }
    } catch (e) {
      if (context.mounted) {
        mostrarError(context, e);
      }
    } finally {
      nombreCtrl.dispose();
      telCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncClientes = ref.watch(clientesProvider(''));
    return _SelectorEntidadBase<Cliente>(
      etiqueta: 'Cliente',
      obligatorio: widget.obligatorio,
      asyncOpciones: asyncClientes,
      idSeleccionado: _seleccionadoId,
      idDe: (c) => c.id,
      textoDe: (c) => c.telefono != null && c.telefono!.isNotEmpty
          ? '${c.nombre} (${c.telefono})'
          : c.nombre,
      onChanged: (c) {
        setState(() => _seleccionadoId = c?.id);
        widget.onChanged(c);
      },
      accionExtra: widget.permitirCrear
          ? IconButton.filledTonal(
              tooltip: 'Crear cliente rápido',
              onPressed: () => _crearRapido(context),
              icon: const Icon(Icons.person_add_alt_1),
            )
          : null,
    );
  }
}

class SelectorProveedor extends ConsumerWidget {
  const SelectorProveedor({
    super.key,
    this.proveedorId,
    required this.onChanged,
    this.obligatorio = false,
  });

  final String? proveedorId;
  final ValueChanged<Proveedor?> onChanged;
  final bool obligatorio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(proveedoresProvider(''));
    return _SelectorEntidadBase<Proveedor>(
      etiqueta: 'Proveedor',
      obligatorio: obligatorio,
      asyncOpciones: asyncItems,
      idSeleccionado: proveedorId,
      idDe: (p) => p.id,
      textoDe: (p) => p.nombre,
      onChanged: onChanged,
    );
  }
}

class SelectorInsumo extends ConsumerWidget {
  const SelectorInsumo({
    super.key,
    this.insumoId,
    required this.onChanged,
    this.obligatorio = false,
    this.excluir = const {},
  });

  final String? insumoId;
  final ValueChanged<Insumo?> onChanged;
  final bool obligatorio;
  final Set<String> excluir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(insumosProvider(''));
    final filtrados = asyncItems.whenData(
      (lista) => lista
          .where((i) => i.id == insumoId || !excluir.contains(i.id))
          .toList(),
    );
    return _SelectorEntidadBase<Insumo>(
      etiqueta: 'Insumo',
      obligatorio: obligatorio,
      asyncOpciones: filtrados,
      idSeleccionado: insumoId,
      idDe: (i) => i.id,
      textoDe: (i) => '${i.nombre} (${i.unidad.sufijoBase})',
      onChanged: onChanged,
    );
  }
}

class SelectorProducto extends ConsumerWidget {
  const SelectorProducto({
    super.key,
    this.productoId,
    required this.onChanged,
    this.obligatorio = false,
  });

  final String? productoId;
  final ValueChanged<Producto?> onChanged;
  final bool obligatorio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(productosProvider(const FiltroProductos()));
    return _SelectorEntidadBase<Producto>(
      etiqueta: 'Producto del catálogo',
      obligatorio: obligatorio,
      asyncOpciones: asyncItems,
      idSeleccionado: productoId,
      idDe: (p) => p.id,
      textoDe: (p) => p.precioBase != null
          ? '${p.nombre} (${p.precioBase!.formatear()})'
          : p.nombre,
      onChanged: onChanged,
    );
  }
}

class SelectorCategoriaGasto extends ConsumerWidget {
  const SelectorCategoriaGasto({
    super.key,
    this.categoriaId,
    required this.onChanged,
    this.obligatorio = false,
  });

  final String? categoriaId;
  final ValueChanged<CategoriaGasto?> onChanged;
  final bool obligatorio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(categoriasGastoProvider(false));
    return _SelectorEntidadBase<CategoriaGasto>(
      etiqueta: 'Categoría de gasto',
      obligatorio: obligatorio,
      asyncOpciones: asyncItems,
      idSeleccionado: categoriaId,
      idDe: (c) => c.id,
      textoDe: (c) => c.nombre,
      onChanged: onChanged,
    );
  }
}

class SelectorPerfil extends ConsumerWidget {
  const SelectorPerfil({
    super.key,
    this.perfilId,
    required this.onChanged,
    this.obligatorio = false,
  });

  final String? perfilId;
  final ValueChanged<Perfil?> onChanged;
  final bool obligatorio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(perfilesProvider(false));
    return _SelectorEntidadBase<Perfil>(
      etiqueta: 'Asignar a',
      obligatorio: obligatorio,
      asyncOpciones: asyncItems,
      idSeleccionado: perfilId,
      idDe: (p) => p.id,
      textoDe: (p) => '${p.nombre} (${p.rol.etiqueta})',
      onChanged: onChanged,
    );
  }
}

class SelectorPedido extends ConsumerWidget {
  const SelectorPedido({
    super.key,
    this.pedidoId,
    required this.onChanged,
    this.obligatorio = false,
  });

  final String? pedidoId;
  final ValueChanged<PedidoResumen?> onChanged;
  final bool obligatorio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(pedidosProvider(FiltroPedidos.activos));
    return _SelectorEntidadBase<PedidoResumen>(
      etiqueta: 'Pedido vinculado',
      obligatorio: obligatorio,
      asyncOpciones: asyncItems,
      idSeleccionado: pedidoId,
      idDe: (p) => p.pedido.id,
      textoDe: (p) => '${p.pedido.numeroTexto} – ${p.clienteNombre}',
      onChanged: onChanged,
    );
  }
}
