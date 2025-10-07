// student/student_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import student screens
import 'student_sos_screen.dart';
import 'student_reports_screen.dart';
import 'student_complaints_screen.dart';
import 'student_history_screen.dart';
import 'student_profile_screen.dart';
import '../common/side_menu.dart';
import '../models/user_role.dart';

class StudentDashboard extends StatefulWidget {
  final String username;
  final UserRole role;

  const StudentDashboard({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  late Stream<QuerySnapshot> _incidentsStream;

  @override
  void initState() {
    super.initState();
    _incidentsStream = FirebaseFirestore.instance
        .collection('incidents')
        .where('studentUid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Main Dashboard Screen
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeHeader(),
          SizedBox(height: 20),

          // Emergency SOS Button
          _buildEmergencySOS(),
          SizedBox(height: 20),

          // Quick Stats
          _buildQuickStats(),
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
          colors: [Colors.blue.shade700, Colors.blue.shade900],
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
            'Your Safety is Our Priority',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _incidentsStream,
            builder: (context, snapshot) {
              final incidents = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Text(
                '$incidents Reported Incident${incidents != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySOS() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentSosScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.warning, size: 50, color: Colors.white),
              SizedBox(height: 12),
              Text(
                'EMERGENCY SOS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap to send immediate emergency alert to security',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _incidentsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final incidents = snapshot.data!.docs;
        final today = DateTime.now();
        final todayIncidents = incidents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'] as Timestamp;
          final incidentDate = timestamp.toDate();
          return incidentDate.year == today.year &&
              incidentDate.month == today.month &&
              incidentDate.day == today.day;
        }).length;

        final pendingIncidents = incidents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'pending';
        }).length;

        final resolvedIncidents = incidents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'resolved';
        }).length;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Today',
                value: todayIncidents.toString(),
                subtitle: 'Reports',
                color: Colors.blue,
                icon: Icons.today,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Pending',
                value: pendingIncidents.toString(),
                subtitle: 'Actions',
                color: Colors.orange,
                icon: Icons.pending_actions,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Resolved',
                value: resolvedIncidents.toString(),
                subtitle: 'Cases',
                color: Colors.green,
                icon: Icons.check_circle,
              ),
            ),
          ],
        );
      },
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
                  '📋 Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.history),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StudentHistoryScreen()),
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

                final incidents = snapshot.data!.docs;

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
                        Text(
                          'Your reports will appear here',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: incidents.take(3).map((doc) {
                    final incident = doc.data() as Map<String, dynamic>;
                    return _ActivityItem(incident: incident);
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
                  title: 'Emergency SOS',
                  icon: Icons.warning,
                  color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentSosScreen())),
                ),
                _ActionCard(
                  title: 'File Report',
                  icon: Icons.report,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentReportsScreen())),
                ),
                _ActionCard(
                  title: 'Complaints',
                  icon: Icons.feedback,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentComplaintsScreen())),
                ),
                _ActionCard(
                  title: 'History',
                  icon: Icons.history,
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentHistoryScreen())),
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
      appBar: AppBar(
        title: Text('Student Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentProfileScreen()),
              );
            },
          ),
        ],
      ),
      drawer: SideMenu(role: widget.role, username: widget.username),
      body: _currentIndex == 0 ? _buildDashboard() : _buildOtherScreens(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildOtherScreens() {
    switch (_currentIndex) {
      case 1:
        return StudentHistoryScreen();
      default:
        return _buildDashboard();
    }
  }
}

// Supporting Widgets
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
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
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
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

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> incident;

  const _ActivityItem({required this.incident});

  @override
  Widget build(BuildContext context) {
    final timestamp = (incident['timestamp'] as Timestamp).toDate();
    final status = incident['status'] ?? 'pending';

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getStatusIcon(status),
          color: _getStatusColor(status),
        ),
        title: Text(
          incident['type'] ?? 'SOS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          incident['location'] ?? 'Unknown Location',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Text(
          DateFormat('HH:mm').format(timestamp),
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'resolved':
        return Icons.check_circle;
      case 'acknowledged':
        return Icons.access_time;
      default:
        return Icons.warning;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'acknowledged':
        return Colors.orange;
      default:
        return Colors.red;
    }
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