// lib/main.dart
import 'package:collegesafety/security/emergency_alert_screen.dart';
import 'package:collegesafety/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';

// Screens
import 'login_screen.dart';
import 'register_screen.dart';
import 'student/student_dashboard.dart';
import 'security/security_dashboard.dart';
import 'admin/manage_users_screen.dart';
import 'superadmin/superadmin_dashboard.dart';
import 'models/user_role.dart';

// --- COMPLETE BACKGROUND HANDLER ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔔 Background message received: ${message.notification?.title}");

  // Handle SOS alerts in background
  if (message.data['type'] == 'sos_alert') {
    final studentName = message.data['studentName'] ?? 'Student';
    final location = message.data['location'] ?? 'Unknown Location';
    final incidentId = message.data['incidentId'] ?? '';

    print("🚨 EMERGENCY SOS in background:");
    print("   Student: $studentName");
    print("   Location: $location");
    print("   Incident ID: $incidentId");

    // Show local notification for background SOS
    await _showBackgroundSOSNotification(studentName, location, incidentId);
  }
}

// Show notification when app is in background/terminated
Future<void> _showBackgroundSOSNotification(String studentName, String location, String incidentId) async {
  try {
    final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize notifications for background
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidSettings);
    await notificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_emergency_channel',
      'SOS Emergency Alerts',
      channelDescription: 'High priority emergency SOS notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚨 EMERGENCY SOS ALERT',
      '$studentName needs help at $location',
      platformDetails,
      payload: incidentId,
    );

    print("📲 Background SOS notification shown");
  } catch (e) {
    print("❌ Error showing background notification: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Init Notifications
  await NotificationService.initialize();
  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔥 ADDED: Configure foreground notification options
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, // Show alert when in foreground
    badge: true, // Update badge when in foreground
    sound: true, // Play sound when in foreground
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nursing College Safety',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            final uid = snapshot.data!.uid;
            // Fetch user details from Firestore
            return FutureBuilder<Map<String, dynamic>?>(
              future: FirestoreService().getUserDetails(uid),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final userData = userSnapshot.data!;
                final roleString = userData['role'] as String?;
                final role = FirestoreService().mapRoleFromString(roleString);
                final username = userData['name'] ?? 'User';

                // Initialize FCM for this user
                NotificationService().init(uid);

                // Navigate to role-specific dashboard
                switch (role) {
                  case UserRole.student:
                    return StudentDashboard(username: username, role: role);
                  case UserRole.security:
                    return SecurityDashboard(username: username, role: role);
                  case UserRole.admin:
                    return ManageUsersScreen(username: username, role: role);
                  case UserRole.superadmin:
                    return SuperAdminDashboard(username: username, role: role);
                  }
              },
            );
          } else {
            // User not logged in, show LoginScreen
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/student': (context) => StudentDashboard(
          username: 'User',
          role: UserRole.student,
        ),
        '/security': (context) => SecurityDashboard(
          username: 'User',
          role: UserRole.security,
        ),
        '/emergency': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return EmergencyAlertScreen(incidentId: args['incidentId']);
        },
        '/admin': (context) => ManageUsersScreen(
          username: 'User',
          role: UserRole.admin,
        ),
        '/superadmin': (context) => SuperAdminDashboard(
          username: 'User',
          role: UserRole.superadmin,
        ),
      },
    );
  }
}