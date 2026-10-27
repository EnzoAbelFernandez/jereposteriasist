import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class ProductosListaPantalla extends ConsumerStatefulWidget {
  const ProductosListaPantalla({super.key});

  @override
  ConsumerState<ProductosListaPantalla> createState() =>
      _ProductosListaPantallaState();
}

class _ProductosListaPantallaState
    extends ConsumerState<ProductosListaPantalla> {
  String _busqueda = '';
  CategoriaProducto? _categoria;

  @override
  Widget build(BuildContext context) {
    final asyncProductos = ref.watch(
      productosProvider(
        FiltroProductos(busqueda: _busqueda, categoria: _categoria),
      ),
    );
    final puedeEditar = ref
        .watch(permisosActualesProvider)
        .puede(Modulo.catalogo, NivelPermiso.editar);

    return PantallaBase(
      titulo: 'Catálogo de productos',
      acciones: [
        IconButton(
          tooltip: 'Recetas',
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: () => context.push(Rutas.recetas),
        ),
      ],
      botonFlotante: RequierePermiso(
        modulo: Modulo.catalogo,
        nivel: NivelPermiso.cargar,
        child: FloatingActionButton.extended(
          onPressed: () => context.push(Rutas.productoNuevo),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo producto'),
        ),
      ),
      cuerpo: Column(
        children: [
          CampoBusqueda(
            hint: 'Buscar producto...',
            onChanged: (v) => setState(() => _busqueda = v),
          ),
          ChipsFiltro<CategoriaProducto>(
            opciones: CategoriaProducto.values,
            seleccionados: _categoria != null ? {_categoria!} : {},
            etiqueta: (c) => c.etiqueta,
            multiple: false,
            onChanged: (nuevos) => setState(() {
              _categoria = nuevos.isEmpty ? null : nuevos.first;
            }),
          ),
          Expanded(
            child: ListaAsync<Producto>(
              valor: asyncProductos,
              vacio: const EstadoVacio(
                icono: Icons.cake_outlined,
                mensaje: 'Todavía no hay productos en el catálogo',
              ),
              itemBuilder: (context, p) =>
                  _ProductoTile(producto: p, puedeEditar: puedeEditar),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductoTile extends ConsumerWidget {
  const _ProductoTile({required this.producto, required this.puedeEditar});

  final Producto producto;
  final bool puedeEditar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final asyncCosto = ref.watch(costoProductoProvider(producto.id));
    final costo = asyncCosto.asData?.value;

    final desc = producto.descripcion?.trim();
    final textoSubtitulo = (desc != null && desc.isNotEmpty)
        ? '${producto.categoria.etiqueta} • $desc'
        : producto.categoria.etiqueta;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: tema.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: puedeEditar
            ? () => context.push(Rutas.productoEditar(producto.id))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: tema.colorScheme.primaryContainer,
                    foregroundColor: tema.colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.cake_outlined, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          style: tema.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          textoSubtitulo,
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (producto.precioBase != null)
                        TextoDinero(
                          producto.precioBase!,
                          estilo: tema.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tema.colorScheme.primary,
                          ),
                        )
                      else
                        Text(
                          'Sin precio',
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: tema.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (costo != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 15,
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Costo receta: ${costo.costoUnitario.formatear()}',
                            style: tema.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (costo.margenPorcentaje != null)
                        InsigniaEstado(
                          texto: 'Margen ${costo.margenPorcentaje}%',
                          color: costo.margenPorcentaje! >= 60
                              ? ColorEstado.exito
                              : (costo.margenPorcentaje! >= 40
                                    ? ColorEstado.advertencia
                                    : ColorEstado.peligro),
                        )
                      else if (!costo.tieneCostoCompleto)
                        Text(
                          'Costo parcial',
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: tema.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
