import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../common/side_menu.dart';
import '../models/user_role.dart';
import '../security/pending_sos_screen.dart';
import '../admin/manage_users_screen.dart';
import '../superadmin/system_analytics_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String username;
  final UserRole role;

  const AdminDashboard({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _adminDepartment = '';
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _getAdminDepartment();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getAdminDepartment() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _adminDepartment = userDoc.data()?['department'] ?? 'General';
      });
    }
  }

  // Statistics Cards
  Widget _buildStatsCard(String title, int count, Color color, IconData icon, String subtitle) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Quick Action Button
  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Analytics Chart
  Widget _buildComplaintsChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complaints Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('complaints')
                    .where('department', isEqualTo: _adminDepartment)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final complaints = snapshot.data!.docs;
                  final pending = complaints.where((doc) => doc['status'] == 'pending').length;
                  final inProgress = complaints.where((doc) => doc['status'] == 'inProgress').length;
                  final resolved = complaints.where((doc) => doc['status'] == 'resolved').length;

                  return PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: pending.toDouble(),
                          color: Colors.orange,
                          title: '$pending\nPending',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: inProgress.toDouble(),
                          color: Colors.blue,
                          title: '$inProgress\nIn Progress',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: resolved.toDouble(),
                          color: Colors.green,
                          title: '$resolved\nResolved',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Emergency Alert Widget
  Widget _buildEmergencyAlert() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('sos_alerts')
          .where('department', isEqualTo: _adminDepartment)
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final alerts = snapshot.data!.docs;
        if (alerts.isEmpty) return const SizedBox();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${alerts.length} PENDING EMERGENCY ALERT${alerts.length > 1 ? 'S' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Immediate attention required',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PendingSOSScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Admin Dashboard'),
              if (_adminDepartment.isNotEmpty)
                Text(
                  _adminDepartment,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
            ],
          ),
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_active),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PendingSOSScreen()),
                );
              },
              tooltip: 'Emergency Alerts',
            ),
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SystemAnalyticsScreen()),
                );
              },
              tooltip: 'Analytics',
            ),
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageUsersScreen(
                      username: widget.username,
                      role: widget.role,
                    ),
                  ),
                );
              },
              tooltip: 'Manage Users',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.warning), text: 'Emergencies'),
              Tab(icon: Icon(Icons.list_alt), text: 'Complaints'),
              Tab(icon: Icon(Icons.people), text: 'Students'),
            ],
          ),
        ),
        drawer: SideMenu(role: widget.role, username: widget.username),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Overview
            _buildOverviewTab(),

            // Tab 2: Emergencies
            _buildEmergenciesTab(),

            // Tab 3: Complaints
            _buildComplaintsTab(),

            // Tab 4: Students
            _buildStudentsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Quick action for new complaint/alert
            _showQuickActions(context);
          },
          backgroundColor: Colors.blue.shade800,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Emergency Alert Banner
          _buildEmergencyAlert(),

          // Quick Stats
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('sos_alerts')
                .where('department', isEqualTo: _adminDepartment)
                .snapshots(),
            builder: (context, sosSnapshot) {
              final totalAlerts = sosSnapshot.data?.docs.length ?? 0;
              final pendingAlerts = sosSnapshot.data?.docs
                  .where((doc) => doc['status'] == 'pending')
                  .length ??
                  0;

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('complaints')
                    .where('department', isEqualTo: _adminDepartment)
                    .snapshots(),
                builder: (context, complaintSnapshot) {
                  final totalComplaints = complaintSnapshot.data?.docs.length ?? 0;
                  final pendingComplaints = complaintSnapshot.data?.docs
                      .where((doc) => doc['status'] == 'pending')
                      .length ??
                      0;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatsCard(
                              'Emergency Alerts',
                              pendingAlerts,
                              Colors.red,
                              Icons.warning_amber,
                              '$totalAlerts total',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatsCard(
                              'Pending Complaints',
                              pendingComplaints,
                              Colors.orange,
                              Icons.pending_actions,
                              '$totalComplaints total',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatsCard(
                              'Students',
                              _getStudentCount(),
                              Colors.blue,
                              Icons.people,
                              'In department',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatsCard(
                              'Response Rate',
                              _getResponseRate(),
                              Colors.green,
                              Icons.trending_up,
                              'This month',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildQuickAction(
                'New Alert',
                Icons.add_alert,
                Colors.red,
                    () => _createNewEmergency(context),
              ),
              _buildQuickAction(
                'Manage Users',
                Icons.people,
                Colors.blue,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageUsersScreen(
                        username: widget.username,
                        role: widget.role,
                      ),
                    ),
                  );
                },
              ),
              _buildQuickAction(
                'Reports',
                Icons.analytics,
                Colors.green,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SystemAnalyticsScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Analytics Chart
          _buildComplaintsChart(),

          const SizedBox(height: 20),

          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildEmergenciesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('sos_alerts')
          .where('department', isEqualTo: _adminDepartment)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final alerts = snapshot.data!.docs;

        if (alerts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Emergency Alerts',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            final data = alert.data() as Map<String, dynamic>;
            return _buildEmergencyCard(data, alert.id);
          },
        );
      },
    );
  }

  Widget _buildComplaintsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('complaints')
          .where('department', isEqualTo: _adminDepartment)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final complaints = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index];
            final data = complaint.data() as Map<String, dynamic>;
            return _buildComplaintCard(data, complaint.id);
          },
        );
      },
    );
  }

  Widget _buildStudentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('department', isEqualTo: _adminDepartment)
          .where('role', isEqualTo: 'student')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final data = student.data() as Map<String, dynamic>;
            return _buildStudentCard(data);
          },
        );
      },
    );
  }

  // Card Builders
  Widget _buildEmergencyCard(Map<String, dynamic> data, String alertId) {
    final status = data['status'] ?? 'pending';
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: status == 'pending' ? Colors.red.shade100 : Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            status == 'pending' ? Icons.warning : Icons.check_circle,
            color: status == 'pending' ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          data['alertType'] ?? 'Emergency Alert',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: status == 'pending' ? Colors.red : Colors.green,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${data['location'] ?? 'Unknown'}'),
            Text('Reported by: ${data['reportedBy'] ?? 'Unknown'}'),
            Text('Time: ${_formatTime(timestamp)}'),
          ],
        ),
        trailing: Chip(
          label: Text(
            status.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: status == 'pending' ? Colors.red : Colors.green,
        ),
        onTap: () => _showEmergencyDetails(context, data, alertId),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> data, String complaintId) {
    final status = data['status'] ?? 'pending';
    final priority = data['priority'] ?? 'medium';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _getComplaintIcon(data['type']),
        title: Text(data['title'] ?? 'No Title'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['description'] ?? 'No description'),
            Text('Category: ${data['type'] ?? 'General'}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(
              label: Text(
                priority.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: _getPriorityColor(priority),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                status.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: _getStatusColor(status),
            ),
          ],
        ),
        onTap: () => _showComplaintDetails(context, data, complaintId),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(data['name']?[0].toUpperCase() ?? 'S'),
        ),
        title: Text(data['name'] ?? 'No Name'),
        subtitle: Text(data['email'] ?? 'No Email'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showStudentDetails(context, data),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Add recent activity items here
            _buildActivityItem('New emergency alert reported', '2 min ago', Icons.warning, Colors.red),
            _buildActivityItem('Complaint resolved', '1 hour ago', Icons.check_circle, Colors.green),
            _buildActivityItem('New student registered', '2 hours ago', Icons.person_add, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(title),
      subtitle: Text(time),
      dense: true,
    );
  }

  // Helper Methods
  int _getStudentCount() {
    // This would typically come from Firestore
    return 45; // Example count
  }

  int _getResponseRate() {
    // This would typically be calculated from Firestore data
    return 87; // Example percentage
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Icon _getComplaintIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'medical':
        return const Icon(Icons.medical_services, color: Colors.red);
      case 'facility':
        return const Icon(Icons.build, color: Colors.blue);
      case 'academic':
        return const Icon(Icons.school, color: Colors.green);
      case 'security':
        return const Icon(Icons.security, color: Colors.orange);
      default:
        return const Icon(Icons.report_problem, color: Colors.grey);
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'inprogress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Dialog Methods
  void _showEmergencyDetails(BuildContext context, Map<String, dynamic> data, String alertId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type:', data['alertType'] ?? 'Emergency'),
              _buildDetailRow('Location:', data['location'] ?? 'Unknown'),
              _buildDetailRow('Department:', data['department'] ?? 'N/A'),
              _buildDetailRow('Reported by:', data['reportedBy'] ?? 'Unknown'),
              _buildDetailRow('Time:', data['timestamp'] != null
                  ? (data['timestamp'] as Timestamp).toDate().toString()
                  : 'Unknown'),
              if (data['description'] != null)
                _buildDetailRow('Description:', data['description']),
            ],
          ),
        ),
        actions: [
          if (data['status'] == 'pending')
            ElevatedButton(
              onPressed: () {
                _firestore.collection('sos_alerts').doc(alertId).update({
                  'status': 'resolved',
                  'resolvedBy': widget.username,
                  'resolvedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alert marked as resolved')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Mark Resolved', style: TextStyle(color: Colors.white)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showComplaintDetails(BuildContext context, Map<String, dynamic> data, String complaintId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complaint Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Title:', data['title'] ?? 'No Title'),
              _buildDetailRow('Type:', data['type'] ?? 'General'),
              _buildDetailRow('Priority:', data['priority'] ?? 'Medium'),
              _buildDetailRow('Status:', data['status'] ?? 'Pending'),
              _buildDetailRow('Description:', data['description'] ?? 'No description'),
              _buildDetailRow('Reported by:', data['reportedBy'] ?? 'Unknown'),
              _buildDetailRow('Department:', data['department'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          DropdownButton<String>(
            value: data['status'] ?? 'pending',
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'inProgress', child: Text('In Progress')),
              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
            ],
            onChanged: (newStatus) {
              _firestore.collection('complaints').doc(complaintId).update({
                'status': newStatus,
                'updatedBy': widget.username,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Status updated to $newStatus')),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Student Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name:', data['name'] ?? 'N/A'),
            _buildDetailRow('Email:', data['email'] ?? 'N/A'),
            _buildDetailRow('Department:', data['department'] ?? 'Not Assigned'),
            _buildDetailRow('Student ID:', data['studentId'] ?? 'N/A'),
            _buildDetailRow('Year:', data['year'] ?? 'N/A'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_alert, color: Colors.red),
              title: const Text('Create Emergency Alert'),
              onTap: () {
                Navigator.pop(context);
                _createNewEmergency(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.orange),
              title: const Text('Log New Complaint'),
              onTap: () {
                Navigator.pop(context);
                _createNewComplaint(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.blue),
              title: const Text('Add New User'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to add user screen
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewEmergency(BuildContext context) {
    // Implement emergency creation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Emergency Alert'),
        content: const Text('Emergency alert creation functionality would go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Create emergency logic
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createNewComplaint(BuildContext context) {
    // Implement complaint creation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log New Complaint'),
        content: const Text('Complaint creation functionality would go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Create complaint logic
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}