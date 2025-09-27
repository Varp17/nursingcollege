// lib/student/student_dashboard.dart

import 'package:flutter/material.dart';
import '../common/side_menu.dart';
import 'student_sos_screen.dart'; // <-- NEW

class StudentDashboard extends StatelessWidget {
  final String username;
  final UserRole role;

  const StudentDashboard({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),
      drawer: SideMenu(role: role, username: username),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.sos, size: 32),
            label: const Text(
              "EMERGENCY SOS",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentSosScreen()),
              );
            },
          ),
        ),
      ),
    );
  }
}
