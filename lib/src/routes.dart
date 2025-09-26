import 'package:flutter/material.dart';
import '../common/side_menu.dart';
import '../login_screen.dart';
import '../register_screen.dart';
import '../student/student_dashboard.dart';
import '../security/security_dashboard.dart';
import '../admin/manage_users_screen.dart';
import '../superadmin/superadmin_dashboard.dart';

class AppRoutes {
  static const login = "/login";
  static const register = "/register";
  static const studentDashboard = "/student";
  static const securityDashboard = "/security";
  static const adminDashboard = "/admin";
  static const superAdminDashboard = "/superadmin";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    final username = args?['username'] as String? ?? "User";
    final role = args?['role'];

    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case studentDashboard:
        return MaterialPageRoute(
          builder: (_) => StudentDashboard(
            username: username,
            role: role ?? UserRole.student,
          ),
        );
      case securityDashboard:
        return MaterialPageRoute(
          builder: (_) => SecurityDashboard(
            username: username,
            role: role ?? UserRole.security,
          ),
        );
      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => ManageUsersScreen(
            username: username,
            role: role ?? UserRole.admin,
          ),
        );
      case superAdminDashboard:
        return MaterialPageRoute(
          builder: (_) => SuperAdminDashboard(
            username: username,
            role: role ?? UserRole.superadmin,
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
