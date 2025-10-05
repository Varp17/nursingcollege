// student/student_dashboard.dart
import 'package:collegesafety/student/student_sos_screen.dart';
import 'package:flutter/material.dart';
import '../common/side_menu.dart';
import '../models/user_role.dart'; // use the single UserRole enum


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
        child: GestureDetector(
          onTap: () {
            // Navigate to SOS screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentSosScreen()),
            );
          },
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.6),
                  spreadRadius: 8,
                  blurRadius: 16,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              "SOS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}