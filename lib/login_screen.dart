// lib/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collegesafety/profile_completion_screen.dart';
import 'package:collegesafety/widgets/custom_button.dart';
import 'package:collegesafety/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'admin/admin_dashboard.dart';
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
  final AuthService _authService = AuthService();

  void _login() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Superadmin bypass
      if (emailCtrl.text == "codinghunter0@gmail.com" && passCtrl.text == "123456") {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuperAdminDashboard(
              username: "SuperAdmin",
              role: UserRole.superadmin,
            ),
          ),
        );
        return;
      }

      final user = await _authService.login(emailCtrl.text.trim(), passCtrl.text.trim());
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed - user not found')),
        );
        return;
      }

      // Check if user exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User account not found in system')),
        );
        await _authService.logout();
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'] ?? 'student';
      final approved = await _authService.isApproved(user.uid);
      final username = userData['name'] ?? 'User';

      if (!approved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account pending admin approval'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Check if profile is complete (for students)
      if (role == 'student') {
        final profileComplete = await _authService.isProfileComplete(user.uid);
        if (!profileComplete) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileCompletionScreen()),
          );
          return;
        }
      }

      // Navigate to appropriate dashboard
      await _navigateToDashboard(role, username, user.uid);

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _navigateToDashboard(String role, String username, String uid) async {
    if (!mounted) return;

    switch (role) {
      case "student":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDashboard(
              username: username,
              role: UserRole.student,
            ),
          ),
        );
        break;
      case "security":
      // Initialize security status
        await _initializeSecurityStatus(uid, username);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SecurityDashboard(
              username: username,
              role: UserRole.security,
            ),
          ),
        );
        break;
      case "admin":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(
              username: username,
              role: UserRole.admin,
            ),
          ),
        );
        break;
      case "superadmin":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuperAdminDashboard(
              username: username,
              role: UserRole.superadmin,
            ),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unknown user role: $role")),
        );
    }
  }

  Future<void> _initializeSecurityStatus(String uid, String username) async {
    try {
      await FirebaseFirestore.instance
          .collection('security_status')
          .doc(uid)
          .set({
        'status': 'Available',
        'name': username,
        'userId': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error initializing security status: $e');
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => loading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => loading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;

      if (user == null) {
        throw Exception('Google sign-in failed - no user returned');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // First-time Google login - create user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          "uid": user.uid,
          "name": user.displayName ?? "",
          "email": user.email ?? "",
          "role": "student",
          "approved": false, // Students need admin approval
          "createdAt": FieldValue.serverTimestamp(),
          "age": "",
          "college": "",
          "section": "",
          "phone": "",
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileCompletionScreen()),
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'] ?? 'student';
      final approved = await _authService.isApproved(user.uid);
      final username = userData['name'] ?? user.displayName ?? 'User';

      if (!approved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Waiting for Admin approval"),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Check profile completion for students
      if (role == 'student') {
        final profileComplete = await _authService.isProfileComplete(user.uid);
        if (!profileComplete) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileCompletionScreen()),
          );
          return;
        }
      }

      // Initialize security status if security user
      if (role == 'security') {
        await _initializeSecurityStatus(user.uid, username);
      }

      // Navigate to dashboard
      await _navigateToDashboard(role, username, user.uid);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google sign-in failed: ${e.toString()}")),
        );
      }
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
                      // App Logo/Title
                      Column(
                        children: [
                          Icon(
                            Icons.security,
                            size: 60,
                            color: Colors.deepPurple,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Campus Safety',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Emergency Response System',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Login Form
                      CustomTextField(
                        controller: emailCtrl,
                        hint: 'Email Address',
                        prefixIcon: const Icon(Icons.email),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: passCtrl,
                        hint: 'Password',
                        obscure: true,
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        height: 50,
                        child: CustomButton(
                          label: loading ? 'Signing in...' : 'Login to Dashboard',
                          onPressed: loading ? null : _login,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "OR",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          Expanded(child: Divider(thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Google Sign In
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: Image.asset(
                            'assets/google_logo.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.account_circle, size: 24),
                          ),
                          label: Text(
                            'Sign in with Google',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: loading ? null : _googleSignIn,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            child: const Text(
                              "Register Now",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      // Demo Credentials Hint
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demo Access:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'SuperAdmin: codinghunter0@gmail.com / 123456',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontSize: 10,
                              ),
                            ),
                          ],
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

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}