// lib/services/notification_service.dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _fs = FirestoreService();

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> initPlugin() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(initSettings);

    // Ask notification permission (Android 13+)
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  Future<void> init(String uid) async {
    // iOS permission
    await _fcm.requestPermission();

    // Save initial FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      await _fs.saveFcmToken(uid, token);
    }

    // Token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      await _fs.saveFcmToken(uid, newToken);
    });

    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      final notif = msg.notification;
      if (notif != null) {
        _showLocalNotification(notif.title, notif.body);
      }
    });
  }

  static Future<void> _showLocalNotification(String? title, String? body) async {
    const androidDetails = AndroidNotificationDetails(
      'sos_high_priority_channel',
      'SOS Alerts',
      channelDescription: 'High priority SOS alerts',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
