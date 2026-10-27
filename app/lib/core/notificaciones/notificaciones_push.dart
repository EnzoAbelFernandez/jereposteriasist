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

  static Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;

    if (!_esAndroid) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(manejarMensajeEnSegundoPlano);

      const configAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const configInicial = InitializationSettings(android: configAndroid);
      await _notificacionesLocales.initialize(configInicial);

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
    } catch (_) {
      // Si Firebase no está disponible en el entorno actual, continúa sin interrumpir la app.
    }
  }

  static Future<void> mostrarNotificacionLocal({
    required int id,
    required String titulo,
    required String cuerpo,
  }) async {
    if (!_esAndroid) return;
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
