// student/student_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/side_menu.dart';

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
    final complaints = [
      "Harassment",
      "Ragging",
      "Patient Violence",
      "Fighting in Parking",
      "Student Needs Help",
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),
      drawer: SideMenu(role: role, username: username),
      body: ListView.builder(
        itemCount: complaints.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(complaints[index]),
              trailing: const Icon(Icons.report),
              onTap: () async {
                try {
                  await FirebaseFirestore.instance.collection("complaints").add({
                    "type": complaints[index],
                    "userId": FirebaseAuth.instance.currentUser!.uid,
                    "timestamp": FieldValue.serverTimestamp(),
                    "status": "pending",
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${complaints[index]} reported!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to report: $e")),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
