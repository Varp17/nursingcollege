// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _fs = FirestoreService();

  Future<void> init(String uid) async {
    // Request permission (ios)
    await _fcm.requestPermission();

    // Get token
    final token = await _fcm.getToken();
    if (token != null) {
      await _fs.saveFcmToken(uid, token);
    }

    // Handle background messages via onBackgroundMessage in main.dart
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      // handle foreground notification (show dialog / in-app banner)
      print('Foreground message: ${msg.notification?.title}');
    });
  }
}
