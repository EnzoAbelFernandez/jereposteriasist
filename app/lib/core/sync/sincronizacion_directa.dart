import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/errores.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sincronización directa bidireccional con Supabase.
///
/// Sirve como respaldo en tiempo real y fallback cuando PowerSync local
/// está inicializando o en plataformas donde la biblioteca SQLite nativa
/// requiere tiempo o respaldo adicional.
class SincronizacionDirectaSupabase {
  static RealtimeChannel? _canalRealtime;

  /// Carga el acceso real del usuario autenticado, sin depender de PowerSync.
  /// Solo lee Supabase: no genera operaciones en la cola de escritura local.
  static Future<void> cargarAcceso(
    AlmacenLocal almacen,
    SupabaseClient client,
  ) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null || almacen.usuarioActualId != uid) return;
    try {
      final fila = await client
          .from('perfiles')
          .select()
          .eq('id', uid)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      final filasPermisos = await client
          .from('permisos')
          .select()
          .eq('perfil_id', uid)
          .timeout(const Duration(seconds: 10));
      final perfil = fila == null
          ? null
          : Perfil(
              id: fila['id'] as String,
              nombre: fila['nombre'] as String,
              rol: Rol.desdeValor(fila['rol'] as String? ?? 'empleado'),
              telefono: fila['telefono'] as String?,
              activo: fila['activo'] == true || fila['activo'] == 1,
            );
      final niveles = <Modulo, NivelPermiso>{
        for (final fila in filasPermisos)
          Modulo.desdeValor(fila['modulo'] as String): NivelPermiso.desdeValor(
            fila['nivel'] as String,
          ),
      };
      // Una respuesta tardía no debe modificar el acceso de otra sesión.
      if (client.auth.currentUser?.id != uid ||
          almacen.usuarioActualId != uid) {
        return;
      }
      if (perfil == null) {
        almacen.perfiles.remove(uid);
      } else {
        almacen.perfiles[uid] = perfil;
      }
      almacen.permisos[uid] = niveles;
      almacen.notificar();
    } catch (_) {
      // Si no hay red, se mantiene el acceso que ya estaba en el almacén.
      debugPrint(
        'No se pudo actualizar el perfil y los permisos desde Supabase.',
      );
    }
  }

  /// Guarda o actualiza un registro directamente en Supabase.
  /// Solo confirma éxito cuando Supabase acepta la escritura. Sin base local
  /// persistente, un fallo se informa al formulario para que conserve los campos.
  static Future<void> guardar(
    SupabaseClient client,
    String tabla,
    Map<String, dynamic> datos,
  ) async {
    if (client.auth.currentSession == null) {
      throw const ErrorDeNegocio(
        'Iniciá sesión para guardar los cambios en Supabase.',
      );
    }
    try {
      if (tabla == 'alertas' && datos.containsKey('leida_en')) {
        await client
            .from('alertas')
            .update({'leida_en': datos['leida_en']})
            .eq('id', datos['id'])
            .select('id')
            .single();
      } else if (datos.containsKey('id') && datos.length == 1) {
        await client.from(tabla).delete().eq('id', datos['id']);
      } else {
        final datosServidor = Map<String, dynamic>.of(datos);
        if (tabla == 'pedidos') datosServidor.remove('numero');
        await client.from(tabla).upsert(datosServidor).select('id').single();
      }
    } on PostgrestException catch (e) {
      throw ErrorDeNegocio(
        'Supabase rechazó el guardado en $tabla${e.code == null ? '' : ' (${e.code})'}: ${e.message}',
      );
    } catch (_) {
      throw ErrorDeNegocio(
        'No pudimos confirmar el guardado en $tabla. Revisá la conexión y volvé a intentar.',
      );
    }
  }

  /// Descarga el estado actual de las tablas principales desde Supabase hacia [almacen].
  static Future<void> sincronizarTodo(
    AlmacenLocal almacen,
    SupabaseClient client,
  ) async {
    try {
      // 1. Perfiles
      try {
        final rowsPerfiles = await client.from('perfiles').select();
        for (final r in rowsPerfiles) {
          final p = Perfil(
            id: r['id'] as String,
            nombre: (r['nombre'] as String?)?.trim().isNotEmpty == true
                ? (r['nombre'] as String).trim()
                : 'Usuario',
            rol: Rol.desdeValor(r['rol'] as String? ?? 'empleado'),
            telefono: r['telefono'] as String?,
            activo: r['activo'] == true || r['activo'] == 1,
          );
          almacen.perfiles[p.id] = p;
        }
      } catch (e) {
        debugPrint('Error sincronizando perfiles directo: $e');
      }

      // 2. Permisos
      try {
        final rowsPermisos = await client.from('permisos').select();
        for (final r in rowsPermisos) {
          final perfilId = r['perfil_id'] as String;
          final modulo = Modulo.desdeValor(r['modulo'] as String);
          final nivel = NivelPermiso.desdeValor(r['nivel'] as String);
          almacen.permisos.putIfAbsent(perfilId, () => {})[modulo] = nivel;
        }
      } catch (e) {
        debugPrint('Error sincronizando permisos directo: $e');
      }

      // 3. Insumos
      try {
        final rowsInsumos = await client.from('insumos').select();
        for (final r in rowsInsumos) {
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
          almacen.insumos[i.id] = i;
        }
      } catch (e) {
        debugPrint('Error sincronizando insumos directo: $e');
      }

      // 4. Clientes
      try {
        final rowsClientes = await client.from('clientes').select();
        for (final r in rowsClientes) {
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
            habitualAuto: r['habitual_auto'] == true || r['habitual_auto'] == 1,
            archivadoEn: r['archivado_en'] != null
                ? DateTime.tryParse(r['archivado_en'] as String)
                : null,
            creadoEn:
                DateTime.tryParse((r['creado_en'] as String?) ?? '') ??
                DateTime.now(),
          );
          almacen.clientes[c.id] = c;
        }
      } catch (e) {
        debugPrint('Error sincronizando clientes directo: $e');
      }

      // 5. Proveedores
      try {
        final rowsProveedores = await client.from('proveedores').select();
        for (final r in rowsProveedores) {
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
          almacen.proveedores[p.id] = p;
        }
      } catch (e) {
        debugPrint('Error sincronizando proveedores directo: $e');
      }

      // 6. Productos
      try {
        final rowsProductos = await client.from('productos').select();
        for (final r in rowsProductos) {
          final prod = Producto(
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
          almacen.productos[prod.id] = prod;
        }
      } catch (e) {
        debugPrint('Error sincronizando productos directo: $e');
      }

      // 7. Recetas
      try {
        final rowsRecetas = await client.from('recetas').select();
        for (final r in rowsRecetas) {
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
          almacen.recetas[rec.id] = rec;
        }
        final rowsRecetaItems = await client.from('receta_items').select();
        almacen.recetaItems.clear();
        for (final r in rowsRecetaItems) {
          final item = RecetaItem(
            id: r['id'] as String,
            recetaId: r['receta_id'] as String,
            insumoId: r['insumo_id'] as String,
            cantidad: (r['cantidad'] as num).toInt(),
          );
          almacen.recetaItems.putIfAbsent(item.recetaId, () => []).add(item);
        }
      } catch (e) {
        debugPrint('Error sincronizando recetas directo: $e');
      }

      // 8. Pedidos
      try {
        final rowsPedidos = await client.from('pedidos').select();
        for (final r in rowsPedidos) {
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
          almacen.pedidos[ped.id] = ped;
        }
        final rowsPedidoItems = await client.from('pedido_items').select();
        almacen.pedidoItems.clear();
        for (final r in rowsPedidoItems) {
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
          almacen.pedidoItems.putIfAbsent(item.pedidoId, () => []).add(item);
        }
      } catch (e) {
        debugPrint('Error sincronizando pedidos directo: $e');
      }

      // 9. Compras
      try {
        final rowsCompras = await client.from('compras').select();
        for (final r in rowsCompras) {
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
          almacen.compras[c.id] = c;
        }
        final rowsCompraItems = await client.from('compra_items').select();
        almacen.compraItems.clear();
        for (final r in rowsCompraItems) {
          final item = CompraItem(
            id: r['id'] as String,
            compraId: r['compra_id'] as String,
            insumoId: r['insumo_id'] as String,
            cantidad: (r['cantidad'] as num).toInt(),
            precioTotal: Dinero((r['precio_total_centavos'] as num).toInt()),
          );
          almacen.compraItems.putIfAbsent(item.compraId, () => []).add(item);
        }
      } catch (e) {
        debugPrint('Error sincronizando compras directo: $e');
      }

      // 10. Gastos y Categorías
      try {
        final rowsCats = await client.from('categorias_gasto').select();
        for (final r in rowsCats) {
          final cat = CategoriaGasto(
            id: r['id'] as String,
            nombre: r['nombre'] as String,
            archivadoEn: r['archivado_en'] != null
                ? DateTime.tryParse(r['archivado_en'] as String)
                : null,
          );
          almacen.categoriasGasto[cat.id] = cat;
        }
        final rowsGastos = await client.from('gastos').select();
        for (final r in rowsGastos) {
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
          almacen.gastos[g.id] = g;
        }
      } catch (e) {
        debugPrint('Error sincronizando gastos directo: $e');
      }

      // 11. Producciones
      try {
        final rowsProducciones = await client.from('producciones').select();
        for (final r in rowsProducciones) {
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
          almacen.producciones[p.id] = p;
        }
      } catch (e) {
        debugPrint('Error sincronizando producciones directo: $e');
      }

      // 12. Movimientos de stock
      try {
        final rowsMovs = await client.from('movimientos_stock').select();
        for (final r in rowsMovs) {
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
            creadoPorNombre: almacen.nombreDePerfil(r['creado_por'] as String?),
          );
          almacen.movimientosStock[m.id] = m;
        }
      } catch (e) {
        debugPrint('Error sincronizando movimientos_stock directo: $e');
      }

      // 13. Movimientos de caja
      try {
        final rowsCaja = await client.from('movimientos_caja').select();
        for (final r in rowsCaja) {
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
            creadoPorNombre: almacen.nombreDePerfil(r['creado_por'] as String?),
            anulado: false,
          );
          almacen.movimientosCaja[m.id] = m;
        }
      } catch (e) {
        debugPrint('Error sincronizando movimientos_caja directo: $e');
      }

      // 14. Tareas
      try {
        final rowsTareas = await client.from('tareas').select();
        for (final r in rowsTareas) {
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
          almacen.tareas[t.id] = t;
        }
      } catch (e) {
        debugPrint('Error sincronizando tareas directo: $e');
      }

      // 15. Alertas
      try {
        final rowsAlertas = await client.from('alertas').select();
        for (final r in rowsAlertas) {
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
          almacen.alertas[a.id] = a;
        }
      } catch (e) {
        debugPrint('Error sincronizando alertas directo: $e');
      }

      almacen.notificar();
    } catch (e) {
      debugPrint('Error general en sincronizarTodo: $e');
    }
  }

  /// Suscribe un canal Supabase Realtime para cambios instantáneos entre dispositivos.
  static void suscribirRealtime(AlmacenLocal almacen, SupabaseClient client) {
    if (_canalRealtime != null) return;

    try {
      _canalRealtime = client
          .channel('jereposteria_publico')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'insumos',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'pedidos',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'clientes',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'proveedores',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'productos',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'recetas',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'compras',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'gastos',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'producciones',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'movimientos_stock',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'movimientos_caja',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tareas',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'alertas',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'perfiles',
            callback: (payload) {
              unawaited(sincronizarTodo(almacen, client));
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('No se pudo suscribir a Supabase Realtime: $e');
    }
  }
}
