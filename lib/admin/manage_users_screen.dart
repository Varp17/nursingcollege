import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';

class ManageUsersScreen extends StatefulWidget {
  final String username;
  final UserRole role;

  const ManageUsersScreen({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _departments = [
    'Nursing',
    'Medical-Surgical',
    'Pediatrics',
    'Obstetrics',
    'Psychiatric',
    'Community Health',
    'Administration',
    'Security',
    'General'
  ];

  void _updateRole(String uid, String newRole, String? department) {
    _firestore.collection('users').doc(uid).update({
      'role': newRole,
      'department': department,
      'updatedBy': widget.username,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showEditDialog(BuildContext context, DocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>;
    String selectedRole = data['role'] ?? 'student';
    String selectedDepartment = data['department'] ?? 'General';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit User Role & Department'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student Nurse')),
                    DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                    DropdownMenuItem(value: 'hod', child: Text('HOD')),
                    DropdownMenuItem(value: 'security', child: Text('Security')),
                    DropdownMenuItem(value: 'admin', child: Text('Department Admin')),
                  ],
                  onChanged: (value) => setState(() => selectedRole = value!),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  items: _departments.map((dept) {
                    return DropdownMenuItem(value: dept, child: Text(dept));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedDepartment = value!),
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _updateRole(user.id, selectedRole, selectedDepartment);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated successfully')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users - Nursing College'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(data['name']?[0].toUpperCase() ?? 'U'),
                  ),
                  title: Text(data['name'] ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['email'] ?? 'No Email'),
                      Text('Role: ${data['role']?.toString().toUpperCase() ?? 'N/A'}'),
                      Text('Department: ${data['department'] ?? 'Not Assigned'}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showEditDialog(context, user);
                      } else if (action == 'view') {
                        // View user details
                        _showUserDetails(context, data);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Role/Dept')),
                      const PopupMenuItem(value: 'view', child: Text('View Details')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Name: ${data['name'] ?? 'N/A'}'),
            Text('Email: ${data['email'] ?? 'N/A'}'),
            Text('Role: ${data['role'] ?? 'N/A'}'),
            Text('Department: ${data['department'] ?? 'Not Assigned'}'),
            Text('User ID: ${data['uid'] ?? 'N/A'}'),
            if (data['createdAt'] != null)
              Text('Joined: ${(data['createdAt'] as Timestamp).toDate().toString()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}