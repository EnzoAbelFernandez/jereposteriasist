import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';
import 'package:jereposteria/core/notificaciones/notificaciones_push.dart';
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
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

/// Almacén reactivo local que respalda los repositorios y sincroniza en tiempo real con PowerSync.
class AlmacenLocal extends ChangeNotifier {
  AlmacenLocal({
    String? usuarioActualId,
    bool inicializarDatosBase = true,
    this.db,
  }) : _usuarioActualId = usuarioActualId ?? idJefeLocal {
    if (inicializarDatosBase) {
      _sembrarBase();
    }
  }

  static const String idJefeLocal = '00000000-0000-4000-8000-000000000001';
  static const Uuid _uuid = Uuid();

  String generarId() => _uuid.v4();

  final PowerSyncDatabase? db;

  String? _usuarioActualId;
  String? get usuarioActualId => _usuarioActualId;
  set usuarioActualId(String? valor) {
    _usuarioActualId = valor;
    if (valor != null && !perfiles.containsKey(valor)) {
      perfiles[valor] = Perfil(
        id: valor,
        nombre: valor == idJefeLocal ? 'Jere' : 'Usuario',
        rol: Rol.jefe,
        activo: true,
      );
      permisos.putIfAbsent(
        valor,
        () => {for (final m in Modulo.values) m: NivelPermiso.editar},
      );
    }
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
  final List<StreamSubscription> _subscriptions = [];

  void notificar() {
    if (!_cambios.isClosed) {
      _cambios.add(null);
    }
    notifyListeners();
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

  /// Conecta el almacén a los streams reactivos de SQLite mediante PowerSync.
  Future<void> vincularPowerSync(PowerSyncDatabase base) async {
    _subscriptions.add(
      base.statusStream.listen((status) {
        conectadoAInternet = status.connected;
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM configuracion LIMIT 1').listen((rows) {
        if (rows.isEmpty) return;
        final r = rows.first;
        configuracion = Configuracion(
          nombreNegocio: (r['nombre_negocio'] as String?) ?? 'Mi repostería',
          diasAvisoCumple: (r['dias_aviso_cumple'] as num?)?.toInt() ?? 7,
          avisoCumpleAlcance: AlcanceAvisoCumple.desdeValor(
            (r['aviso_cumple_alcance'] as String?) ?? 'todos',
          ),
          habitualMinPedidos: (r['habitual_min_pedidos'] as num?)?.toInt() ?? 3,
          habitualMeses: (r['habitual_meses'] as num?)?.toInt() ?? 12,
        );
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM perfiles').listen((rows) {
        for (final r in rows) {
          final p = Perfil(
            id: r['id'] as String,
            nombre: r['nombre'] as String,
            rol: Rol.desdeValor(r['rol'] as String? ?? 'empleado'),
            telefono: r['telefono'] as String?,
            activo: (r['activo'] == 1 || r['activo'] == true),
          );
          perfiles[p.id] = p;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM permisos').listen((rows) {
        for (final r in rows) {
          final perfilId = r['perfil_id'] as String;
          final modulo = Modulo.desdeValor(r['modulo'] as String);
          final nivel = NivelPermiso.desdeValor(r['nivel'] as String);
          permisos.putIfAbsent(perfilId, () => {})[modulo] = nivel;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM insumos').listen((rows) {
        insumos.clear();
        for (final r in rows) {
          final i = Insumo(
            id: r['id'] as String,
            nombre: r['nombre'] as String,
            unidad: Unidad.desdeValor(r['unidad'] as String),
            stockMinimo: (r['stock_minimo'] as num?)?.toInt() ?? 0,
            categoria: r['categoria'] as String?,
            notas: r['notas'] as String?,
            archivadoEn: r['archivado_en'] != null
                ? DateTime.tryParse(r['archivado_en'] as String)
                : null,
          );
          insumos[i.id] = i;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM clientes').listen((rows) {
        clientes.clear();
        for (final r in rows) {
          final c = Cliente(
            id: r['id'] as String,
            nombre: r['nombre'] as String,
            telefono: r['telefono'] as String?,
            email: r['email'] as String?,
            direccion: r['direccion'] as String?,
            cumpleDia: (r['cumple_dia'] as num?)?.toInt(),
            cumpleMes: (r['cumple_mes'] as num?)?.toInt(),
            cumpleAnio: (r['cumple_anio'] as num?)?.toInt(),
            preferencias: r['preferencias'] as String?,
            alergias: r['alergias'] as String?,
            notas: r['notas'] as String?,
            habitualModo: HabitualModo.desdeValor(
              (r['habitual_modo'] as String?) ?? 'auto',
            ),
            habitualAuto:
                (r['habitual_auto'] == 1 || r['habitual_auto'] == true),
            archivadoEn: r['archivado_en'] != null
                ? DateTime.tryParse(r['archivado_en'] as String)
                : null,
            creadoEn:
                DateTime.tryParse((r['creado_en'] as String?) ?? '') ??
                DateTime.now(),
          );
          clientes[c.id] = c;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM proveedores').listen((rows) {
        proveedores.clear();
        for (final r in rows) {
          final p = Proveedor(
            id: r['id'] as String,
            nombre: r['nombre'] as String,
            telefono: r['telefono'] as String?,
            email: r['email'] as String?,
            notas: r['notas'] as String?,
            archivadoEn: r['archivado_en'] != null
                ? DateTime.tryParse(r['archivado_en'] as String)
                : null,
          );
          proveedores[p.id] = p;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM productos').listen((rows) {
        productos.clear();
        for (final r in rows) {
          final p = Producto(
            id: r['id'] as String,
            nombre: r['nombre'] as String,
            categoria: CategoriaProducto.desdeValor(
              (r['categoria'] as String?) ?? 'torta',
            ),
            precioBase: r['precio_base_centavos'] != null
                ? Dinero((r['precio_base_centavos'] as num).toInt())
                : null,
            descripcion: r['descripcion'] as String?,
            archivadoEn: r['archivado_en'] != null
                ? DateTime.tryParse(r['archivado_en'] as String)
                : null,
          );
          productos[p.id] = p;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM recetas').listen((rows) {
        recetas.clear();
        for (final r in rows) {
          final rec = Receta(
            id: r['id'] as String,
            nombre: r['nombre'] as String,
            productoId: r['producto_id'] as String?,
            rindeCantidad: (r['rinde_cantidad'] as num?)?.toInt() ?? 1,
            rindeDescripcion: r['rinde_descripcion'] as String?,
            notas: r['notas'] as String?,
            archivadoEn: r['archivado_en'] != null
                ? DateTime.tryParse(r['archivado_en'] as String)
                : null,
          );
          recetas[rec.id] = rec;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM receta_items').listen((rows) {
        recetaItems.clear();
        for (final r in rows) {
          final item = RecetaItem(
            id: r['id'] as String,
            recetaId: r['receta_id'] as String,
            insumoId: r['insumo_id'] as String,
            cantidad: (r['cantidad'] as num).toInt(),
          );
          recetaItems.putIfAbsent(item.recetaId, () => []).add(item);
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM pedidos').listen((rows) {
        pedidos.clear();
        for (final r in rows) {
          final ped = Pedido(
            id: r['id'] as String,
            numero: (r['numero'] as num?)?.toInt(),
            clienteId: r['cliente_id'] as String,
            fechaEntrega:
                DateTime.tryParse(r['fecha_entrega'] as String? ?? '') ??
                DateTime.now(),
            tipoEntrega: TipoEntrega.desdeValor(
              (r['tipo_entrega'] as String?) ?? 'retira',
            ),
            direccionEntrega: r['direccion_entrega'] as String?,
            estado: EstadoPedido.desdeValor(
              (r['estado'] as String?) ?? 'confirmado',
            ),
            descuento: Dinero((r['descuento_centavos'] as num?)?.toInt() ?? 0),
            motivoDescuento: r['motivo_descuento'] as String?,
            notas: r['notas'] as String?,
            entregadoEn: r['entregado_en'] != null
                ? DateTime.tryParse(r['entregado_en'] as String)
                : null,
            canceladoEn: r['cancelado_en'] != null
                ? DateTime.tryParse(r['cancelado_en'] as String)
                : null,
            motivoCancelacion: r['motivo_cancelacion'] as String?,
            creadoEn:
                DateTime.tryParse(r['creado_en'] as String? ?? '') ??
                DateTime.now(),
          );
          pedidos[ped.id] = ped;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM pedido_items ORDER BY orden ASC').listen((
        rows,
      ) {
        pedidoItems.clear();
        for (final r in rows) {
          final item = PedidoItem(
            id: r['id'] as String,
            pedidoId: r['pedido_id'] as String,
            productoId: r['producto_id'] as String?,
            descripcion: (r['descripcion'] as String?) ?? '',
            cantidad: (r['cantidad'] as num?)?.toInt() ?? 1,
            precioUnitario: Dinero(
              (r['precio_unitario_centavos'] as num?)?.toInt() ?? 0,
            ),
            notas: r['notas'] as String?,
            orden: (r['orden'] as num?)?.toInt() ?? 0,
          );
          pedidoItems.putIfAbsent(item.pedidoId, () => []).add(item);
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM compras').listen((rows) {
        compras.clear();
        for (final r in rows) {
          final c = Compra(
            id: r['id'] as String,
            proveedorId: r['proveedor_id'] as String?,
            fecha:
                DateTime.tryParse(r['fecha'] as String? ?? '') ??
                DateTime.now(),
            medioPago: MedioPago.desdeValor(
              (r['medio_pago'] as String?) ?? 'efectivo',
            ),
            estado: EstadoDocumento.desdeValor(
              (r['estado'] as String?) ?? 'registrado',
            ),
            anuladoEn: r['anulado_en'] != null
                ? DateTime.tryParse(r['anulado_en'] as String)
                : null,
            motivoAnulacion: r['motivo_anulacion'] as String?,
            notas: r['notas'] as String?,
            creadoPor: r['creado_por'] as String?,
          );
          compras[c.id] = c;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM compra_items').listen((rows) {
        compraItems.clear();
        for (final r in rows) {
          final item = CompraItem(
            id: r['id'] as String,
            compraId: r['compra_id'] as String,
            insumoId: r['insumo_id'] as String,
            cantidad: (r['cantidad'] as num).toInt(),
            precioTotal: Dinero((r['precio_total_centavos'] as num).toInt()),
          );
          compraItems.putIfAbsent(item.compraId, () => []).add(item);
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM categorias_gasto').listen((rows) {
        categoriasGasto.clear();
        for (final r in rows) {
          final cat = CategoriaGasto(
            id: r['id'] as String,
            nombre: r['nombre'] as String,
            archivadoEn: r['archivado_en'] != null
                ? DateTime.tryParse(r['archivado_en'] as String)
                : null,
          );
          categoriasGasto[cat.id] = cat;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM gastos').listen((rows) {
        gastos.clear();
        for (final r in rows) {
          final g = Gasto(
            id: r['id'] as String,
            fecha:
                DateTime.tryParse(r['fecha'] as String? ?? '') ??
                DateTime.now(),
            categoriaId: r['categoria_id'] as String,
            descripcion: r['descripcion'] as String,
            monto: Dinero((r['monto_centavos'] as num).toInt()),
            medioPago: MedioPago.desdeValor(
              (r['medio_pago'] as String?) ?? 'efectivo',
            ),
            estado: EstadoDocumento.desdeValor(
              (r['estado'] as String?) ?? 'registrado',
            ),
            anuladoEn: r['anulado_en'] != null
                ? DateTime.tryParse(r['anulado_en'] as String)
                : null,
            motivoAnulacion: r['motivo_anulacion'] as String?,
            notas: r['notas'] as String?,
          );
          gastos[g.id] = g;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM producciones').listen((rows) {
        producciones.clear();
        for (final r in rows) {
          final p = Produccion(
            id: r['id'] as String,
            fecha:
                DateTime.tryParse(r['fecha'] as String? ?? '') ??
                DateTime.now(),
            productoId: r['producto_id'] as String?,
            descripcion: r['descripcion'] as String,
            cantidad: (r['cantidad'] as num?)?.toInt() ?? 1,
            pedidoId: r['pedido_id'] as String?,
            recetaId: r['receta_id'] as String?,
            estado: EstadoDocumento.desdeValor(
              (r['estado'] as String?) ?? 'registrado',
            ),
            anuladoEn: r['anulado_en'] != null
                ? DateTime.tryParse(r['anulado_en'] as String)
                : null,
            motivoAnulacion: r['motivo_anulacion'] as String?,
            notas: r['notas'] as String?,
          );
          producciones[p.id] = p;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM movimientos_stock').listen((rows) {
        movimientosStock.clear();
        for (final r in rows) {
          final m = MovimientoStock(
            id: r['id'] as String,
            insumoId: r['insumo_id'] as String,
            fecha:
                DateTime.tryParse(r['fecha'] as String? ?? '') ??
                DateTime.now(),
            cantidad: (r['cantidad'] as num).toInt(),
            tipo: TipoMovimientoStock.desdeValor(
              (r['tipo'] as String?) ?? 'ajuste',
            ),
            compraId: r['compra_id'] as String?,
            produccionId: r['produccion_id'] as String?,
            anulaId: r['anula_id'] as String?,
            nota: r['nota'] as String?,
            creadoPor: r['creado_por'] as String?,
            creadoPorNombre: nombreDePerfil(r['creado_por'] as String?),
          );
          movimientosStock[m.id] = m;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM movimientos_caja').listen((rows) {
        movimientosCaja.clear();
        for (final r in rows) {
          final m = MovimientoCaja(
            id: r['id'] as String,
            fecha:
                DateTime.tryParse(r['fecha'] as String? ?? '') ??
                DateTime.now(),
            tipo: TipoMovimientoCaja.desdeValor(
              (r['tipo'] as String?) ?? 'ingreso',
            ),
            monto: Dinero((r['monto_centavos'] as num).toInt()),
            medioPago: MedioPago.desdeValor(
              (r['medio_pago'] as String?) ?? 'efectivo',
            ),
            concepto: ConceptoCaja.desdeValor(
              (r['concepto'] as String?) ?? 'otroIngreso',
            ),
            descripcion: r['descripcion'] as String?,
            pedidoId: r['pedido_id'] as String?,
            compraId: r['compra_id'] as String?,
            gastoId: r['gasto_id'] as String?,
            anulaId: r['anula_id'] as String?,
            creadoPor: r['creado_por'] as String?,
            creadoPorNombre: nombreDePerfil(r['creado_por'] as String?),
            anulado: false,
          );
          movimientosCaja[m.id] = m;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM tareas').listen((rows) {
        tareas.clear();
        for (final r in rows) {
          final t = Tarea(
            id: r['id'] as String,
            titulo: r['titulo'] as String,
            descripcion: r['descripcion'] as String?,
            tipo: TipoTarea.desdeValor((r['tipo'] as String?) ?? 'otro'),
            prioridad: PrioridadTarea.desdeValor(
              (r['prioridad'] as String?) ?? 'media',
            ),
            estado: EstadoTarea.desdeValor(
              (r['estado'] as String?) ?? 'pendiente',
            ),
            asignadoA: (r['asignado_a'] as String?) ?? '',
            fechaVencimiento: r['fecha_vencimiento'] != null
                ? DateTime.tryParse(r['fecha_vencimiento'] as String)
                : null,
            pedidoId: r['pedido_id'] as String?,
            completadaEn: r['completada_en'] != null
                ? DateTime.tryParse(r['completada_en'] as String)
                : null,
            creadoPor: r['creado_por'] as String?,
            creadoEn:
                DateTime.tryParse(r['creado_en'] as String? ?? '') ??
                DateTime.now(),
          );
          tareas[t.id] = t;
        }
        notificar();
      }),
    );

    _subscriptions.add(
      base.watch('SELECT * FROM alertas').listen((rows) {
        alertas.clear();
        for (final r in rows) {
          final a = Alerta(
            id: r['id'] as String,
            tipo: TipoAlerta.desdeValor((r['tipo'] as String?) ?? 'cumpleanos'),
            titulo: r['titulo'] as String,
            mensaje: r['mensaje'] as String,
            entidadTipo: r['entidad_tipo'] as String?,
            entidadId: r['entidad_id'] as String?,
            leidaEn: r['leida_en'] != null
                ? DateTime.tryParse(r['leida_en'] as String)
                : null,
            creadoEn:
                DateTime.tryParse(r['creado_en'] as String? ?? '') ??
                DateTime.now(),
          );
          alertas[a.id] = a;
        }
        notificar();
      }),
    );
  }

  // =========================================================================
  // Métodos de Persistencia (In-Memory + PowerSync SQLite)
  // =========================================================================

  Future<void> persistirInsumo(
    Insumo i, {
    MovimientoStock? movimientoInicial,
  }) async {
    insumos[i.id] = i;
    if (movimientoInicial != null) {
      movimientosStock[movimientoInicial.id] = movimientoInicial;
      evaluarAlertaStockBajo(i.id);
    }
    notificar();

    if (db != null) {
      await db!.writeTransaction((tx) async {
        await tx.execute(
          '''
          INSERT OR REPLACE INTO insumos (
            id, nombre, unidad, stock_minimo, categoria, notas, archivado_en, creado_por, creado_en, actualizado_en
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            i.id,
            i.nombre,
            i.unidad.valor,
            i.stockMinimo,
            i.categoria,
            i.notas,
            i.archivadoEn?.toIso8601String(),
            _usuarioActualId,
            DateTime.now().toIso8601String(),
            DateTime.now().toIso8601String(),
          ],
        );
        if (movimientoInicial != null) {
          await tx.execute(
            '''
            INSERT OR REPLACE INTO movimientos_stock (
              id, insumo_id, fecha, cantidad, tipo, compra_id, produccion_id, anula_id, nota, creado_por, creado_en
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              movimientoInicial.id,
              movimientoInicial.insumoId,
              movimientoInicial.fecha.toIso8601String(),
              movimientoInicial.cantidad,
              movimientoInicial.tipo.valor,
              movimientoInicial.compraId,
              movimientoInicial.produccionId,
              movimientoInicial.anulaId,
              movimientoInicial.nota,
              movimientoInicial.creadoPor ?? _usuarioActualId,
              DateTime.now().toIso8601String(),
            ],
          );
        }
      });
    }
  }

  Future<void> persistirMovimientoStock(MovimientoStock m) async {
    movimientosStock[m.id] = m;
    evaluarAlertaStockBajo(m.insumoId);
    notificar();

    if (db != null) {
      await db!.execute(
        '''
        INSERT OR REPLACE INTO movimientos_stock (
          id, insumo_id, fecha, cantidad, tipo, compra_id, produccion_id, anula_id, nota, creado_por, creado_en
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          m.id,
          m.insumoId,
          m.fecha.toIso8601String(),
          m.cantidad,
          m.tipo.valor,
          m.compraId,
          m.produccionId,
          m.anulaId,
          m.nota,
          m.creadoPor ?? _usuarioActualId,
          DateTime.now().toIso8601String(),
        ],
      );
    }
  }

  Future<void> persistirCliente(Cliente c) async {
    clientes[c.id] = c;
    notificar();

    if (db != null) {
      await db!.execute(
        '''
        INSERT OR REPLACE INTO clientes (
          id, nombre, telefono, email, direccion, cumple_dia, cumple_mes, cumple_anio,
          preferencias, alergias, notas, habitual_modo, habitual_auto, archivado_en,
          creado_por, creado_en, actualizado_en
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          c.id,
          c.nombre,
          c.telefono,
          c.email,
          c.direccion,
          c.cumpleDia,
          c.cumpleMes,
          c.cumpleAnio,
          c.preferencias,
          c.alergias,
          c.notas,
          c.habitualModo.valor,
          c.habitualAuto ? 1 : 0,
          c.archivadoEn?.toIso8601String(),
          _usuarioActualId,
          c.creadoEn.toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );
    }
  }

  Future<void> persistirProveedor(Proveedor p) async {
    proveedores[p.id] = p;
    notificar();

    if (db != null) {
      await db!.execute(
        '''
        INSERT OR REPLACE INTO proveedores (
          id, nombre, telefono, email, notas, archivado_en, creado_por, creado_en, actualizado_en
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          p.id,
          p.nombre,
          p.telefono,
          p.email,
          p.notas,
          p.archivadoEn?.toIso8601String(),
          _usuarioActualId,
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );
    }
  }

  Future<void> persistirProducto(Producto p) async {
    productos[p.id] = p;
    notificar();

    if (db != null) {
      await db!.execute(
        '''
        INSERT OR REPLACE INTO productos (
          id, nombre, categoria, precio_base_centavos, descripcion, archivado_en, creado_por, creado_en, actualizado_en
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          p.id,
          p.nombre,
          p.categoria.valor,
          p.precioBase?.centavos,
          p.descripcion,
          p.archivadoEn?.toIso8601String(),
          _usuarioActualId,
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );
    }
  }

  Future<void> persistirReceta(Receta r, List<RecetaItem> items) async {
    recetas[r.id] = r;
    recetaItems[r.id] = items;
    notificar();

    if (db != null) {
      await db!.writeTransaction((tx) async {
        await tx.execute(
          '''
          INSERT OR REPLACE INTO recetas (
            id, nombre, producto_id, rinde_cantidad, rinde_descripcion, notas, archivado_en, creado_por, creado_en, actualizado_en
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            r.id,
            r.nombre,
            r.productoId,
            r.rindeCantidad,
            r.rindeDescripcion,
            r.notas,
            r.archivadoEn?.toIso8601String(),
            _usuarioActualId,
            DateTime.now().toIso8601String(),
            DateTime.now().toIso8601String(),
          ],
        );
        await tx.execute('DELETE FROM receta_items WHERE receta_id = ?', [
          r.id,
        ]);
        for (final item in items) {
          await tx.execute(
            '''
            INSERT INTO receta_items (id, receta_id, insumo_id, cantidad, creado_en, actualizado_en)
            VALUES (?, ?, ?, ?, ?, ?)
            ''',
            [
              item.id,
              item.recetaId,
              item.insumoId,
              item.cantidad,
              DateTime.now().toIso8601String(),
              DateTime.now().toIso8601String(),
            ],
          );
        }
      });
    }
  }

  Future<void> persistirPedido(
    Pedido p,
    List<PedidoItem> items, {
    MovimientoCaja? sena,
  }) async {
    pedidos[p.id] = p;
    pedidoItems[p.id] = items;
    if (sena != null) {
      movimientosCaja[sena.id] = sena;
    }
    recalcularHabitual(p.clienteId);
    notificar();

    if (db != null) {
      await db!.writeTransaction((tx) async {
        await tx.execute(
          '''
          INSERT OR REPLACE INTO pedidos (
            id, numero, cliente_id, fecha_entrega, tipo_entrega, direccion_entrega, estado,
            descuento_centavos, motivo_descuento, notas, entregado_en, cancelado_en,
            motivo_cancelacion, creado_por, creado_en, actualizado_en
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            p.id,
            p.numero,
            p.clienteId,
            p.fechaEntrega.toIso8601String(),
            p.tipoEntrega.valor,
            p.direccionEntrega,
            p.estado.valor,
            p.descuento.centavos,
            p.motivoDescuento,
            p.notas,
            p.entregadoEn?.toIso8601String(),
            p.canceladoEn?.toIso8601String(),
            p.motivoCancelacion,
            _usuarioActualId,
            p.creadoEn.toIso8601String(),
            DateTime.now().toIso8601String(),
          ],
        );
        await tx.execute('DELETE FROM pedido_items WHERE pedido_id = ?', [
          p.id,
        ]);
        for (final item in items) {
          await tx.execute(
            '''
            INSERT INTO pedido_items (
              id, pedido_id, producto_id, descripcion, cantidad, precio_unitario_centavos,
              notas, orden, creado_en, actualizado_en
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              item.id,
              item.pedidoId,
              item.productoId,
              item.descripcion,
              item.cantidad,
              item.precioUnitario.centavos,
              item.notas,
              item.orden,
              DateTime.now().toIso8601String(),
              DateTime.now().toIso8601String(),
            ],
          );
        }
        if (sena != null) {
          await tx.execute(
            '''
            INSERT OR REPLACE INTO movimientos_caja (
              id, fecha, tipo, monto_centavos, medio_pago, concepto, descripcion,
              pedido_id, compra_id, gasto_id, anula_id, creado_por, creado_en
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              sena.id,
              sena.fecha.toIso8601String(),
              sena.tipo.valor,
              sena.monto.centavos,
              sena.medioPago.valor,
              sena.concepto.valor,
              sena.descripcion,
              sena.pedidoId,
              sena.compraId,
              sena.gastoId,
              sena.anulaId,
              sena.creadoPor ?? _usuarioActualId,
              DateTime.now().toIso8601String(),
            ],
          );
        }
      });
    }
  }

  Future<void> persistirCompra(
    Compra c,
    List<CompraItem> items,
    List<MovimientoStock> movsStock,
    MovimientoCaja movCaja,
  ) async {
    compras[c.id] = c;
    compraItems[c.id] = items;
    for (final m in movsStock) {
      movimientosStock[m.id] = m;
      evaluarAlertaStockBajo(m.insumoId);
    }
    movimientosCaja[movCaja.id] = movCaja;
    notificar();

    if (db != null) {
      await db!.writeTransaction((tx) async {
        await tx.execute(
          '''
          INSERT OR REPLACE INTO compras (
            id, proveedor_id, fecha, medio_pago, estado, anulado_en, motivo_anulacion, notas,
            creado_por, creado_en, actualizado_en
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            c.id,
            c.proveedorId,
            c.fecha.toIso8601String(),
            c.medioPago.valor,
            c.estado.valor,
            c.anuladoEn?.toIso8601String(),
            c.motivoAnulacion,
            c.notas,
            c.creadoPor ?? _usuarioActualId,
            DateTime.now().toIso8601String(),
            DateTime.now().toIso8601String(),
          ],
        );
        for (final item in items) {
          await tx.execute(
            '''
            INSERT OR REPLACE INTO compra_items (id, compra_id, insumo_id, cantidad, precio_total_centavos, creado_en)
            VALUES (?, ?, ?, ?, ?, ?)
            ''',
            [
              item.id,
              item.compraId,
              item.insumoId,
              item.cantidad,
              item.precioTotal.centavos,
              DateTime.now().toIso8601String(),
            ],
          );
        }
        for (final m in movsStock) {
          await tx.execute(
            '''
            INSERT OR REPLACE INTO movimientos_stock (
              id, insumo_id, fecha, cantidad, tipo, compra_id, produccion_id, anula_id, nota, creado_por, creado_en
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              m.id,
              m.insumoId,
              m.fecha.toIso8601String(),
              m.cantidad,
              m.tipo.valor,
              m.compraId,
              m.produccionId,
              m.anulaId,
              m.nota,
              m.creadoPor ?? _usuarioActualId,
              DateTime.now().toIso8601String(),
            ],
          );
        }
        await tx.execute(
          '''
          INSERT OR REPLACE INTO movimientos_caja (
            id, fecha, tipo, monto_centavos, medio_pago, concepto, descripcion,
            pedido_id, compra_id, gasto_id, anula_id, creado_por, creado_en
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            movCaja.id,
            movCaja.fecha.toIso8601String(),
            movCaja.tipo.valor,
            movCaja.monto.centavos,
            movCaja.medioPago.valor,
            movCaja.concepto.valor,
            movCaja.descripcion,
            movCaja.pedidoId,
            movCaja.compraId,
            movCaja.gastoId,
            movCaja.anulaId,
            movCaja.creadoPor ?? _usuarioActualId,
            DateTime.now().toIso8601String(),
          ],
        );
      });
    }
  }

  Future<void> persistirAnulacionCompra(
    Compra c,
    List<MovimientoStock> contraMovs,
    MovimientoCaja contraCaja,
  ) async {
    compras[c.id] = c;
    for (final m in contraMovs) {
      movimientosStock[m.id] = m;
      evaluarAlertaStockBajo(m.insumoId);
    }
    movimientosCaja[contraCaja.id] = contraCaja;
    notificar();

    if (db != null) {
      await db!.writeTransaction((tx) async {
        await tx.execute(
          '''
          UPDATE compras SET estado = ?, anulado_en = ?, motivo_anulacion = ?, actualizado_en = ?
          WHERE id = ?
          ''',
          [
            c.estado.valor,
            c.anuladoEn?.toIso8601String(),
            c.motivoAnulacion,
            DateTime.now().toIso8601String(),
            c.id,
          ],
        );
        for (final m in contraMovs) {
          await tx.execute(
            '''
            INSERT OR REPLACE INTO movimientos_stock (
              id, insumo_id, fecha, cantidad, tipo, compra_id, produccion_id, anula_id, nota, creado_por, creado_en
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              m.id,
              m.insumoId,
              m.fecha.toIso8601String(),
              m.cantidad,
              m.tipo.valor,
              m.compraId,
              m.produccionId,
              m.anulaId,
              m.nota,
              m.creadoPor ?? _usuarioActualId,
              DateTime.now().toIso8601String(),
            ],
          );
        }
        await tx.execute(
          '''
          INSERT OR REPLACE INTO movimientos_caja (
            id, fecha, tipo, monto_centavos, medio_pago, concepto, descripcion,
            pedido_id, compra_id, gasto_id, anula_id, creado_por, creado_en
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            contraCaja.id,
            contraCaja.fecha.toIso8601String(),
            contraCaja.tipo.valor,
            contraCaja.monto.centavos,
            contraCaja.medioPago.valor,
            contraCaja.concepto.valor,
            contraCaja.descripcion,
            contraCaja.pedidoId,
            contraCaja.compraId,
            contraCaja.gastoId,
            contraCaja.anulaId,
            contraCaja.creadoPor ?? _usuarioActualId,
            DateTime.now().toIso8601String(),
          ],
        );
      });
    }
  }

  Future<void> persistirGasto(Gasto g, MovimientoCaja movCaja) async {
    gastos[g.id] = g;
    movimientosCaja[movCaja.id] = movCaja;
    notificar();

    if (db != null) {
      await db!.writeTransaction((tx) async {
        await tx.execute(
          '''
          INSERT OR REPLACE INTO gastos (
            id, fecha, categoria_id, descripcion, monto_centavos, medio_pago, estado,
            anulado_en, motivo_anulacion, notas, creado_por, creado_en, actualizado_en
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            g.id,
            g.fecha.toIso8601String(),
            g.categoriaId,
            g.descripcion,
            g.monto.centavos,
            g.medioPago.valor,
            g.estado.valor,
            g.anuladoEn?.toIso8601String(),
            g.motivoAnulacion,
            g.notas,
            _usuarioActualId,
            DateTime.now().toIso8601String(),
            DateTime.now().toIso8601String(),
          ],
        );
        await tx.execute(
          '''
          INSERT OR REPLACE INTO movimientos_caja (
            id, fecha, tipo, monto_centavos, medio_pago, concepto, descripcion,
            pedido_id, compra_id, gasto_id, anula_id, creado_por, creado_en
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            movCaja.id,
            movCaja.fecha.toIso8601String(),
            movCaja.tipo.valor,
            movCaja.monto.centavos,
            movCaja.medioPago.valor,
            movCaja.concepto.valor,
            movCaja.descripcion,
            movCaja.pedidoId,
            movCaja.compraId,
            movCaja.gastoId,
            movCaja.anulaId,
            movCaja.creadoPor ?? _usuarioActualId,
            DateTime.now().toIso8601String(),
          ],
        );
      });
    }
  }

  Future<void> persistirAnulacionGasto(
    Gasto g,
    MovimientoCaja contraCaja,
  ) async {
    gastos[g.id] = g;
    movimientosCaja[contraCaja.id] = contraCaja;
    notificar();

    if (db != null) {
      await db!.writeTransaction((tx) async {
        await tx.execute(
          '''
          UPDATE gastos SET estado = ?, anulado_en = ?, motivo_anulacion = ?, actualizado_en = ?
          WHERE id = ?
          ''',
          [
            g.estado.valor,
            g.anuladoEn?.toIso8601String(),
            g.motivoAnulacion,
            DateTime.now().toIso8601String(),
            g.id,
          ],
        );
        await tx.execute(
          '''
          INSERT OR REPLACE INTO movimientos_caja (
            id, fecha, tipo, monto_centavos, medio_pago, concepto, descripcion,
            pedido_id, compra_id, gasto_id, anula_id, creado_por, creado_en
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            contraCaja.id,
            contraCaja.fecha.toIso8601String(),
            contraCaja.tipo.valor,
            contraCaja.monto.centavos,
            contraCaja.medioPago.valor,
            contraCaja.concepto.valor,
            contraCaja.descripcion,
            contraCaja.pedidoId,
            contraCaja.compraId,
            contraCaja.gastoId,
            contraCaja.anulaId,
            contraCaja.creadoPor ?? _usuarioActualId,
            DateTime.now().toIso8601String(),
          ],
        );
      });
    }
  }

  Future<void> persistirCategoriaGasto(CategoriaGasto cat) async {
    categoriasGasto[cat.id] = cat;
    notificar();

    if (db != null) {
      await db!.execute(
        '''
        INSERT OR REPLACE INTO categorias_gasto (
          id, nombre, archivado_en, creado_por, creado_en, actualizado_en
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          cat.id,
          cat.nombre,
          cat.archivadoEn?.toIso8601String(),
          _usuarioActualId,
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );
    }
  }

  Future<void> persistirProduccion(
    Produccion p,
    List<MovimientoStock> movs,
  ) async {
    producciones[p.id] = p;
    for (final m in movs) {
      movimientosStock[m.id] = m;
      evaluarAlertaStockBajo(m.insumoId);
    }
    notificar();

    if (db != null) {
      await db!.writeTransaction((tx) async {
        await tx.execute(
          '''
          INSERT OR REPLACE INTO producciones (
            id, fecha, producto_id, descripcion, cantidad, pedido_id, receta_id,
            estado, anulado_en, motivo_anulacion, notas, creado_por, creado_en, actualizado_en
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            p.id,
            p.fecha.toIso8601String(),
            p.productoId,
            p.descripcion,
            p.cantidad,
            p.pedidoId,
            p.recetaId,
            p.estado.valor,
            p.anuladoEn?.toIso8601String(),
            p.motivoAnulacion,
            p.notas,
            _usuarioActualId,
            DateTime.now().toIso8601String(),
            DateTime.now().toIso8601String(),
          ],
        );
        for (final m in movs) {
          await tx.execute(
            '''
            INSERT OR REPLACE INTO movimientos_stock (
              id, insumo_id, fecha, cantidad, tipo, compra_id, produccion_id, anula_id, nota, creado_por, creado_en
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              m.id,
              m.insumoId,
              m.fecha.toIso8601String(),
              m.cantidad,
              m.tipo.valor,
              m.compraId,
              m.produccionId,
              m.anulaId,
              m.nota,
              m.creadoPor ?? _usuarioActualId,
              DateTime.now().toIso8601String(),
            ],
          );
        }
      });
    }
  }

  Future<void> persistirAnulacionProduccion(
    Produccion p,
    List<MovimientoStock> contraMovs,
  ) async {
    producciones[p.id] = p;
    for (final m in contraMovs) {
      movimientosStock[m.id] = m;
      evaluarAlertaStockBajo(m.insumoId);
    }
    notificar();

    if (db != null) {
      await db!.writeTransaction((tx) async {
        await tx.execute(
          '''
          UPDATE producciones SET estado = ?, anulado_en = ?, motivo_anulacion = ?, actualizado_en = ?
          WHERE id = ?
          ''',
          [
            p.estado.valor,
            p.anuladoEn?.toIso8601String(),
            p.motivoAnulacion,
            DateTime.now().toIso8601String(),
            p.id,
          ],
        );
        for (final m in contraMovs) {
          await tx.execute(
            '''
            INSERT OR REPLACE INTO movimientos_stock (
              id, insumo_id, fecha, cantidad, tipo, compra_id, produccion_id, anula_id, nota, creado_por, creado_en
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              m.id,
              m.insumoId,
              m.fecha.toIso8601String(),
              m.cantidad,
              m.tipo.valor,
              m.compraId,
              m.produccionId,
              m.anulaId,
              m.nota,
              m.creadoPor ?? _usuarioActualId,
              DateTime.now().toIso8601String(),
            ],
          );
        }
      });
    }
  }

  Future<void> persistirMovimientoCaja(MovimientoCaja m) async {
    movimientosCaja[m.id] = m;
    notificar();

    if (db != null) {
      await db!.execute(
        '''
        INSERT OR REPLACE INTO movimientos_caja (
          id, fecha, tipo, monto_centavos, medio_pago, concepto, descripcion,
          pedido_id, compra_id, gasto_id, anula_id, creado_por, creado_en
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          m.id,
          m.fecha.toIso8601String(),
          m.tipo.valor,
          m.monto.centavos,
          m.medioPago.valor,
          m.concepto.valor,
          m.descripcion,
          m.pedidoId,
          m.compraId,
          m.gastoId,
          m.anulaId,
          m.creadoPor ?? _usuarioActualId,
          DateTime.now().toIso8601String(),
        ],
      );
    }
  }

  Future<void> persistirTarea(Tarea t) async {
    tareas[t.id] = t;
    notificar();

    if (db != null) {
      await db!.execute(
        '''
        INSERT OR REPLACE INTO tareas (
          id, titulo, descripcion, tipo, prioridad, estado, asignado_a,
          fecha_vencimiento, pedido_id, completada_en, creado_por, creado_en, actualizado_en
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          t.id,
          t.titulo,
          t.descripcion,
          t.tipo.valor,
          t.prioridad.valor,
          t.estado.valor,
          t.asignadoA,
          t.fechaVencimiento?.toIso8601String(),
          t.pedidoId,
          t.completadaEn?.toIso8601String(),
          t.creadoPor ?? _usuarioActualId,
          t.creadoEn.toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );
    }
  }

  Future<void> persistirAlerta(Alerta a) async {
    alertas[a.id] = a;
    notificar();

    if (db != null) {
      await db!.execute(
        '''
        INSERT OR REPLACE INTO alertas (
          id, destinatario_id, tipo, titulo, mensaje, entidad_tipo, entidad_id,
          clave, leida_en, push_enviada_en, creado_en
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          a.id,
          _usuarioActualId,
          a.tipo.valor,
          a.titulo,
          a.mensaje,
          a.entidadTipo,
          a.entidadId,
          a.id,
          a.leidaEn?.toIso8601String(),
          null,
          a.creadoEn.toIso8601String(),
        ],
      );
    }
  }

  Future<void> persistirConfiguracion(Configuracion c) async {
    configuracion = c;
    recalcularTodosLosHabituales();
    notificar();

    if (db != null) {
      await db!.execute(
        '''
        INSERT OR REPLACE INTO configuracion (
          id, unica, nombre_negocio, dias_aviso_cumple, aviso_cumple_alcance,
          habitual_min_pedidos, habitual_meses, actualizado_en
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          'configuracion_principal',
          'si',
          c.nombreNegocio,
          c.diasAvisoCumple,
          c.avisoCumpleAlcance.valor,
          c.habitualMinPedidos,
          c.habitualMeses,
          DateTime.now().toIso8601String(),
        ],
      );
    }
  }

  Future<void> persistirPermisos(
    String perfilId,
    Map<Modulo, NivelPermiso> nuevos,
  ) async {
    permisos[perfilId] = Map.of(nuevos);
    notificar();

    if (db != null) {
      await db!.writeTransaction((tx) async {
        for (final entry in nuevos.entries) {
          final id = '$perfilId:${entry.key.valor}';
          await tx.execute(
            '''
            INSERT OR REPLACE INTO permisos (id, perfil_id, modulo, nivel, actualizado_en)
            VALUES (?, ?, ?, ?, ?)
            ''',
            [
              id,
              perfilId,
              entry.key.valor,
              entry.value.valor,
              DateTime.now().toIso8601String(),
            ],
          );
        }
      });
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
      final act = Cliente(
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
      persistirCliente(act);
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
    final nuevaAlerta = Alerta(
      id: clave,
      tipo: TipoAlerta.stockBajo,
      titulo: 'Falta ${insumo.nombre}',
      mensaje:
          'Quedan ${insumo.unidad.formatear(actual)} (mínimo ${insumo.unidad.formatear(insumo.stockMinimo)}).',
      entidadTipo: 'insumo',
      entidadId: insumo.id,
      creadoEn: DateTime.now(),
    );
    persistirAlerta(nuevaAlerta);
    unawaited(
      ServicioNotificacionesPush.mostrarNotificacionLocal(
        id: clave.hashCode,
        titulo: 'Falta ${insumo.nombre}',
        cuerpo:
            'Quedan ${insumo.unidad.formatear(actual)} (mínimo ${insumo.unidad.formatear(insumo.stockMinimo)}).',
      ),
    );
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _cambios.close();
    super.dispose();
  }
}

final almacenLocalProvider = Provider<AlmacenLocal>((ref) {
  final almacen = AlmacenLocal();
  ref.onDispose(almacen.dispose);
  return almacen;
});
