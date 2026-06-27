// lib/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Handler para mensajes en background (top-level, fuera de la clase)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // El plugin flutter_local_notifications muestra la notificación automáticamente
  // cuando la app está en background/killed si el mensaje tiene notification payload
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static const _channelId = 'safecar_admin_channel';
  static const _channelName = 'Safe Car Admin';
  static const _channelDesc = 'Alertas de grúa, reservas y pedidos';

  static Future<void> init() async {
    // Permisos
    await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // Canal Android
    const androidChannel = AndroidNotificationChannel(
      _channelId, _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Init local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (details) {
        // Navegar según payload si se necesita en el futuro
      },
    );

    // Handler background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handler foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif == null) return;
      _localNotif.show(
        notif.hashCode,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId, _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            color: const Color(0xFFD4AF37),
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['event_type'],
      );
    });

    // Registrar token en el backend
    final token = await _messaging.getToken();
    if (token != null) {
      await ApiService.registerFcmToken(token);
    }

    // Refrescar token si cambia
    _messaging.onTokenRefresh.listen((newToken) {
      ApiService.registerFcmToken(newToken);
    });
  }
}

// Necesario para el color en el canal
import 'dart:ui' show Color;
