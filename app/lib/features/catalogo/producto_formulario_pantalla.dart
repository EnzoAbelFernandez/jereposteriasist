import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class ProductoFormularioPantalla extends ConsumerStatefulWidget {
  const ProductoFormularioPantalla({super.key, this.id});
  final String? id;

  bool get esEdicion => id != null;

  @override
  ConsumerState<ProductoFormularioPantalla> createState() =>
      _ProductoFormularioPantallaState();
}

class _ProductoFormularioPantallaState
    extends ConsumerState<ProductoFormularioPantalla> {
  final _formKey = GlobalKey<FormState>();
  bool _inicializado = false;

  String _nombre = '';
  CategoriaProducto _categoria = CategoriaProducto.torta;
  Dinero? _precioBase;
  String _descripcion = '';

  void _precargar(Producto p) {
    if (_inicializado) return;
    _inicializado = true;
    _nombre = p.nombre;
    _categoria = p.categoria;
    _precioBase = p.precioBase;
    _descripcion = p.descripcion ?? '';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final datos = ProductoDatos(
      nombre: _nombre.trim(),
      categoria: _categoria,
      precioBase: _precioBase,
      descripcion: _descripcion.trim().isEmpty ? null : _descripcion.trim(),
    );
    final repo = ref.read(productosRepositorioProvider);
    if (widget.esEdicion) {
      await repo.actualizar(widget.id!, datos);
    } else {
      await repo.crear(datos);
    }
    if (mounted) {
      mostrarExito(context, 'Producto guardado');
      context.pop();
    }
  }

  Future<void> _archivar() async {
    final ok = await confirmar(
      context,
      titulo: 'Archivar producto',
      mensaje: '¿Querés archivar este producto?',
      textoConfirmar: 'Archivar',
      peligroso: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(productosRepositorioProvider).archivar(widget.id!);
      if (mounted) {
        mostrarExito(context, 'Producto archivado');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        mostrarError(context, e);
      }
    }
  }

  Widget _construirFormulario() {
    return FormularioResponsivo(
      formKey: _formKey,
      campos: [
        CampoTexto(
          etiqueta: 'Nombre',
          valorInicial: _nombre,
          obligatorio: true,
          icono: Icons.cake_outlined,
          onChanged: (v) => _nombre = v,
        ),
        SelectorOpcion<CategoriaProducto>(
          etiqueta: 'Categoría',
          opciones: CategoriaProducto.values,
          valor: _categoria,
          etiquetaDe: (c) => c.etiqueta,
          obligatorio: true,
          onChanged: (c) {
            if (c != null) {
              setState(() => _categoria = c);
            }
          },
        ),
        CampoDinero(
          etiqueta: 'Precio sugerido (opcional)',
          valorInicial: _precioBase,
          obligatorio: false,
          onChanged: (v) => _precioBase = v,
        ),
        CampoTexto(
          etiqueta: 'Descripción / notas',
          valorInicial: _descripcion,
          maxLineas: 3,
          icono: Icons.notes_outlined,
          onChanged: (v) => _descripcion = v,
        ),
      ],
      botonGuardar: BotonGuardar(
        texto: widget.esEdicion ? 'Guardar cambios' : 'Crear producto',
        onGuardar: _guardar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.esEdicion) {
      return PantallaBase(
        titulo: 'Nuevo producto',
        cuerpo: _construirFormulario(),
      );
    }

    final asyncProducto = ref.watch(productoProvider(widget.id!));
    return PantallaBase(
      titulo: 'Editar producto',
      acciones: [
        RequierePermiso(
          modulo: Modulo.catalogo,
          nivel: NivelPermiso.editar,
          child: IconButton(
            tooltip: 'Archivar',
            icon: const Icon(Icons.archive_outlined),
            onPressed: _archivar,
          ),
        ),
      ],
      cuerpo: VistaAsync<Producto?>(
        valor: asyncProducto,
        builder: (context, producto) {
          _precargar(producto!);
          return _construirFormulario();
        },
      ),
    );
  }
}
