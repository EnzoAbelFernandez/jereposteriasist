import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';
import 'package:jereposteria/data/local/almacen_local.dart';
import 'package:jereposteria/data/modelos/alertas_equipo_modelos.dart';
import 'package:jereposteria/data/modelos/clientes_modelos.dart';
import 'package:jereposteria/data/modelos/pedidos_modelos.dart';
import 'package:jereposteria/data/modelos/productos_modelos.dart';
import 'package:jereposteria/data/modelos/proveedores_modelos.dart';
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

      // 7. Pedidos
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
      } catch (e) {
        debugPrint('Error sincronizando pedidos directo: $e');
      }

      // 8. Tareas
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

      // 9. Alertas
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
              final rec = payload.newRecord;
              if (rec.isNotEmpty) {
                final i = Insumo(
                  id: rec['id'] as String,
                  nombre: rec['nombre'] as String,
                  unidad: Unidad.desdeValor(rec['unidad'] as String),
                  stockMinimo: (rec['stock_minimo'] as num?)?.toInt() ?? 0,
                  categoria: rec['categoria'] as String?,
                  notas: rec['notas'] as String?,
                  archivadoEn: rec['archivado_en'] != null
                      ? DateTime.tryParse(rec['archivado_en'] as String)
                      : null,
                );
                almacen.insumos[i.id] = i;
                almacen.notificar();
              }
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
            table: 'tareas',
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
