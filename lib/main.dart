import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'common/side_menu.dart';
import 'firebase_options.dart';

// Services
import 'services/auth_service.dart';

// Screens
import 'login_screen.dart';
import 'register_screen.dart';
import 'student/student_dashboard.dart';
import 'security/security_dashboard.dart';
import 'admin/manage_users_screen.dart';
import 'superadmin/superadmin_dashboard.dart';

// --- NOTIFICATIONS SETUP ---
// Global notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Background handler for FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");

  final notification = message.notification;
  if (notification != null) {
    const androidDetails = AndroidNotificationDetails(
      'sos_high_priority_channel',
      'SOS Alerts',
      channelDescription: 'High priority SOS alerts',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      ticker: 'SOS Alert',
    );

    const platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
    );
  }
}

// --- MAIN APP ENTRY ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Create notification channel
  const AndroidNotificationChannel sosChannel = AndroidNotificationChannel(
    'sos_high_priority_channel',
    'SOS Alerts',
    description: 'High priority SOS alerts',
    importance: Importance.max,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(sosChannel);

  // Init plugin
  const initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Ask notification permission (Android 13+)
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }

  runApp(const MyApp());
}

// --- APP WIDGETS ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nursing College Safety App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LandingScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/student': (context) => const StudentDashboard(username: 'User', role: UserRole.student,),
        '/security': (context) => SecurityDashboard(username: 'User', role: UserRole.security,),
        '/admin': (context) => ManageUsersScreen(username: 'User', role: UserRole.admin,),
        '/superadmin': (context) => const SuperAdminDashboard(username: 'User', role: UserRole.superadmin,),
      },

    );
  }
}

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ChooseAuthScreen();
        }

        final user = snapshot.data!;
        return FutureBuilder<String?>(
          future: AuthService().getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (!roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final roleStr = roleSnapshot.data ?? "student"; // default
            final username = user.displayName ?? "User";

            switch (roleStr) {
              case "student":
                return StudentDashboard(
                  username: username,
                  role: UserRole.student,
                );
              case "security":
                return SecurityDashboard(
                  username: username,
                  role: UserRole.security,
                );
              case "admin":
                return ManageUsersScreen(
                  username: username,
                  role: UserRole.admin,
                );
              case "superadmin":
                return SuperAdminDashboard(
                  username: username,
                  role: UserRole.superadmin,
                );
              default:
                return const Scaffold(
                  body: Center(child: Text("Unknown role")),
                );
            }
          },
        );
      },
    );
  }
}

class ChooseAuthScreen extends StatelessWidget {
  const ChooseAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nursing College Safety")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text("Register"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
