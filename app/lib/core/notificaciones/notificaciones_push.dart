import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> manejarMensajeEnSegundoPlano(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class ServicioNotificacionesPush {
  ServicioNotificacionesPush._();

  static final FlutterLocalNotificationsPlugin _notificacionesLocales =
      FlutterLocalNotificationsPlugin();

  static bool _inicializado = false;

  static const AndroidNotificationChannel _canalAndroid =
      AndroidNotificationChannel(
        'jereposteria_alertas',
        'Alertas de JeRepostería',
        description:
            'Avisos de cumpleaños, entregas próximas, tareas y stock bajo',
        importance: Importance.high,
      );

  static bool get _esAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _esWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static RealtimeChannel? _canalAlertasSupabase;

  static Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;

    try {
      const configAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const configWindows = WindowsInitializationSettings(
        appName: 'JeRepostería',
        appUserModelId: 'com.jereposteria.jereposteria',
        guid: 'd84b0f31-95d7-4f6a-9f88-58c2c7e3b901',
      );
      const configInicial = InitializationSettings(
        android: configAndroid,
        windows: configWindows,
      );
      await _notificacionesLocales.initialize(configInicial);

      if (_esAndroid) {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(manejarMensajeEnSegundoPlano);

        final pluginAndroid = _notificacionesLocales
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await pluginAndroid?.createNotificationChannel(_canalAndroid);

        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notif = message.notification;
          if (notif != null) {
            mostrarNotificacionLocal(
              id: message.hashCode,
              titulo: notif.title ?? 'JeRepostería',
              cuerpo: notif.body ?? '',
            );
          }
        });

        FirebaseMessaging.instance.onTokenRefresh.listen((nuevoToken) {
          unawaited(registrarTokenEnSupabase(tokenExplicito: nuevoToken));
        });

        unawaited(registrarTokenEnSupabase());
      } else if (_esWindows) {
        suscribirAlertasTiempoReal();
      }
    } catch (_) {
      // Si Firebase o el subsistema nativo no está disponible, continúa sin interrumpir la app.
    }
  }

  /// En Windows Desktop escucha en tiempo real las alertas nuevas en Supabase
  /// para el usuario actual y dispara una notificación nativa de Windows.
  static void suscribirAlertasTiempoReal() {
    if (!_esWindows) return;
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      _canalAlertasSupabase?.unsubscribe();
      _canalAlertasSupabase = client
          .channel('alertas_windows_${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'alertas',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'destinatario_id',
              value: user.id,
            ),
            callback: (payload) {
              final nuevo = payload.newRecord;
              final titulo = (nuevo['titulo'] as String?) ?? 'JeRepostería';
              final mensaje = (nuevo['mensaje'] as String?) ?? '';
              final idStr =
                  (nuevo['id'] as String?) ?? DateTime.now().toIso8601String();
              unawaited(
                mostrarNotificacionLocal(
                  id: idStr.hashCode,
                  titulo: titulo,
                  cuerpo: mensaje,
                ),
              );
            },
          )
          .subscribe();
    } catch (_) {}
  }

  static Future<void> mostrarNotificacionLocal({
    required int id,
    required String titulo,
    required String cuerpo,
  }) async {
    if (!_esAndroid && !_esWindows) return;
    try {
      await _notificacionesLocales.show(
        id,
        titulo,
        cuerpo,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _canalAndroid.id,
            _canalAndroid.name,
            channelDescription: _canalAndroid.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          windows: const WindowsNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  static Future<void> registrarTokenEnSupabase({String? tokenExplicito}) async {
    if (!_esAndroid) return;
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final token =
          tokenExplicito ?? await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) return;

      await client.from('dispositivos').upsert({
        'perfil_id': user.id,
        'token': token.trim(),
        'plataforma': 'android',
        'actualizado_en': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
    } catch (_) {}
  }
}
