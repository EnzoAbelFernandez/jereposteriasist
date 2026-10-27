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

  Widget _construirFormulario({CostoProductoEstimado? costo}) {
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
        if (costo != null)
          TarjetaSeccion(
            titulo: 'Costeo y rentabilidad',
            icono: Icons.analytics_outlined,
            accion: costo.margenPorcentaje != null
                ? InsigniaEstado(
                    texto: 'Margen ${costo.margenPorcentaje}%',
                    color: costo.margenPorcentaje! >= 60
                        ? ColorEstado.exito
                        : (costo.margenPorcentaje! >= 40
                              ? ColorEstado.advertencia
                              : ColorEstado.peligro),
                  )
                : null,
            children: [
              FilaDato(
                etiqueta: 'Receta vinculada',
                valor: costo.recetaNombre,
                icono: Icons.menu_book_outlined,
              ),
              FilaDato(
                etiqueta: 'Costo de insumos',
                valor: costo.costoUnitario.formatear(),
                icono: Icons.inventory_2_outlined,
              ),
              if (costo.precioVenta != null)
                FilaDato(
                  etiqueta: 'Precio de venta actual',
                  valor: costo.precioVenta!.formatear(),
                  icono: Icons.payments_outlined,
                ),
              if (costo.margenUnitario != null)
                FilaDato(
                  etiqueta: 'Ganancia estimada',
                  valor:
                      '${costo.margenUnitario!.formatear()} por unidad (${costo.margenPorcentaje}%)',
                  icono: Icons.trending_up_outlined,
                ),
              FilaDato(
                etiqueta: 'Precio sugerido (×3)',
                valor: costo.precioSugerido().formatear(),
                icono: Icons.lightbulb_outline,
              ),
              if (!costo.tieneCostoCompleto) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: resolverColorEstado(
                      context,
                      ColorEstado.advertencia,
                    ).fondo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: resolverColorEstado(
                          context,
                          ColorEstado.advertencia,
                        ).frente,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Costo parcial: algún ingrediente aún no registra compras para calcular su valor real.',
                          style: TextStyle(
                            fontSize: 12,
                            color: resolverColorEstado(
                              context,
                              ColorEstado.advertencia,
                            ).frente,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
    final asyncCosto = ref.watch(costoProductoProvider(widget.id!));
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
          return _construirFormulario(costo: asyncCosto.asData?.value);
        },
      ),
    );
  }
}
