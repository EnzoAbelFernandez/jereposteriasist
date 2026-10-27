import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/core/config/entorno.dart';
import 'package:jereposteria/core/notificaciones/notificaciones_push.dart';
import 'package:jereposteria/core/router/router.dart';
import 'package:jereposteria/core/tema/tema.dart';
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
  runApp(const ProviderScope(child: JeReposteriaApp()));
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
