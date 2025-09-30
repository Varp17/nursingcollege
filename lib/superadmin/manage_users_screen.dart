import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/side_menu.dart';
import '../models/user_role.dart'; // unified UserRole enum

class ManageUsersScreen extends StatelessWidget {
  final String username;
  final UserRole role;

  ManageUsersScreen({super.key, required this.username, required this.role});

  final CollectionReference usersRef =
  FirebaseFirestore.instance.collection('users');

  final List<String> _roles = ['student', 'admin', 'security'];

  void _updateRole(BuildContext context, String userId, String newRole) {
    usersRef.doc(userId).update({'role': newRole, 'approved': true});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("User role updated to $newRole")),
    );
  }

  void _approveUser(BuildContext context, String userId, String name) {
    usersRef.doc(userId).update({'approved': true});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$name approved!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      drawer: SideMenu(role: role, username: username),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("No users available"));
          }

          // Pending approval users
          final pendingUsers = users.where((user) {
            final data = user.data() as Map<String, dynamic>;
            return (data['approved'] ?? false) == false;
          }).toList();

          // Approved users grouped by role
          final roleUsers = <String, List<QueryDocumentSnapshot>>{};
          for (var roleType in _roles) {
            roleUsers[roleType] = users.where((user) {
              final data = user.data() as Map<String, dynamic>;
              return data['role'] == roleType && (data['approved'] ?? false) == true;
            }).toList();
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // Pending approvals
              if (pendingUsers.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Pending Approval",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...pendingUsers.map((user) {
                  final data = user.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['email'] ?? ''),
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        onPressed: () => _approveUser(context, user.id, data['name'] ?? ''),
                      ),
                    ),
                  );
                }).toList(),
                const Divider(),
              ],

              // Approved users grouped by role
              ..._roles.map((roleType) {
                final list = roleUsers[roleType]!;
                if (list.isEmpty) return const SizedBox();

                return ExpansionTile(
                  initiallyExpanded: true,
                  leading: Icon(
                    roleType == 'student'
                        ? Icons.school
                        : roleType == 'admin'
                        ? Icons.admin_panel_settings
                        : Icons.security,
                    color: Colors.blueAccent,
                  ),
                  title: Text(
                    roleType[0].toUpperCase() + roleType.substring(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: list.map((user) {
                    final data = user.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(data['role'][0].toUpperCase()),
                        ),
                        title: Text(data['name'] ?? 'No Name'),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.edit),
                          onSelected: (value) => _updateRole(context, user.id, value),
                          itemBuilder: (context) => _roles
                              .map((r) => PopupMenuItem(
                              value: r, child: Text(r[0].toUpperCase() + r.substring(1))))
                              .toList(),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
