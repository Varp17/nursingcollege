// services/notification_service.dart
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // 🔥 FIXED: Renamed from initPlugin to initialize
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidSettings);

    final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    await _localNotificationsPlugin.initialize(initializationSettings);

    // Create emergency notification channel
    await _createEmergencyChannel();
  }

  static Future<void> _createEmergencyChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sos_emergency_channel', // id
      'SOS Emergency Alerts', // title
      description: 'Highest priority emergency notifications',
      importance: Importance.max,
      // 🔥 FIXED: Removed 'priority' parameter
      playSound: true,
      enableVibration: true,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 🔥 FIXED: Initialize method for user-specific setup
  Future<void> init(String userId) async {
    // Your existing user initialization code here
    print('NotificationService initialized for user: $userId');
  }

  // 🔥 HIGH-PRIORITY EMERGENCY NOTIFICATION
  Future<void> showEmergencySOSNotification({
    required String studentName,
    required String location,
    required String incidentId,
  }) async {
    // 🔥 FIXED: Removed const and fixed parameters
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_emergency_channel',
      'SOS Emergency Alerts',
      channelDescription: 'Highest priority emergency notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: Color(0xFFFF0000),
      ledColor: Color(0xFFFF0000),
      ledOnMs: 1000,
      ledOffMs: 1000,
      timeoutAfter: 60000,
      autoCancel: false,
      ongoing: true,
    );

    final NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚨 EMERGENCY SOS ALERT',
      '$studentName needs immediate help at $location',
      platformDetails,
      payload: incidentId,
    );

    // Vibrate device
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 2000);
    }

    print('🔔 HIGH-PRIORITY SOS Notification shown');
  }
}