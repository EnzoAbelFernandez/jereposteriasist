import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Contexto del rechazo, sin incluir tokens ni el contenido de los registros.
class ErrorSubidaSync implements Exception {
  const ErrorSubidaSync({
    required this.tabla,
    required this.operacion,
    required this.codigo,
  });

  final String tabla;
  final String operacion;
  final String codigo;

  String get mensaje {
    final causa = switch (codigo) {
      '42501' => 'Supabase rechazó la operación por permisos.',
      '23503' => 'Falta un registro relacionado en Supabase.',
      '23502' => 'Falta un campo obligatorio en Supabase.',
      '23505' => 'Hay un identificador o valor único repetido.',
      '22P02' => 'Un campo tiene un formato incompatible con Supabase.',
      '23514' => 'Los datos no cumplen una validación de Supabase.',
      'P0001' => 'Una regla de negocio de Supabase rechazó la operación.',
      _ => 'Supabase rechazó la operación.',
    };
    return 'Tabla: $tabla. Operación: $operacion. Código: $codigo. $causa Los cambios siguen en la cola local.';
  }

  @override
  String toString() => mensaje;
}

/// Conector entre PowerSync (SQLite local) y Supabase.
///
/// Sube la cola de operaciones creadas sin conexión respetando las transacciones locales.
class SupabasePowerSyncConnector extends PowerSyncBackendConnector {
  SupabasePowerSyncConnector({
    required this.supabase,
    required this.powersyncUrl,
  });

  final SupabaseClient supabase;
  final String powersyncUrl;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // getSession renueva la sesión cuando el token venció o está próximo
    // a vencer; currentSession puede devolver un token vencido.
    final session = await supabase.auth.getSession();
    if (session == null) return null;
    final vencimiento = session.expiresAt;
    if (vencimiento != null &&
        vencimiento * 1000 <= DateTime.now().millisecondsSinceEpoch) {
      throw const AuthException('La sesión venció y no pudo renovarse.');
    }
    return PowerSyncCredentials(
      endpoint: powersyncUrl,
      token: session.accessToken,
      userId: session.user.id,
      expiresAt: session.expiresAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000),
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    // Cualquier rechazo se propaga al SDK como uploadError y deja la cola
    // pendiente. Solo se completa cuando todas las escrituras fueron aceptadas.
    for (final op in transaction.crud) {
      try {
        final table = supabase.from(op.table);
        if (op.table == 'alertas' && op.op == UpdateType.put) {
          final data = op.opData ?? {};
          // Versiones anteriores encolaban avisos locales derivados de stock.
          // El servidor genera el aviso a partir del movimiento sincronizado.
          if (op.id.startsWith('stock_bajo:') &&
              data['tipo'] == 'stock_bajo' &&
              data['clave'] == op.id &&
              data['leida_en'] == null) {
            continue;
          }
          // Solo se permite cambiar el estado de lectura de una alerta real.
          if (data['leida_en'] == null || op.id.startsWith('stock_bajo:')) {
            throw const AuthException(
              'La alerta pendiente no se puede sincronizar automáticamente.',
            );
          }
          await table
              .update({'leida_en': data['leida_en']})
              .eq('id', op.id)
              .select('id')
              .single();
          continue;
        }
        switch (op.op) {
          case UpdateType.put:
            final data = Map<String, dynamic>.of(op.opData ?? {});
            data['id'] = op.id;
            // Incluye operaciones de versiones anteriores todavía en cola.
            // El correlativo pertenece al servidor, nunca al dispositivo.
            if (op.table == 'pedidos') data.remove('numero');
            await table.upsert(data);
          case UpdateType.patch:
            if (op.opData != null && op.opData!.isNotEmpty) {
              final data = Map<String, dynamic>.of(op.opData!);
              if (op.table == 'pedidos') data.remove('numero');
              if (data.isNotEmpty) await table.update(data).eq('id', op.id);
            }
          case UpdateType.delete:
            await table.delete().eq('id', op.id);
        }
      } on PostgrestException catch (e) {
        throw ErrorSubidaSync(
          tabla: op.table,
          operacion: op.op.name,
          codigo: e.code ?? 'sin código',
        );
      }
    }
    await transaction.complete();
  }
}
