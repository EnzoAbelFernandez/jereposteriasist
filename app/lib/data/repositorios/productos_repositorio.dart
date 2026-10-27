import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/productos_modelos.dart';

abstract class ProductosRepositorio {
  Stream<List<Producto>> observarActivos({
    String busqueda = '',
    CategoriaProducto? categoria,
  });
  Stream<Producto?> observarPorId(String id);
  Future<String> crear(ProductoDatos datos);
  Future<void> actualizar(String id, ProductoDatos datos);
  Future<void> archivar(String id);
}

class _ProductosRepositorioLocal implements ProductosRepositorio {
  _ProductosRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  String? _limpiar(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  Stream<List<Producto>> observarActivos({
    String busqueda = '',
    CategoriaProducto? categoria,
  }) {
    final q = busqueda.trim().toLowerCase();
    return _almacen.observar(() {
      final lista =
          _almacen.productos.values.where((p) {
            if (p.archivado) return false;
            if (categoria != null && p.categoria != categoria) return false;
            if (q.isEmpty) return true;
            return p.nombre.toLowerCase().contains(q) ||
                (p.descripcion?.toLowerCase().contains(q) ?? false);
          }).toList()..sort(
            (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
          );
      return lista;
    });
  }

  @override
  Stream<Producto?> observarPorId(String id) =>
      _almacen.observar(() => _almacen.productos[id]);

  @override
  Future<String> crear(ProductoDatos datos) async {
    if (datos.nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre del producto es obligatorio.');
    }
    if (datos.precioBase != null && datos.precioBase!.esNegativo) {
      throw const ErrorDeNegocio('El precio no puede ser negativo.');
    }
    final id = _almacen.generarId();
    final producto = Producto(
      id: id,
      nombre: datos.nombre.trim(),
      categoria: datos.categoria,
      precioBase: datos.precioBase,
      descripcion: _limpiar(datos.descripcion),
    );
    await _almacen.persistirProducto(producto);
    return id;
  }

  @override
  Future<void> actualizar(String id, ProductoDatos datos) async {
    if (datos.nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre del producto es obligatorio.');
    }
    final actual = _almacen.productos[id];
    if (actual == null) {
      throw const ErrorDeNegocio('El producto no existe.');
    }
    final actualizado = Producto(
      id: id,
      nombre: datos.nombre.trim(),
      categoria: datos.categoria,
      precioBase: datos.precioBase,
      descripcion: _limpiar(datos.descripcion),
      archivadoEn: actual.archivadoEn,
    );
    await _almacen.persistirProducto(actualizado);
  }

  @override
  Future<void> archivar(String id) async {
    final p = _almacen.productos[id];
    if (p == null) return;
    final archivado = Producto(
      id: p.id,
      nombre: p.nombre,
      categoria: p.categoria,
      precioBase: p.precioBase,
      descripcion: p.descripcion,
      archivadoEn: DateTime.now(),
    );
    await _almacen.persistirProducto(archivado);
  }
}

final productosRepositorioProvider = Provider<ProductosRepositorio>((ref) {
  return _ProductosRepositorioLocal(ref.watch(almacenLocalProvider));
});

final productosProvider = StreamProvider.autoDispose
    .family<List<Producto>, FiltroProductos>((ref, filtro) {
      return ref
          .watch(productosRepositorioProvider)
          .observarActivos(
            busqueda: filtro.busqueda,
            categoria: filtro.categoria,
          );
    });

final productoProvider = StreamProvider.autoDispose.family<Producto?, String>((
  ref,
  id,
) {
  return ref.watch(productosRepositorioProvider).observarPorId(id);
});
