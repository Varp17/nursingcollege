// lib/main.dart
import 'package:collegesafety/security/emergency_alert_screen.dart';
import 'package:collegesafety/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';

// Enhanced Providers
import 'providers/sos_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

// Screens
import 'login_screen.dart';
import 'register_screen.dart';
import 'student/student_dashboard.dart';
import 'security/security_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'superadmin/superadmin_dashboard.dart';
import 'models/user_role.dart';

// Enhanced Background Handler with Vibration
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔔 Background message received: ${message.notification?.title}");

  // Handle SOS alerts in background with vibration
  if (message.data['type'] == 'sos_alert') {
    final studentName = message.data['studentName'] ?? 'Student';
    final location = message.data['location'] ?? 'Unknown Location';
    final incidentId = message.data['incidentId'] ?? '';
    final emergencyType = message.data['emergencyType'] ?? 'Emergency';

    print("🚨 EMERGENCY SOS in background:");
    print("   Student: $studentName");
    print("   Location: $location");
    print("   Type: $emergencyType");

    // Trigger vibration for emergency alerts
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [1000, 500, 1000, 500, 1000]);
      }
    } catch (e) {
      print("Vibration error: $e");
    }

    // Show enhanced background notification
    await _showEnhancedBackgroundSOSNotification(studentName, location, emergencyType, incidentId);
  }
}

// Enhanced background notification with emergency styling
Future<void> _showEnhancedBackgroundSOSNotification(
    String studentName, String location, String emergencyType, String incidentId) async {
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
      channelDescription: 'High priority emergency SOS notifications with vibration',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('emergency_alert'),
      colorized: true,
      color: Color(0xFFD32F2F),
      ledColor: Color(0xFFD32F2F),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚨 $emergencyType - $location',
      '$studentName needs immediate assistance! Tap to respond.',
      platformDetails,
      payload: incidentId,
    );

    print("📲 Enhanced background SOS notification shown with vibration");
  } catch (e) {
    print("❌ Error showing enhanced background notification: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize enhanced services
  await NotificationService.initialize();

  // Register enhanced background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Configure foreground notification options
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SosProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Nursing College Safety',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.red,
              primaryColor: Color(0xFFD32F2F),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(
                backgroundColor: Color(0xFFD32F2F),
                foregroundColor: Colors.white,
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.red,
              primaryColor: Color(0xFFD32F2F),
              scaffoldBackgroundColor: Color(0xFF121212),
              appBarTheme: AppBarTheme(
                backgroundColor: Color(0xFF1E1E1E),
              ),
            ),
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingScreen();
                }

                if (snapshot.hasData && snapshot.data != null) {
                  return _buildRoleBasedHome(snapshot.data!);
                } else {
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
              '/admin': (context) => AdminDashboard(
                username: 'User',
                role: UserRole.admin,
              ),
              '/superadmin': (context) => SuperAdminDashboard(
                username: 'User',
                role: UserRole.superadmin,
              ),
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Color(0xFFD32F2F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Nursing College Safety',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'Loading Safety System...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBasedHome(User user) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: FirestoreService().getUserDetails(user.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return const LoginScreen();
        }

        final userData = userSnapshot.data!;
        final roleString = userData['role'] as String?;
        final role = FirestoreService().mapRoleFromString(roleString);
        final username = userData['name'] ?? 'User';

        // Initialize enhanced services
        NotificationService().init(user.uid);
        _initializeRoleBasedServices(role, user.uid);

        // Navigate to role-specific dashboard
        switch (role) {
          case UserRole.student:
            return StudentDashboard(username: username, role: role);
          case UserRole.security:
            return SecurityDashboard(username: username, role: role);
          case UserRole.admin:
            return AdminDashboard(username: username, role: role);
          case UserRole.superadmin:
            return SuperAdminDashboard(username: username, role: role);
        }
      },
    );
  }

  void _initializeRoleBasedServices(UserRole role, String userId) {
    final sosProvider = Provider.of<SosProvider>(navigatorKey.currentContext!, listen: false);

    switch (role) {
      case UserRole.security:
        sosProvider.listenToActiveAlerts();
        break;
      case UserRole.student:
        sosProvider.listenToMyComplaints(userId);
        break;
      case UserRole.admin:
      case UserRole.superadmin:
        sosProvider.listenToActiveAlerts();
        sosProvider.listenToSolvedComplaints();
        break;
    }
  }
}