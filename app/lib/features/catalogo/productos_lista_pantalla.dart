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
              itemBuilder: (context, p) {
                final desc = p.descripcion?.trim();
                final textoSubtitulo = (desc != null && desc.isNotEmpty)
                    ? '${p.categoria.etiqueta} • $desc'
                    : p.categoria.etiqueta;

                return ListTile(
                  title: Text(p.nombre),
                  subtitle: Text(
                    textoSubtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: p.precioBase != null
                      ? TextoDinero(p.precioBase!)
                      : null,
                  onTap: puedeEditar
                      ? () => context.push(Rutas.productoEditar(p.id))
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
