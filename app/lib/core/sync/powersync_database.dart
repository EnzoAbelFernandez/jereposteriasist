import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/core/config/entorno.dart';
import 'package:jereposteria/core/sync/powersync_schema.dart';
import 'package:jereposteria/core/sync/supabase_connector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Instancia global o nula de PowerSyncDatabase.
final powerSyncDatabaseProvider = Provider<PowerSyncDatabase?>((ref) => null);

/// Inicializa la base de datos local SQLite y la vincula con Supabase a través de PowerSync.
Future<PowerSyncDatabase?> inicializarPowerSync() async {
  if (kIsWeb) {
    return null;
  }

  try {
    final dir = await getApplicationSupportDirectory();
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    final dbPath = p.join(dir.path, 'jereposteria.powersync.db');

    final db = PowerSyncDatabase(schema: powersyncSchema, path: dbPath);
    await db.initialize();

    SupabaseClient? supabase;
    try {
      supabase = Supabase.instance.client;
    } catch (_) {
      supabase = null;
    }

    if (supabase != null) {
      final connector = SupabasePowerSyncConnector(
        supabase: supabase,
        powersyncUrl: EntornoApp.powerSyncUrl,
      );

      // Si ya hay sesión activa persistida en disco, conectar inmediatamente.
      if (supabase.auth.currentSession != null) {
        unawaited(db.connect(connector: connector));
      }

      // Escuchar cambios de sesión (login, refresh de token, logout).
      supabase.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated) {
          db.connect(connector: connector);
        } else if (event == AuthChangeEvent.signedOut) {
          db.disconnect();
        }
      });
    }

    return db;
  } catch (e, stack) {
    debugPrint('No se pudo inicializar PowerSync: $e\n$stack');
    return null;
  }
}
