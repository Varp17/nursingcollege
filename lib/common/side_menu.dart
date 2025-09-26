import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../admin/manage_users_screen.dart';

enum UserRole { superadmin, admin, student, security }

class SideMenu extends StatelessWidget {
  final UserRole role;
  final String username;

  const SideMenu({super.key, required this.role, required this.username});

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login'); // Adjust login route
  }

  List<Widget> _getMenuItems(BuildContext context) {
    switch (role) {
      case UserRole.superadmin:
        return [
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Manage Admins'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Manage Users'),
            onTap: () {
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
        ];
      case UserRole.admin:
        return [
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Student Records'),
            onTap: () => Navigator.pop(context),
          ),
        ];
      case UserRole.student:
        return [
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('My Courses'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('My Schedule'),
            onTap: () => Navigator.pop(context),
          ),
        ];
      case UserRole.security:
        return [
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Check-in Logs'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Alerts'),
            onTap: () => Navigator.pop(context),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(username),
            accountEmail: Text(role.name.toUpperCase()),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text( username.isNotEmpty ? username[0].toUpperCase() : "?",
                style: const TextStyle(fontSize: 20),),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _getMenuItems(context),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
