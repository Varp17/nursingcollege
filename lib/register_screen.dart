import 'package:collegesafety/profile_completion_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'common/side_menu.dart';
import 'student/student_dashboard.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  get label => null;

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
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user info in Firestore
      await _firestore.collection("users").doc(userCred.user!.uid).set({
        "name": _nameController.text.trim(),
        "age": _ageController.text.trim(),
        "email": _emailController.text.trim(),
        "role": "student",      // default role
        "approved": false,      // <- newly added
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled Google sign-in
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred = await _auth.signInWithCredential(credential);

      // Check if user already exists
      DocumentSnapshot userDoc =
      await _firestore.collection("users").doc(userCred.user!.uid).get();

      if (!userDoc.exists) {
        // Create basic record
        await _firestore.collection("users").doc(userCred.user!.uid).set({
          "name": userCred.user!.displayName ?? "",
          "age": "",
          "email": userCred.user!.email ?? "",
          "role": "student",      // default role
          "approved": false,      // <- newly added
        });


        // Navigate to profile completion screen
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileCompletionScreen()),
        );
      } else {
        // Check if profile is incomplete (age not set)
        final data = userDoc.data() as Map<String, dynamic>;
        final hasAge =
        (data["age"] != null && data["age"].toString().isNotEmpty);

        if (!mounted) return;
        if (!hasAge) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileCompletionScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDashboard(
                username: data["name"] ?? "Student",
                role: UserRole.student,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration:
                const InputDecoration(labelText: "Full Name"),
              ),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registerWithEmail,
                child: const Text("Register with Email"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _registerWithGoogle,
                icon: Image.asset(
                  'assets/google_logo.png',
                  width: 24,
                  height: 24,
                ),
                label: const Text("Sign in with Google"),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
