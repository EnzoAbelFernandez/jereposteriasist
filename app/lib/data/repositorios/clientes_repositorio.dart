import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/formato/fechas.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/clientes_modelos.dart';

abstract class ClientesRepositorio {
  Stream<List<Cliente>> observarActivos({String busqueda = ''});
  Stream<List<Cliente>> observarArchivados();
  Stream<Cliente?> observarPorId(String id);
  Stream<List<ClienteConCumple>> observarProximosCumpleanos({int dias = 7});
  Future<String> crear(ClienteDatos datos);
  Future<void> actualizar(String id, ClienteDatos datos);
  Future<void> archivar(String id);
  Future<void> desarchivar(String id);
}

class _ClientesRepositorioLocal implements ClientesRepositorio {
  _ClientesRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  @override
  Stream<List<Cliente>> observarActivos({String busqueda = ''}) {
    final q = busqueda.trim().toLowerCase();
    return _almacen.observar(() {
      final lista =
          _almacen.clientes.values.where((c) {
            if (c.archivado) return false;
            if (q.isEmpty) return true;
            return c.nombre.toLowerCase().contains(q) ||
                (c.telefono?.toLowerCase().contains(q) ?? false);
          }).toList()..sort(
            (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
          );
      return lista;
    });
  }

  @override
  Stream<List<Cliente>> observarArchivados() {
    return _almacen.observar(() {
      final lista = _almacen.clientes.values.where((c) => c.archivado).toList()
        ..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        );
      return lista;
    });
  }

  @override
  Stream<Cliente?> observarPorId(String id) {
    return _almacen.observar(() => _almacen.clientes[id]);
  }

  @override
  Stream<List<ClienteConCumple>> observarProximosCumpleanos({int dias = 7}) {
    return _almacen.observar(() {
      final base = hoy();
      final cfg = _almacen.configuracion;
      final res = <ClienteConCumple>[];
      for (final c in _almacen.clientes.values) {
        if (c.archivado || !c.tieneCumple) continue;
        if (cfg.avisoCumpleAlcance == AlcanceAvisoCumple.habituales &&
            !c.esHabitual) {
          continue;
        }
        final prox = c.proximoCumple(base)!;
        final faltan = prox.difference(base).inDays;
        if (faltan >= 0 && faltan <= dias) {
          res.add(ClienteConCumple(cliente: c, fecha: prox, dias: faltan));
        }
      }
      res.sort((a, b) => a.dias.compareTo(b.dias));
      return res;
    });
  }

  void _validar(ClienteDatos d) {
    if (d.nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre del cliente es obligatorio.');
    }
    if ((d.cumpleDia == null) != (d.cumpleMes == null)) {
      throw const ErrorDeNegocio(
        'Completá tanto el día como el mes del cumpleaños.',
      );
    }
  }

  String? _limpiar(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  Future<String> crear(ClienteDatos datos) async {
    _validar(datos);
    final id = _almacen.generarId();
    final cliente = Cliente(
      id: id,
      nombre: datos.nombre.trim(),
      telefono: _limpiar(datos.telefono),
      email: _limpiar(datos.email),
      direccion: _limpiar(datos.direccion),
      cumpleDia: datos.cumpleDia,
      cumpleMes: datos.cumpleMes,
      cumpleAnio: datos.cumpleAnio,
      preferencias: _limpiar(datos.preferencias),
      alergias: _limpiar(datos.alergias),
      notas: _limpiar(datos.notas),
      habitualModo: datos.habitualModo,
      creadoEn: DateTime.now(),
    );
    await _almacen.persistirCliente(cliente);
    return id;
  }

  @override
  Future<void> actualizar(String id, ClienteDatos datos) async {
    _validar(datos);
    final actual = _almacen.clientes[id];
    if (actual == null) {
      throw const ErrorDeNegocio('El cliente no existe.');
    }
    final actualizado = Cliente(
      id: id,
      nombre: datos.nombre.trim(),
      telefono: _limpiar(datos.telefono),
      email: _limpiar(datos.email),
      direccion: _limpiar(datos.direccion),
      cumpleDia: datos.cumpleDia,
      cumpleMes: datos.cumpleMes,
      cumpleAnio: datos.cumpleAnio,
      preferencias: _limpiar(datos.preferencias),
      alergias: _limpiar(datos.alergias),
      notas: _limpiar(datos.notas),
      habitualModo: datos.habitualModo,
      habitualAuto: actual.habitualAuto,
      archivadoEn: actual.archivadoEn,
      creadoEn: actual.creadoEn,
    );
    await _almacen.persistirCliente(actualizado);
  }

  @override
  Future<void> archivar(String id) async {
    final c = _almacen.clientes[id];
    if (c == null) return;
    final archivado = Cliente(
      id: c.id,
      nombre: c.nombre,
      telefono: c.telefono,
      email: c.email,
      direccion: c.direccion,
      cumpleDia: c.cumpleDia,
      cumpleMes: c.cumpleMes,
      cumpleAnio: c.cumpleAnio,
      preferencias: c.preferencias,
      alergias: c.alergias,
      notas: c.notas,
      habitualModo: c.habitualModo,
      habitualAuto: c.habitualAuto,
      archivadoEn: DateTime.now(),
      creadoEn: c.creadoEn,
    );
    await _almacen.persistirCliente(archivado);
  }

  @override
  Future<void> desarchivar(String id) async {
    final c = _almacen.clientes[id];
    if (c == null) return;
    final desarchivado = Cliente(
      id: c.id,
      nombre: c.nombre,
      telefono: c.telefono,
      email: c.email,
      direccion: c.direccion,
      cumpleDia: c.cumpleDia,
      cumpleMes: c.cumpleMes,
      cumpleAnio: c.cumpleAnio,
      preferencias: c.preferencias,
      alergias: c.alergias,
      notas: c.notas,
      habitualModo: c.habitualModo,
      habitualAuto: c.habitualAuto,
      creadoEn: c.creadoEn,
    );
    await _almacen.persistirCliente(desarchivado);
  }
}

final clientesRepositorioProvider = Provider<ClientesRepositorio>((ref) {
  return _ClientesRepositorioLocal(ref.watch(almacenLocalProvider));
});

final clientesProvider = StreamProvider.autoDispose
    .family<List<Cliente>, String>((ref, busqueda) {
      return ref
          .watch(clientesRepositorioProvider)
          .observarActivos(busqueda: busqueda);
    });

final clientesArchivadosProvider = StreamProvider.autoDispose<List<Cliente>>((
  ref,
) {
  return ref.watch(clientesRepositorioProvider).observarArchivados();
});

final clienteProvider = StreamProvider.autoDispose.family<Cliente?, String>((
  ref,
  id,
) {
  return ref.watch(clientesRepositorioProvider).observarPorId(id);
});

final proximosCumpleanosProvider =
    StreamProvider.autoDispose<List<ClienteConCumple>>((ref) {
      final almacen = ref.watch(almacenLocalProvider);
      final repo = ref.watch(clientesRepositorioProvider);
      return repo.observarProximosCumpleanos(
        dias: almacen.configuracion.diasAvisoCumple,
      );
    });
