// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collegesafety/profile_completion_screen.dart';
import 'package:collegesafety/widgets/custom_button.dart';
import 'package:collegesafety/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/auth_service.dart';
import 'student/student_dashboard.dart';
import 'security/security_dashboard.dart';
import 'admin/manage_users_screen.dart';
import 'superadmin/superadmin_dashboard.dart';
import '../models/user_role.dart';

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
        if (!mounted) return;
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

      switch (roleStr) {
        case "student":
          Navigator.pushReplacement(
            // ignore: duplicate_ignore
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (_) =>
                  StudentDashboard(username: username, role: UserRole.student),
            ),
          );
          break;
        case "security":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SecurityDashboard(username: username, role: UserRole.security),
            ),
          );
          break;
        case "admin":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ManageUsersScreen(username: username, role: UserRole.admin),
            ),
          );
          break;
        case "superadmin":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SuperAdminDashboard(username: username, role: UserRole.superadmin),
            ),
          );
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unknown role")),
          );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => loading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // canceled

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .get();

      if (!userDoc.exists) {
        // First-time Google login
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user!.uid)
            .set({
          "name": userCred.user!.displayName ?? "",
          "age": "",
          "email": userCred.user!.email ?? "",
          "role": "student",
          "approved": false,
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileCompletionScreen()),
        );
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final hasAge = data["age"] != null && data["age"].toString().isNotEmpty;
      final approved = data['approved'] ?? false;
      final roleStr = data['role'] ?? 'student';
      final username = data['name'] ?? 'User';

      if (!approved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Waiting for Admin approval")),
        );
        return;
      }

      if (!hasAge) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileCompletionScreen()),
        );
        return;
      }

      // Navigate to respective dashboard
      switch (roleStr) {
        case 'student':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  StudentDashboard(username: username, role: UserRole.student),
            ),
          );
          break;
        case 'security':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SecurityDashboard(username: username, role: UserRole.security),
            ),
          );
          break;
        case 'admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ManageUsersScreen(username: username, role: UserRole.admin),
            ),
          );
          break;
        case 'superadmin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SuperAdminDashboard(username: username, role: UserRole.superadmin),
            ),
          );
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unknown role")),
          );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Google sign-in failed: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 8,
                shadowColor: Colors.black45,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nursing College Safety',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: emailCtrl,
                        hint: 'Email',
                        prefixIcon: const Icon(Icons.email),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: passCtrl,
                        hint: 'Password',
                        obscure: true,
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: CustomButton(
                          label: loading ? 'Signing in...' : 'Login',
                          onPressed: loading ? null : _login,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Expanded(child: Divider(thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text("OR"),
                          ),
                          Expanded(child: Divider(thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: Image.asset('assets/google_logo.png', width: 24),
                          label: const Text(
                            'Sign in with Google',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          onPressed: loading ? null : _googleSignIn,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: const Text(
                          "Don't have an account? Register",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
