import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/proveedores_modelos.dart';

abstract class ProveedoresRepositorio {
  Stream<List<Proveedor>> observarActivos({String busqueda = ''});
  Stream<Proveedor?> observarPorId(String id);
  Future<String> crear(ProveedorDatos datos);
  Future<void> actualizar(String id, ProveedorDatos datos);
  Future<void> archivar(String id);
}

class _ProveedoresRepositorioLocal implements ProveedoresRepositorio {
  _ProveedoresRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  String? _limpiar(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  Stream<List<Proveedor>> observarActivos({String busqueda = ''}) {
    final q = busqueda.trim().toLowerCase();
    return _almacen.observar(() {
      final lista =
          _almacen.proveedores.values.where((p) {
            if (p.archivado) return false;
            if (q.isEmpty) return true;
            return p.nombre.toLowerCase().contains(q) ||
                (p.telefono?.toLowerCase().contains(q) ?? false);
          }).toList()..sort(
            (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
          );
      return lista;
    });
  }

  @override
  Stream<Proveedor?> observarPorId(String id) =>
      _almacen.observar(() => _almacen.proveedores[id]);

  @override
  Future<String> crear(ProveedorDatos datos) async {
    if (datos.nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre del proveedor es obligatorio.');
    }
    final id = _almacen.generarId();
    _almacen.proveedores[id] = Proveedor(
      id: id,
      nombre: datos.nombre.trim(),
      telefono: _limpiar(datos.telefono),
      email: _limpiar(datos.email),
      notas: _limpiar(datos.notas),
    );
    _almacen.notificar();
    return id;
  }

  @override
  Future<void> actualizar(String id, ProveedorDatos datos) async {
    if (datos.nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre del proveedor es obligatorio.');
    }
    final actual = _almacen.proveedores[id];
    if (actual == null) {
      throw const ErrorDeNegocio('El proveedor no existe.');
    }
    _almacen.proveedores[id] = Proveedor(
      id: id,
      nombre: datos.nombre.trim(),
      telefono: _limpiar(datos.telefono),
      email: _limpiar(datos.email),
      notas: _limpiar(datos.notas),
      archivadoEn: actual.archivadoEn,
    );
    _almacen.notificar();
  }

  @override
  Future<void> archivar(String id) async {
    final p = _almacen.proveedores[id];
    if (p == null) return;
    _almacen.proveedores[id] = Proveedor(
      id: p.id,
      nombre: p.nombre,
      telefono: p.telefono,
      email: p.email,
      notas: p.notas,
      archivadoEn: DateTime.now(),
    );
    _almacen.notificar();
  }
}

final proveedoresRepositorioProvider = Provider<ProveedoresRepositorio>((ref) {
  return _ProveedoresRepositorioLocal(ref.watch(almacenLocalProvider));
});

final proveedoresProvider = StreamProvider.autoDispose
    .family<List<Proveedor>, String>((ref, busqueda) {
      return ref
          .watch(proveedoresRepositorioProvider)
          .observarActivos(busqueda: busqueda);
    });

final proveedorProvider = StreamProvider.autoDispose.family<Proveedor?, String>(
  (ref, id) {
    return ref.watch(proveedoresRepositorioProvider).observarPorId(id);
  },
);
