import 'package:flutter/material.dart';
import '../common/side_menu.dart';
import '../login_screen.dart';
import '../register_screen.dart';
import '../student/student_dashboard.dart';
import '../security/security_dashboard.dart';
import '../admin/manage_users_screen.dart';
import '../superadmin/superadmin_dashboard.dart';
import '../landing_screen.dart';
import '../models/user_role.dart'; // use the single UserRole enum

class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String student = '/student';
  static const String security = '/security';
  static const String admin = '/admin';
  static const String superadmin = '/superadmin';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case landing:
        return MaterialPageRoute(builder: (_) => const LandingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case student:
        return MaterialPageRoute(
          builder: (_) => const StudentDashboard(
            username: 'User',
            role: UserRole.student,
          ),
        );
      case security:
        return MaterialPageRoute(
          builder: (_) => SecurityDashboard(
            username: 'User',
            role: UserRole.security,
          ),
        );
      case admin:
        return MaterialPageRoute(
          builder: (_) => ManageUsersScreen(
            username: 'User',
            role: UserRole.admin,
          ),
        );
      case superadmin:
        return MaterialPageRoute(
          builder: (_) => const SuperAdminDashboard(
            username: 'User',
            role: UserRole.superadmin,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Unknown route")),
          ),
        );
    }
  }
}
