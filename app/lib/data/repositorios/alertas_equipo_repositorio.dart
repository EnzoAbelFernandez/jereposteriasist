import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/alertas_equipo_modelos.dart';

abstract class AlertasRepositorio {
  Stream<List<Alerta>> observarTodas();
  Stream<int> observarCantidadNoLeidas();
  Future<void> marcarLeida(String id);
  Future<void> marcarTodasLeidas();
}

abstract class EquipoRepositorio {
  Stream<List<Perfil>> observarPerfiles({bool incluirInactivos = false});
  Stream<Perfil?> observarPerfil(String id);
  Stream<Map<Modulo, NivelPermiso>> observarPermisos(String perfilId);
  Future<void> cambiarPermiso(
    String perfilId,
    Modulo modulo,
    NivelPermiso nivel,
  );
  Future<void> actualizarMiPerfil({required String nombre, String? telefono});
  Future<void> invitarEmpleado({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  });
  Future<void> desactivar(String perfilId);
  Future<void> reactivar(String perfilId);
  Future<void> cambiarRol(String perfilId, Rol rol);
}

abstract class ConfiguracionRepositorio {
  Stream<Configuracion> observar();
  Future<void> actualizar(Configuracion c);
  Future<String> exportarBackupJson();
}

class _AlertasRepositorioLocal implements AlertasRepositorio {
  _AlertasRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  @override
  Stream<List<Alerta>> observarTodas() {
    return _almacen.observar(() {
      final lista = _almacen.alertas.values.toList()
        ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return lista;
    });
  }

  @override
  Stream<int> observarCantidadNoLeidas() {
    return _almacen.observar(
      () => _almacen.alertas.values.where((a) => !a.leida).length,
    );
  }

  @override
  Future<void> marcarLeida(String id) async {
    final a = _almacen.alertas[id];
    if (a == null || a.leida) return;
    final alerta = Alerta(
      id: a.id,
      tipo: a.tipo,
      titulo: a.titulo,
      mensaje: a.mensaje,
      entidadTipo: a.entidadTipo,
      entidadId: a.entidadId,
      leidaEn: DateTime.now(),
      creadoEn: a.creadoEn,
    );
    await _almacen.persistirAlerta(alerta);
  }

  @override
  Future<void> marcarTodasLeidas() async {
    final ahora = DateTime.now();
    for (final e in _almacen.alertas.entries.toList()) {
      final a = e.value;
      if (!a.leida) {
        final alerta = Alerta(
          id: a.id,
          tipo: a.tipo,
          titulo: a.titulo,
          mensaje: a.mensaje,
          entidadTipo: a.entidadTipo,
          entidadId: a.entidadId,
          leidaEn: ahora,
          creadoEn: a.creadoEn,
        );
        await _almacen.persistirAlerta(alerta);
      }
    }
  }
}

class _EquipoRepositorioLocal implements EquipoRepositorio {
  _EquipoRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  @override
  Stream<List<Perfil>> observarPerfiles({bool incluirInactivos = false}) {
    return _almacen.observar(() {
      final lista =
          _almacen.perfiles.values
              .where((p) => incluirInactivos || p.activo)
              .toList()
            ..sort((a, b) {
              if (a.esJefe != b.esJefe) return a.esJefe ? -1 : 1;
              return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
            });
      return lista;
    });
  }

  @override
  Stream<Perfil?> observarPerfil(String id) =>
      _almacen.observar(() => _almacen.perfiles[id]);

  @override
  Stream<Map<Modulo, NivelPermiso>> observarPermisos(String perfilId) {
    return _almacen.observar(() {
      final actual = _almacen.permisos[perfilId] ?? const {};
      return {
        for (final m in Modulo.values) m: actual[m] ?? NivelPermiso.ninguno,
      };
    });
  }

  @override
  Future<void> cambiarPermiso(
    String perfilId,
    Modulo modulo,
    NivelPermiso nivel,
  ) async {
    final perfil = _almacen.perfiles[perfilId];
    if (perfil == null) {
      throw const ErrorDeNegocio('El usuario no existe.');
    }
    if (perfil.esJefe) {
      throw const ErrorDeNegocio(
        'El jefe siempre tiene acceso total a todos los módulos.',
      );
    }
    try {
      final client = Supabase.instance.client;
      await client
          .from('permisos')
          .update({'nivel': nivel.valor})
          .eq('perfil_id', perfilId)
          .eq('modulo', modulo.valor)
          .select('id')
          .single();
      final mapa = Map<Modulo, NivelPermiso>.of(
        _almacen.permisos[perfilId] ?? {},
      );
      mapa[modulo] = nivel;
      _almacen.permisos[perfilId] = mapa;
      _almacen.notificar();
    } catch (_) {
      throw const ErrorDeNegocio(
        'No pudimos guardar el permiso. Revisá la conexión y volvé a intentar.',
      );
    }
  }

  @override
  Future<void> actualizarMiPerfil({
    required String nombre,
    String? telefono,
  }) async {
    if (nombre.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre es obligatorio.');
    }
    final uid = _almacen.usuarioActualId;
    if (uid == null || !_almacen.perfiles.containsKey(uid)) return;
    final actual = _almacen.perfiles[uid]!;
    _almacen.perfiles[uid] = Perfil(
      id: actual.id,
      nombre: nombre.trim(),
      rol: actual.rol,
      telefono: telefono?.trim().isEmpty == true ? null : telefono?.trim(),
      activo: actual.activo,
    );
    _almacen.notificar();
  }

  @override
  Future<void> invitarEmpleado({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  }) async {
    if (!_almacen.conectadoAInternet) {
      throw const SinConexion();
    }
    if (nombre.trim().isEmpty || email.trim().isEmpty) {
      throw const ErrorDeNegocio('Completá el nombre y el email.');
    }
    if (password.length < 8) {
      throw const ErrorDeNegocio(
        'La contraseña debe tener al menos 8 caracteres.',
      );
    }
    try {
      final client = Supabase.instance.client;
      final respuesta = await client.functions.invoke(
        'crear-empleado',
        body: {
          'nombre': nombre.trim(),
          'email': email.trim(),
          'password': password,
          'telefono': telefono,
        },
      );
      final resultado = respuesta.data;
      if (resultado is! Map || resultado['id'] is! String) {
        throw const ErrorDeNegocio(
          'No pudimos confirmar la creación de la cuenta.',
        );
      }
      final id = resultado['id'] as String;
      _almacen.perfiles[id] = Perfil(
        id: id,
        nombre: nombre.trim(),
        rol: Rol.empleado,
        telefono: resultado['telefono_guardado'] == true ? telefono : null,
      );
      _almacen.permisos[id] = {
        for (final m in Modulo.values) m: NivelPermiso.ninguno,
      };
      _almacen.notificar();
      if (resultado['telefono_guardado'] == false) {
        throw const ErrorDeNegocio(
          'La cuenta se creó, pero no se pudo guardar el teléfono.',
        );
      }
    } on ErrorDeNegocio {
      rethrow;
    } on FunctionException catch (e) {
      final detalle = e.details;
      throw ErrorDeNegocio(
        detalle is Map && detalle['error'] is String
            ? detalle['error'] as String
            : 'No pudimos crear la cuenta. Revisá la conexión y volvé a intentar.',
      );
    } catch (_) {
      throw const ErrorDeNegocio(
        'No pudimos confirmar la creación. Revisá el equipo antes de reintentar.',
      );
    }
  }

  @override
  Future<void> desactivar(String perfilId) async {
    if (!_almacen.conectadoAInternet) {
      throw const SinConexion();
    }
    final p = _almacen.perfiles[perfilId];
    if (p == null) return;
    if (p.esJefe) {
      throw const ErrorDeNegocio('No se puede desactivar al jefe.');
    }
    _almacen.perfiles[perfilId] = Perfil(
      id: p.id,
      nombre: p.nombre,
      rol: p.rol,
      telefono: p.telefono,
      activo: false,
    );
    _almacen.permisos[perfilId] = {
      for (final m in Modulo.values) m: NivelPermiso.ninguno,
    };
    _almacen.notificar();
  }

  @override
  Future<void> reactivar(String perfilId) async {
    if (!_almacen.conectadoAInternet) {
      throw const SinConexion();
    }
    final p = _almacen.perfiles[perfilId];
    if (p == null) return;
    _almacen.perfiles[perfilId] = Perfil(
      id: p.id,
      nombre: p.nombre,
      rol: p.rol,
      telefono: p.telefono,
      activo: true,
    );
    _almacen.notificar();
  }

  @override
  Future<void> cambiarRol(String perfilId, Rol rol) async {
    final p = _almacen.perfiles[perfilId];
    if (p == null) {
      throw const ErrorDeNegocio('El usuario no existe.');
    }
    if (perfilId == _almacen.usuarioActualId) {
      throw const ErrorDeNegocio('No podés cambiar tu propio rol.');
    }
    try {
      final client = Supabase.instance.client;
      await client
          .from('perfiles')
          .update({'rol': rol.valor})
          .eq('id', perfilId)
          .select('id')
          .single();
    } catch (_) {
      throw const ErrorDeNegocio(
        'No pudimos guardar el rol. Revisá la conexión y volvé a intentar.',
      );
    }
    _almacen.perfiles[perfilId] = Perfil(
      id: p.id,
      nombre: p.nombre,
      rol: rol,
      telefono: p.telefono,
      activo: p.activo,
    );
    _almacen.permisos[perfilId] = {
      for (final m in Modulo.values)
        m: rol == Rol.jefe ? NivelPermiso.editar : NivelPermiso.ninguno,
    };
    _almacen.notificar();
  }
}

class _ConfiguracionRepositorioLocal implements ConfiguracionRepositorio {
  _ConfiguracionRepositorioLocal(this._almacen);
  final AlmacenLocal _almacen;

  @override
  Stream<Configuracion> observar() =>
      _almacen.observar(() => _almacen.configuracion);

  @override
  Future<void> actualizar(Configuracion c) async {
    if (c.nombreNegocio.trim().isEmpty) {
      throw const ErrorDeNegocio('El nombre del negocio es obligatorio.');
    }
    if (c.diasAvisoCumple < 1 || c.diasAvisoCumple > 60) {
      throw const ErrorDeNegocio(
        'Los días de anticipación deben estar entre 1 y 60.',
      );
    }
    if (c.habitualMinPedidos < 1 || c.habitualMeses < 1) {
      throw const ErrorDeNegocio('Los valores deben ser mayores a cero.');
    }
    final nueva = c.copyWith(nombreNegocio: c.nombreNegocio.trim());
    await _almacen.persistirConfiguracion(nueva);
  }

  @override
  Future<String> exportarBackupJson() async {
    final mapa = {
      'exportado_en': DateTime.now().toIso8601String(),
      'configuracion': {
        'nombre_negocio': _almacen.configuracion.nombreNegocio,
        'dias_aviso_cumple': _almacen.configuracion.diasAvisoCumple,
        'aviso_cumple_alcance': _almacen.configuracion.avisoCumpleAlcance.name,
        'habitual_min_pedidos': _almacen.configuracion.habitualMinPedidos,
        'habitual_meses': _almacen.configuracion.habitualMeses,
      },
      'totales': {
        'clientes': _almacen.clientes.length,
        'proveedores': _almacen.proveedores.length,
        'insumos': _almacen.insumos.length,
        'productos': _almacen.productos.length,
        'recetas': _almacen.recetas.length,
        'pedidos': _almacen.pedidos.length,
        'compras': _almacen.compras.length,
        'gastos': _almacen.gastos.length,
        'producciones': _almacen.producciones.length,
        'movimientos_stock': _almacen.movimientosStock.length,
        'movimientos_caja': _almacen.movimientosCaja.length,
        'tareas': _almacen.tareas.length,
      },
      'clientes': [
        for (final c in _almacen.clientes.values)
          {
            'id': c.id,
            'nombre': c.nombre,
            'telefono': c.telefono,
            'email': c.email,
            'direccion': c.direccion,
            'cumple_dia': c.cumpleDia,
            'cumple_mes': c.cumpleMes,
            'cumple_anio': c.cumpleAnio,
            'habitual_modo': c.habitualModo.name,
            'es_habitual': c.esHabitual,
            'archivado': c.archivado,
          },
      ],
      'proveedores': [
        for (final p in _almacen.proveedores.values)
          {
            'id': p.id,
            'nombre': p.nombre,
            'telefono': p.telefono,
            'email': p.email,
            'archivado': p.archivado,
          },
      ],
      'insumos': [
        for (final i in _almacen.insumos.values)
          {
            'id': i.id,
            'nombre': i.nombre,
            'unidad': i.unidad.valor,
            'stock_minimo': i.stockMinimo,
            'stock_actual': _almacen.stockDe(i.id),
            'categoria': i.categoria,
            'archivado': i.archivado,
          },
      ],
      'productos': [
        for (final p in _almacen.productos.values)
          {
            'id': p.id,
            'nombre': p.nombre,
            'categoria': p.categoria.name,
            'precio_base_centavos': p.precioBase?.centavos,
            'archivado': p.archivado,
          },
      ],
      'pedidos': [
        for (final p in _almacen.pedidos.values)
          {
            'id': p.id,
            'numero': p.numero,
            'cliente_id': p.clienteId,
            'fecha_entrega': p.fechaEntrega.toIso8601String(),
            'tipo_entrega': p.tipoEntrega.name,
            'estado': p.estado.name,
            'descuento_centavos': p.descuento.centavos,
          },
      ],
      'movimientos_caja': [
        for (final m in _almacen.movimientosCaja.values)
          {
            'id': m.id,
            'fecha': m.fecha.toIso8601String(),
            'tipo': m.tipo.name,
            'monto_centavos': m.monto.centavos,
            'medio_pago': m.medioPago.name,
            'concepto': m.concepto.name,
            'descripcion': m.descripcionTexto,
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(mapa);
  }
}

final alertasRepositorioProvider = Provider<AlertasRepositorio>((ref) {
  return _AlertasRepositorioLocal(ref.watch(almacenLocalProvider));
});

final alertasProvider = StreamProvider.autoDispose<List<Alerta>>((ref) {
  return ref.watch(alertasRepositorioProvider).observarTodas();
});

final cantidadAlertasNoLeidasProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(alertasRepositorioProvider).observarCantidadNoLeidas();
});

final equipoRepositorioProvider = Provider<EquipoRepositorio>((ref) {
  return _EquipoRepositorioLocal(ref.watch(almacenLocalProvider));
});

final perfilesProvider = StreamProvider.autoDispose.family<List<Perfil>, bool>((
  ref,
  incluirInactivos,
) {
  return ref
      .watch(equipoRepositorioProvider)
      .observarPerfiles(incluirInactivos: incluirInactivos);
});

final perfilProvider = StreamProvider.autoDispose.family<Perfil?, String>((
  ref,
  id,
) {
  return ref.watch(equipoRepositorioProvider).observarPerfil(id);
});

final permisosDePerfilProvider = StreamProvider.autoDispose
    .family<Map<Modulo, NivelPermiso>, String>((ref, perfilId) {
      return ref.watch(equipoRepositorioProvider).observarPermisos(perfilId);
    });

final configuracionRepositorioProvider = Provider<ConfiguracionRepositorio>((
  ref,
) {
  return _ConfiguracionRepositorioLocal(ref.watch(almacenLocalProvider));
});

final configuracionProvider = StreamProvider.autoDispose<Configuracion>((ref) {
  return ref.watch(configuracionRepositorioProvider).observar();
});
