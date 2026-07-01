// lib/services/fcm_service.dart
import 'dart:ui' show Color;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static const _channelId = 'safecar_admin_channel';
  static const _channelName = 'Safe Car Admin';
  static const _channelDesc = 'Alertas de grúa, reservas y pedidos';

  // Naranja del cluster de instrumentos (SC.orange), consistente con
  // el resto de la identidad visual de la app.
  static const _accentColor = Color(0xFFFF6A1A);

  static Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(
      const InitializationSettings(android: androidInit),
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif == null) return;
      _localNotif.show(
        notif.hashCode,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            color: _accentColor,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['event_type'],
      );
    });

    final token = await _messaging.getToken();
    if (token != null) await ApiService.registerFcmToken(token);
    _messaging.onTokenRefresh.listen((t) => ApiService.registerFcmToken(t));
  }
}