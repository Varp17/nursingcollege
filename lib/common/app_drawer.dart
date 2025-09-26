import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatelessWidget {
  final String role;

  const AppDrawer({super.key, required this.role});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.person, size: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),

          // Common items
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          if (role == "student") ...[
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text("Report Complaint"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],

          if (role == "security") ...[
            ListTile(
              leading: const Icon(Icons.shield),
              title: const Text("Pending Complaints"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],

          if (role == "admin") ...[
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Manage Users"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text("All Complaints"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
