//lib/common/side_menu.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_role.dart';
import '../admin/manage_users_screen.dart';
import '../student/student_complaints_screen.dart';
import '../student/student_courses_screen.dart';
import '../student/student_history_screen.dart';
import '../student/student_profile_screen.dart';
import '../student/student_reports_screen.dart';
import '../student/student_schedule_screen.dart';
import '../student/student_sos_screen.dart';
import '../superadmin/student_activities_screen.dart';
import '../superadmin/superadmin_dashboard.dart';
import '../security/pending_sos_screen.dart';
import '../student/student_dashboard.dart';
import '../security/security_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../security/security_alerts_screen.dart';
import '../superadmin/system_analytics_screen.dart';

class SideMenu extends StatelessWidget {
  final UserRole role;
  final String username;

  const SideMenu({super.key, required this.role, required this.username});

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  List<Widget> _getMenuItems(BuildContext context) {
    final commonItems = [
      ListTile(
        leading: const Icon(Icons.dashboard),
        title: const Text('Dashboard'),
        onTap: () {
          Navigator.pop(context);
          // Navigate to respective dashboard based on role
          switch (role) {
            case UserRole.superadmin:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SuperAdminDashboard(
                    username: username,
                    role: role,
                  ),
                ),
              );
              break;
            case UserRole.admin:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminDashboard(
                    username: username,
                    role: role,
                  ),
                ),
              );
              break;
            case UserRole.security:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SecurityDashboard(
                    username: username,
                    role: role,
                  ),
                ),
              );
              break;
            case UserRole.student:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentDashboard(
                    username: username,
                    role: role,
                  ),
                ),
              );
              break;
          }
        },
      ),
    ];

    final roleSpecificItems = <Widget>[];

    switch (role) {
      case UserRole.superadmin:
        roleSpecificItems.addAll([
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Manage Admins'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Add Manage Admins screen navigation
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Users'),
            onTap: () {
              Navigator.pop(context);
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
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('System Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SystemAnalyticsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.monitor_heart),
            title: Text('Student Activities'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => StudentActivitiesScreen(),
              ));
            },
          ),
        ]);
        break;

      case UserRole.admin:
        roleSpecificItems.addAll([
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Student Records'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Add Student Records screen navigation
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Pending SOS Alerts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PendingSOSScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('All Complaints'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Add All Complaints screen navigation
            },
          ),
          ListTile(
            leading: Icon(Icons.monitor_heart),
            title: Text('Student Activities'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => StudentActivitiesScreen(),
              ));
            },
          ),
        ]);
        break;

      case UserRole.security:
        roleSpecificItems.addAll([
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Check-in Logs'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Add Check-in Logs screen navigation
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Pending SOS Alerts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PendingSOSScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber),
            title: const Text('Security Alerts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SecurityAlertsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.monitor_heart),
            title: Text('Student Activities'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => StudentActivitiesScreen(),
              ));
            },
          ),
        ]);
        break;

      case UserRole.student:
        roleSpecificItems.addAll([
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Emergency SOS'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentSosScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('File Report'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentReportsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('My Complaints'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentComplaintsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Incident History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentHistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('My Courses'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentCoursesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('My Schedule'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentScheduleScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentProfileScreen()),
              );
            },
          ),
          // Add to your side menu items

        ]);
        break;
    }

    return [...commonItems, ...roleSpecificItems];
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superadmin:
        return Colors.purple.shade800;
      case UserRole.admin:
        return Colors.blue.shade800;
      case UserRole.security:
        return Colors.orange.shade800;
      case UserRole.student:
        return Colors.green.shade800;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.superadmin:
        return "Super Administrator";
      case UserRole.admin:
        return "Administrator";
      case UserRole.security:
        return "Security Personnel";
      case UserRole.student:
        return "Student";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: _getRoleColor(role),
            ),
            accountName: Text(
              username.isNotEmpty ? username : 'User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              _getRoleDisplayName(role),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : "U",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getRoleColor(role),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _getMenuItems(context),
            ),
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _signOut(context),
            ),
          ),
        ],
      ),
    );
  }
}