import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/core/config/entorno.dart';
import 'package:jereposteria/core/notificaciones/notificaciones_push.dart';
import 'package:jereposteria/core/router/router.dart';
import 'package:jereposteria/core/sync/powersync_database.dart';
import 'package:jereposteria/core/sync/sincronizacion_directa.dart';
import 'package:jereposteria/core/tema/tema.dart';
import 'package:jereposteria/data/data.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: EntornoApp.supabaseUrl,
      publishableKey: EntornoApp.supabasePublishableKey,
    );
  } catch (_) {
    // Permite seguir operando en modo local/offline si no hay red al iniciar.
  }
  await ServicioNotificacionesPush.inicializar();

  PowerSyncDatabase? powerSyncDb;
  try {
    powerSyncDb = await inicializarPowerSync();
  } catch (e) {
    debugPrint('Error inicializando PowerSync: $e');
  }

  final almacen = AlmacenLocal(db: powerSyncDb);
  if (powerSyncDb != null) {
    await almacen.vincularPowerSync(powerSyncDb);
  }

  // Vincular sesión actual si existe en almacenamiento local
  try {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final user = session.user;
      final nombre =
          (user.userMetadata?['nombre'] as String?)?.trim().isNotEmpty == true
          ? (user.userMetadata!['nombre'] as String).trim()
          : (user.email?.split('@').first ?? 'Enzo');
      almacen.perfiles[user.id] = Perfil(
        id: user.id,
        nombre: nombre,
        rol: Rol.jefe,
        activo: true,
      );
      almacen.permisos[user.id] = {
        for (final m in Modulo.values) m: NivelPermiso.editar,
      };
      almacen.usuarioActualId = user.id;

      unawaited(
        SincronizacionDirectaSupabase.sincronizarTodo(
          almacen,
          Supabase.instance.client,
        ),
      );
      SincronizacionDirectaSupabase.suscribirRealtime(
        almacen,
        Supabase.instance.client,
      );
    } else {
      almacen.usuarioActualId = null;
    }
  } catch (_) {
    almacen.usuarioActualId = null;
  }

  runApp(
    ProviderScope(
      overrides: [
        almacenLocalProvider.overrideWithValue(almacen),
        powerSyncDatabaseProvider.overrideWithValue(powerSyncDb),
      ],
      child: const JeReposteriaApp(),
    ),
  );
}

class JeReposteriaApp extends ConsumerWidget {
  const JeReposteriaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'JeRepostería',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro(),
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'AR'), Locale('es')],
      locale: const Locale('es', 'AR'),
    );
  }
}
