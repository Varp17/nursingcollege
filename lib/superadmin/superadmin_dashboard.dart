// superadmin/superadmin_dashboard.dart
import 'package:collegesafety/superadmin/student_activities_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../common/side_menu.dart';
import 'incident_detail_screen.dart';
import 'manage_users_screen.dart';
import 'role_assignment_screen.dart';
import 'system_analytics_screen.dart';
import 'college_management_screen.dart';
import 'audit_log_screen.dart';
import 'backup_management_screen.dart';
import '../models/user_role.dart';
import '../theme/theme.dart'; // Add this line

class SuperAdminDashboard extends StatefulWidget {
  final String username;
  final UserRole role;

  const SuperAdminDashboard({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  late Stream<QuerySnapshot> _usersStream;
  late Stream<QuerySnapshot> _incidentsStream;
  late Stream<QuerySnapshot> _reportsStream;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    _incidentsStream = FirebaseFirestore.instance.collection('incidents').snapshots();
    _reportsStream = FirebaseFirestore.instance.collection('reports').snapshots();
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeHeader(),
          SizedBox(height: 20),

          // System Overview Cards
          _buildSystemOverview(),
          SizedBox(height: 20),

          // User Statistics
          _buildUserStatistics(),
          SizedBox(height: 20),

          // Recent Activity
          _buildRecentActivity(),
          SizedBox(height: 20),

          // Quick Actions Grid
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.purple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${widget.username}!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'System Administration Panel',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _usersStream,
            builder: (context, snapshot) {
              final totalUsers = snapshot.hasData ? snapshot.data!.docs.length : 0;
              final pendingApprovals = snapshot.hasData ? snapshot.data!.docs.where((user) {
                final data = user.data() as Map<String, dynamic>;
                return (data['approved'] ?? false) == false;
              }).length : 0;

              return Row(
                children: [
                  Text(
                    '$totalUsers Total Users',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 20),
                  if (pendingApprovals > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$pendingApprovals Pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersStream,
      builder: (context, usersSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _incidentsStream,
          builder: (context, incidentsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: _reportsStream,
              builder: (context, reportsSnapshot) {
                final totalUsers = usersSnapshot.hasData ? usersSnapshot.data!.docs.length : 0;
                final totalIncidents = incidentsSnapshot.hasData ? incidentsSnapshot.data!.docs.length : 0;
                final totalReports = reportsSnapshot.hasData ? reportsSnapshot.data!.docs.length : 0;

                return Row(
                  children: [
                    Expanded(
                      child: _SystemStatCard(
                        title: 'Total Users',
                        value: totalUsers.toString(),
                        subtitle: 'Registered',
                        color: Colors.blue,
                        icon: Icons.people,
                        progress: 1.0,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _SystemStatCard(
                        title: 'Incidents',
                        value: totalIncidents.toString(),
                        subtitle: 'This Month',
                        color: Colors.red,
                        icon: Icons.warning,
                        progress: 0.7,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _SystemStatCard(
                        title: 'Reports',
                        value: totalReports.toString(),
                        subtitle: 'Active',
                        color: Colors.green,
                        icon: Icons.assignment,
                        progress: 0.5,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserStatistics() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👥 User Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _usersStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;
                final roleCounts = {
                  'student': users.where((user) {
                    final data = user.data() as Map<String, dynamic>;
                    return data['role'] == 'student' && (data['approved'] ?? false);
                  }).length,
                  'security': users.where((user) {
                    final data = user.data() as Map<String, dynamic>;
                    return data['role'] == 'security' && (data['approved'] ?? false);
                  }).length,
                  'admin': users.where((user) {
                    final data = user.data() as Map<String, dynamic>;
                    return data['role'] == 'admin' && (data['approved'] ?? false);
                  }).length,
                };

                final totalApproved = roleCounts.values.reduce((a, b) => a + b);

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _UserRoleCard(
                            role: 'Students',
                            count: roleCounts['student']!,
                            total: totalApproved,
                            color: Colors.blue,
                            icon: Icons.school,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _UserRoleCard(
                            role: 'Security',
                            count: roleCounts['security']!,
                            total: totalApproved,
                            color: Colors.orange,
                            icon: Icons.security,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _UserRoleCard(
                            role: 'Admins',
                            count: roleCounts['admin']!,
                            total: totalApproved,
                            color: Colors.green,
                            icon: Icons.admin_panel_settings,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ManageUsersScreen(
                            username: widget.username,
                            role: widget.role,
                          )),
                        );
                      },
                      icon: Icon(Icons.manage_accounts),
                      label: Text('Manage All Users'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade800,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📈 Recent System Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.analytics),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SystemAnalyticsScreen()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _incidentsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final incidents = snapshot.data!.docs.take(5).toList();

                if (incidents.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: incidents.map((doc) {
                    final incident = doc.data() as Map<String, dynamic>;
                    return _ActivityItem(incident: incident, incidentId: '',);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚡ Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _ActionCard(
                  title: 'User Management',
                  icon: Icons.manage_accounts,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ManageUsersScreen(username: widget.username, role: widget.role),
                  )),
                ),
                _ActionCard(
                  title: 'Role Assignment',
                  icon: Icons.admin_panel_settings,
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RoleAssignmentScreen(),
                  )),
                ),
                _ActionCard(
                  title: 'System Analytics',
                  icon: Icons.analytics,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SystemAnalyticsScreen(),
                  )),
                ),
                _ActionCard(
                  title: 'College Management',
                  icon: Icons.business,
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CollegeManagementScreen(),
                  )),
                ),
                _ActionCard(
                  title: 'Audit Logs',
                  icon: Icons.history,
                  color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AuditLogScreen(),
                  )),
                ),
                _ActionCard(
                  title: 'Backup & Restore',
                  icon: Icons.backup,
                  color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BackupManagementScreen(),
                  )),
                ),
                // Add this to your _buildQuickActions() method in the GridView
                _ActionCard(
                  title: 'Student Activities',
                  icon: Icons.monitor_heart,
                  color: Colors.pink,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StudentActivitiesScreen(),
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'Super Admin Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 2,
        foregroundColor: AppColors.textGrey,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // Notification center
            },
          ),

        ],
      ),
      drawer: SideMenu(role: widget.role, username: widget.username), // This should work now
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.offWhite,
              AppColors.white,
            ],
          ),
        ),
        child: _buildDashboard(), // This should work now
      ),
    );
  }
}

// Supporting Widgets
class _SystemStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final double progress;

  const _SystemStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                CircularPercentIndicator(
                  radius: 20,
                  lineWidth: 3,
                  percent: progress,
                  progressColor: color,
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserRoleCard extends StatelessWidget {
  final String role;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _UserRoleCard({
    required this.role,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              role,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }
}

// In your _ActivityItem widget, make it clickable
class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> incident;
  final String incidentId;

  const _ActivityItem({required this.incident, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    final timestamp = (incident['timestamp'] as Timestamp).toDate();

    return ListTile(
      leading: Icon(Icons.warning, color: Colors.orange),
      title: Text(
        incident['studentName'] ?? 'Unknown',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(incident['type'] ?? 'SOS'),
      trailing: Text(
        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
        style: TextStyle(color: Colors.grey),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IncidentDetailScreen(
              incidentId: incidentId,
              incident: incident,
            ),
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}