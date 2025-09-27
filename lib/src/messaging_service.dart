// lib/src/messaging_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request permissions
    await _messaging.requestPermission();

    // Android channel
    const channel = AndroidNotificationChannel(
      'sos_high_priority_channel',
      'SOS Alerts',
      description: 'High priority SOS alerts',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initSettings);

    // Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'sos_high_priority_channel',
              'SOS Alerts',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
            ),
          ),
        );
      }
    });
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
