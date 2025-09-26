import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/side_menu.dart';

class ManageUsersScreen extends StatelessWidget {
  final String username;
  final UserRole role;

  ManageUsersScreen({super.key, required this.username, required this.role});

  final CollectionReference usersRef =
  FirebaseFirestore.instance.collection('users');

  void _updateRole(String userId, String newRole) {
    usersRef.doc(userId).update({'role': newRole, 'approved': true});
  }

  void _approveUser(String userId) {
    usersRef.doc(userId).update({'approved': true});
  }

  final List<String> _roles = ['student', 'admin', 'security'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      drawer: SideMenu(role: role, username: username),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("No users available"));
          }

          // Separate pending approval users
          final pendingUsers = users.where((user) {
            final data = user.data() as Map<String, dynamic>;
            return (data['approved'] ?? false) == false;
          }).toList();

          // Users grouped by role, excluding pending
          final roleUsers = <String, List<QueryDocumentSnapshot>>{};
          for (var roleType in _roles) {
            roleUsers[roleType] = users.where((user) {
              final data = user.data() as Map<String, dynamic>;
              return data['role'] == roleType && (data['approved'] ?? false) == true;
            }).toList();
          }

          return ListView(
            children: [
              if (pendingUsers.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Pending Approval", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...pendingUsers.map((user) {
                  final data = user.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['name'] ?? 'No Name'),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveUser(user.id),
                      tooltip: 'Approve user',
                    ),
                  );
                }).toList(),
                const Divider(),
              ],

              // Display users by role
              ..._roles.map((roleType) {
                final list = roleUsers[roleType]!;
                if (list.isEmpty) return const SizedBox();

                return ExpansionTile(
                  title: Text(
                    roleType[0].toUpperCase() + roleType.substring(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: list.map((user) {
                    final data = user.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name'] ?? 'No Name'),
                      subtitle: Text(data['email'] ?? ''),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.edit),
                        onSelected: (value) => _updateRole(user.id, value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'admin', child: Text('Admin')),
                          const PopupMenuItem(value: 'security', child: Text('Security')),
                          const PopupMenuItem(value: 'student', child: Text('Student')),
                        ],
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
