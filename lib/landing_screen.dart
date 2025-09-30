import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'student/student_dashboard.dart';
import 'security/security_dashboard.dart';
import 'admin/manage_users_screen.dart';
import 'superadmin/superadmin_dashboard.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'models/user_role.dart'; // <-- add this at the top

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
                return StudentDashboard(username: username, role: UserRole.student);
              case "security":
                return SecurityDashboard(username: username, role: UserRole.security);
              case "admin":
                return ManageUsersScreen(username: username, role: UserRole.admin);
              case "superadmin":
                return SuperAdminDashboard(username: username, role: UserRole.superadmin);
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              child: const Text("Register"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
