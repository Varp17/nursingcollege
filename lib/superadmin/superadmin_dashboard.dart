// superadmin/superadmin_dashboard.dart
import 'package:flutter/material.dart';
import '../common/side_menu.dart';
import 'manage_users_screen.dart';
import '../models/user_role.dart'; // use the single UserRole enum

class SuperAdminDashboard extends StatelessWidget {
  final String username;
  final UserRole role;

  const SuperAdminDashboard({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Super Admin Dashboard")),
      drawer: SideMenu(role: role, username: username),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Assign roles & manage users",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.manage_accounts),
              label: const Text("Manage Users"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageUsersScreen(
                      username: username,
                      role: role,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
