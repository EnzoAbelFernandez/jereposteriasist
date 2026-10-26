import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/data/modelos/alertas_equipo_modelos.dart';
import 'package:jereposteria/data/modelos/caja_modelos.dart';
import 'package:jereposteria/data/modelos/clientes_modelos.dart';
import 'package:jereposteria/data/modelos/compras_modelos.dart';
import 'package:jereposteria/data/modelos/gastos_modelos.dart';
import 'package:jereposteria/data/modelos/pedidos_modelos.dart';
import 'package:jereposteria/data/modelos/produccion_modelos.dart';
import 'package:jereposteria/data/modelos/productos_modelos.dart';
import 'package:jereposteria/data/modelos/proveedores_modelos.dart';
import 'package:jereposteria/data/modelos/recetas_reportes_modelos.dart';
import 'package:jereposteria/data/modelos/stock_modelos.dart';
import 'package:jereposteria/data/modelos/tareas_modelos.dart';
import 'package:uuid/uuid.dart';

/// Almacén reactivo local que respalda los repositorios y emite cambios en tiempo real.
///
/// Todas las operaciones de los repositorios pasan por acá (y se sincronizan con PowerSync).
class AlmacenLocal {
  AlmacenLocal({String? usuarioActualId, bool inicializarDatosBase = true})
    : _usuarioActualId = usuarioActualId ?? idJefeLocal {
    if (inicializarDatosBase) {
      _sembrarBase();
    }
  }

  static const String idJefeLocal = '00000000-0000-4000-8000-000000000001';
  static const Uuid _uuid = Uuid();

  String generarId() => _uuid.v4();

  String? _usuarioActualId;
  String? get usuarioActualId => _usuarioActualId;
  set usuarioActualId(String? valor) {
    _usuarioActualId = valor;
    notificar();
  }

  bool conectadoAInternet = true;

  Configuracion configuracion = const Configuracion();
  final Map<String, Perfil> perfiles = {};
  final Map<String, Map<Modulo, NivelPermiso>> permisos = {};
  final Map<String, Cliente> clientes = {};
  final Map<String, Proveedor> proveedores = {};
  final Map<String, Insumo> insumos = {};
  final Map<String, Producto> productos = {};
  final Map<String, Receta> recetas = {};
  final Map<String, List<RecetaItem>> recetaItems = {};
  final Map<String, Pedido> pedidos = {};
  final Map<String, List<PedidoItem>> pedidoItems = {};
  final Map<String, Compra> compras = {};
  final Map<String, List<CompraItem>> compraItems = {};
  final Map<String, CategoriaGasto> categoriasGasto = {};
  final Map<String, Gasto> gastos = {};
  final Map<String, Produccion> producciones = {};
  final Map<String, MovimientoStock> movimientosStock = {};
  final Map<String, MovimientoCaja> movimientosCaja = {};
  final Map<String, Tarea> tareas = {};
  final Map<String, Alerta> alertas = {};

  final StreamController<void> _cambios = StreamController<void>.broadcast();

  void notificar() {
    if (!_cambios.isClosed) {
      _cambios.add(null);
    }
  }

  /// Crea un `Stream<T>` que emite el valor actual inmediatamente y vuelve a emitir
  /// cada vez que cambia el almacén.
  Stream<T> observar<T>(T Function() calcular) {
    return Stream<T>.multi((controller) {
      controller.addSync(calcular());
      final sub = _cambios.stream.listen((_) {
        if (!controller.isClosed) {
          controller.add(calcular());
        }
      });
      controller.onCancel = sub.cancel;
    });
  }

  String? nombreDePerfil(String? id) =>
      id == null ? null : perfiles[id]?.nombre;

  void _sembrarBase() {
    perfiles[idJefeLocal] = const Perfil(
      id: idJefeLocal,
      nombre: 'Jere',
      rol: Rol.jefe,
      activo: true,
    );
    permisos[idJefeLocal] = {
      for (final m in Modulo.values) m: NivelPermiso.editar,
    };

    const iniciales = [
      'Alquiler',
      'Servicios (luz, gas, agua, internet)',
      'Packaging y descartables',
      'Envíos y transporte',
      'Mantenimiento y equipamiento',
      'Impuestos y monotributo',
      'Sueldos',
      'Publicidad',
      'Otros',
    ];
    for (var i = 0; i < iniciales.length; i++) {
      final id = '00000000-0000-4000-8000-00000000010${i + 1}';
      categoriasGasto[id] = CategoriaGasto(id: id, nombre: iniciales[i]);
    }
  }

  /// Recalcula `habitualAuto` según `configuracion.habitualMinPedidos` y `habitualMeses`.
  void recalcularHabitual(String clienteId, {DateTime? ahora}) {
    final c = clientes[clienteId];
    if (c == null) return;
    final ref = ahora ?? DateTime.now();
    final corte = DateTime(
      ref.year,
      ref.month - configuracion.habitualMeses,
      ref.day,
    );
    final entregadosRecientes = pedidos.values.where((p) {
      if (p.clienteId != clienteId || p.estado != EstadoPedido.entregado) {
        return false;
      }
      final fecha = p.entregadoEn ?? p.fechaEntrega;
      return !fecha.isBefore(corte);
    }).length;
    final nuevoAuto = entregadosRecientes >= configuracion.habitualMinPedidos;
    if (c.habitualAuto != nuevoAuto) {
      clientes[clienteId] = Cliente(
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
        habitualAuto: nuevoAuto,
        archivadoEn: c.archivadoEn,
        creadoEn: c.creadoEn,
      );
    }
  }

  void recalcularTodosLosHabituales({DateTime? ahora}) {
    for (final id in clientes.keys.toList()) {
      recalcularHabitual(id, ahora: ahora);
    }
  }

  int stockDe(String insumoId) {
    var suma = 0;
    for (final m in movimientosStock.values) {
      if (m.insumoId == insumoId) {
        suma += m.cantidad;
      }
    }
    return suma;
  }

  void evaluarAlertaStockBajo(String insumoId) {
    final insumo = insumos[insumoId];
    if (insumo == null || insumo.archivado || insumo.stockMinimo <= 0) return;
    final actual = stockDe(insumoId);
    if (actual >= insumo.stockMinimo) return;
    final hoyTxt = DateTime.now().toIso8601String().substring(0, 10);
    final clave = 'stock_bajo:$insumoId:$hoyTxt';
    final yaExiste = alertas.values.any((a) => a.id == clave);
    if (yaExiste) return;
    alertas[clave] = Alerta(
      id: clave,
      tipo: TipoAlerta.stockBajo,
      titulo: 'Falta ${insumo.nombre}',
      mensaje:
          'Quedan ${insumo.unidad.formatear(actual)} (mínimo ${insumo.unidad.formatear(insumo.stockMinimo)}).',
      entidadTipo: 'insumo',
      entidadId: insumo.id,
      creadoEn: DateTime.now(),
    );
  }

  void dispose() {
    _cambios.close();
  }
}

final almacenLocalProvider = Provider<AlmacenLocal>((ref) {
  final almacen = AlmacenLocal();
  ref.onDispose(almacen.dispose);
  return almacen;
});
