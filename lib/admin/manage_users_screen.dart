import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key, required String username, required role});

  void updateRole(String uid, String newRole) {
    FirebaseFirestore.instance.collection("users").doc(uid).update({
      "role": newRole,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                title: Text(user["name"] ?? "No Name"),
                subtitle: Text("${user["email"]} | Role: ${user["role"]}"),
                trailing: PopupMenuButton<String>(
                  onSelected: (newRole) => updateRole(user.id, newRole),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "student", child: Text("Student")),
                    const PopupMenuItem(value: "security", child: Text("Security")),
                    const PopupMenuItem(value: "teacher", child: Text("Teacher")),
                    const PopupMenuItem(value: "admin", child: Text("Admin")),
                    const PopupMenuItem(value: "superadmin", child: Text("Super Admin")),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
