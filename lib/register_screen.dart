import 'package:collegesafety/profile_completion_screen.dart';
import 'package:collegesafety/security/security_dashboard.dart';
import 'package:collegesafety/superadmin/superadmin_dashboard.dart';
import 'package:collegesafety/widgets/custom_button.dart';
import 'package:collegesafety/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'admin/manage_users_screen.dart';
import 'student/student_dashboard.dart';
import '../models/user_role.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;

  String _role = "student"; // default role
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _registerWithEmail() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection("users").doc(userCred.user!.uid).set({
        "name": _nameController.text.trim(),
        "age": _ageController.text.trim(),
        "email": _emailController.text.trim(),
        "role": _role,
        "approved": false,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDashboard(
            username: _nameController.text.trim(),
            role: UserRole.student,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final userDoc = await _firestore.collection("users").doc(userCred.user!.uid).get();

      if (!userDoc.exists) {
        await _firestore.collection("users").doc(userCred.user!.uid).set({
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
      final approved = data["approved"] ?? false;
      final roleStr = data["role"] ?? "student";
      final username = data["name"] ?? "Student";

      if (!approved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Waiting for Admin approval")),
        );
        return;
      }

      if (!hasAge) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileCompletionScreen()),
        );
        return;
      }

      if (!mounted) return;
      switch (roleStr) {
        case "student":
          Navigator.pushReplacement(
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Google sign-in failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    borderRadius: BorderRadius.circular(24)),
                elevation: 8,
                shadowColor: Colors.black45,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Register",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _nameController,
                        hint: "Full Name",
                        prefixIcon: const Icon(Icons.person),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _ageController,
                        hint: "Age",
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.cake),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        hint: "Email",
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        hint: "Password",
                        obscure: true,
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: CustomButton(
                          label: _isLoading
                              ? "Registering..."
                              : "Register with Email",
                          onPressed: _isLoading ? null : _registerWithEmail,
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
                        child: ElevatedButton.icon(
                          icon: Image.asset('assets/google_logo.png', width: 24, height: 24),
                          label: const Text("Sign in with Google"),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _registerWithGoogle,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: const Text(
                          "Already have an account? Login",
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
