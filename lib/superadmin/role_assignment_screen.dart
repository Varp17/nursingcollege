// superadmin/role_assignment_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleAssignmentScreen extends StatelessWidget {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Role Assignment'),
        backgroundColor: Colors.green.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Text(
                'Role Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ...users.map((user) {
                final data = user.data() as Map<String, dynamic>;
                return _RoleAssignmentCard(user: user, userData: data);
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}

class _RoleAssignmentCard extends StatelessWidget {
  final QueryDocumentSnapshot user;
  final Map<String, dynamic> userData;

  const _RoleAssignmentCard({required this.user, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(userData['name']?[0] ?? 'U'),
        ),
        title: Text(userData['name'] ?? 'Unknown User'),
        subtitle: Text(userData['email'] ?? 'No email'),
        trailing: DropdownButton<String>(
          value: userData['role'] ?? 'student',
          items: ['student', 'security', 'admin'].map((String role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.toUpperCase()),
            );
          }).toList(),
          onChanged: (newRole) {
            if (newRole != null) {
              user.reference.update({'role': newRole});
            }
          },
        ),
      ),
    );
  }
}