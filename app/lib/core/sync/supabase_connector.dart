import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final session = supabase.auth.currentSession;
    if (session == null) return null;
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

    try {
      for (final op in transaction.crud) {
        final table = supabase.from(op.table);
        switch (op.op) {
          case UpdateType.put:
            final data = Map<String, dynamic>.of(op.opData ?? {});
            data['id'] = op.id;
            await table.upsert(data);
          case UpdateType.patch:
            if (op.opData != null && op.opData!.isNotEmpty) {
              await table.update(op.opData!).eq('id', op.id);
            }
          case UpdateType.delete:
            await table.delete().eq('id', op.id);
        }
      }
      await transaction.complete();
    } on PostgrestException catch (e) {
      // Errores de validación o RLS definitivos (4xx / P0001 / 23xxx) se descartan
      // para no bloquear la cola de sincronización indefinidamente.
      final code = e.code ?? '';
      if (code.startsWith('23') || code == 'P0001' || code == '42501') {
        await transaction.complete();
        return;
      }
      rethrow;
    }
  }
}
