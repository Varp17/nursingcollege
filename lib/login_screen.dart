import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'student/student_dashboard.dart';
import 'security/security_dashboard.dart';
import 'admin/manage_users_screen.dart';
import 'superadmin/superadmin_dashboard.dart';
import 'common/side_menu.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  void _login() async {
    setState(() => loading = true);
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    try {
      // Superadmin bypass
      if (email == "codinghunter0@gmail.com" && pass == "123456") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SuperAdminDashboard(
              username: "SuperAdmin",
              role: UserRole.superadmin,
            ),
          ),
        );
        return;
      }

      final user = await AuthService().login(email, pass);
      if (user == null) return;

      final roleStr = await AuthService().getUserRole(user.uid);
      final approved = await AuthService().isApproved(user.uid);

      if (!approved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Waiting for Admin approval")),
        );
        return;
      }

      final username = user.displayName ?? "User";

      if (roleStr == "student") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDashboard(
              username: username,
              role: UserRole.student,
            ),
          ),
        );
      } else if (roleStr == "security") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SecurityDashboard(
              username: username,
              role: UserRole.security,
            ),
          ),
        );
      } else if (roleStr == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ManageUsersScreen(
              username: username,
              role: UserRole.admin,
            ),
          ),
        );
      } else if (roleStr == "superadmin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuperAdminDashboard(
              username: username,
              role: UserRole.superadmin,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unknown role")),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _login,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
