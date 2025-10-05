import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _fs = FirestoreService();

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  /// Initialize plugin
  static Future<void> initPlugin() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!);
          if (data.containsKey('incidentId')) {
            Navigator.of(MyApp.navigatorKey.currentContext!).pushNamed(
              '/emergency',
              arguments: {'incidentId': data['incidentId']},
            );
          }
        }
      },
    );

    if (Platform.isAndroid) await Permission.notification.request();
  }

  /// Initialize FCM
  Future<void> init(String uid) async {
    await _fcm.requestPermission();

    final token = await _fcm.getToken();
    if (token != null) await _fs.saveFcmToken(uid, token);

    _fcm.onTokenRefresh.listen((newToken) async {
      await _fs.saveFcmToken(uid, newToken);
    });

    final role = await _fs.getUserRole(uid);
    if (role == "security") await _fcm.subscribeToTopic("security");

    FirebaseMessaging.onMessage.listen((msg) {
      final notif = msg.notification;
      final data = msg.data;

      if (notif != null) {
        _showLocalNotification(notif.title, notif.body, data);
      }

      if (data.containsKey('incidentId') &&
          MyApp.navigatorKey.currentContext != null) {
        final incidentId = data['incidentId'];
        FirebaseFirestore.instance
            .collection('incidents')
            .doc(incidentId)
            .get()
            .then((doc) {
          if (doc.exists) {
            final incident = doc.data()!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showPopupOverlay(
                  MyApp.navigatorKey.currentContext!, incident, incidentId);
            });
          }
        });
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final data = msg.data;
      if (data.containsKey('incidentId')) {
        Navigator.of(MyApp.navigatorKey.currentContext!).pushNamed(
          '/emergency',
          arguments: {'incidentId': data['incidentId']},
        );
      }
    });
  }

  /// Local notification
  static Future<void> _showLocalNotification(
      String? title, String? body, Map<String, dynamic> data) async {
    const androidDetails = AndroidNotificationDetails(
      'sos_alerts',
      'SOS Alerts',
      channelDescription: 'High priority SOS alerts',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
    );

    final details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  /// Popup overlay
  static void _showPopupOverlay(
      BuildContext context, Map<String, dynamic> data, String incidentId) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.black38.withOpacity(0.6),
          child: DraggableScrollableSheet(
            initialChildSize: 0.35,
            maxChildSize: 0.6,
            minChildSize: 0.25,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    "⚠️ ${data['type'] ?? 'SOS'} Alert",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("Student: ${data['studentName'] ?? 'Anonymous'}"),
                  const SizedBox(height: 4),
                  Text("Location: ${data['location'] ?? 'Unknown'}"),
                  const SizedBox(height: 4),
                  Text("Description: ${data['description'] ?? 'None'}"),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('incidents')
                              .doc(incidentId)
                              .update({
                            'status': 'acknowledged',
                            'acknowledged_at': FieldValue.serverTimestamp(),
                          });
                          overlayEntry.remove();
                        },
                        child: const Text("Acknowledge"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('incidents')
                              .doc(incidentId)
                              .update({
                            'status': 'resolved',
                            'resolved_at': FieldValue.serverTimestamp(),
                          });
                          overlayEntry.remove();
                        },
                        child: const Text("Resolve"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 10), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }
}
