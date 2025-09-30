import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'common/side_menu.dart';
import 'firebase_options.dart';
import 'landing_screen.dart';
import 'services/notification_service.dart';

// Screens
import 'login_screen.dart';
import 'register_screen.dart';
import 'student/student_dashboard.dart';
import 'security/security_dashboard.dart';
import 'admin/manage_users_screen.dart';
import 'superadmin/superadmin_dashboard.dart';
import 'services/auth_service.dart';
import '../models/user_role.dart'; // use the single UserRole enum


// --- BACKGROUND HANDLER ---
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Background message: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Init Notifications
  await NotificationService.initPlugin();

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nursing College Safety',
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
            // User is logged in, go to LandingScreen
            return const LandingScreen();
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

