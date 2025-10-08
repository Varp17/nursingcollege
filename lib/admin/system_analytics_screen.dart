import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SystemAnalyticsScreen extends StatefulWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  State<SystemAnalyticsScreen> createState() => _SystemAnalyticsScreenState();
}

class _SystemAnalyticsScreenState extends State<SystemAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _timeRange = '7days';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Analytics'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        actions: [
          DropdownButton<String>(
            value: _timeRange,
            items: const [
              DropdownMenuItem(value: '7days', child: Text('Last 7 Days')),
              DropdownMenuItem(value: '30days', child: Text('Last 30 Days')),
              DropdownMenuItem(value: '90days', child: Text('Last 90 Days')),
            ],
            onChanged: (value) {
              setState(() {
                _timeRange = value!;
              });
            },
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.white),
            underline: Container(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Overview Cards
            _buildOverviewCards(),
            const SizedBox(height: 20),

            // Emergency Alerts Chart
            _buildEmergencyAlertsChart(),
            const SizedBox(height: 20),

            // Complaints Analytics
            _buildComplaintsAnalytics(),
            const SizedBox(height: 20),

            // User Activity
            _buildUserActivity(),
            const SizedBox(height: 20),

            // Department-wise Statistics
            _buildDepartmentStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('sos_alerts').snapshots(),
      builder: (context, sosSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('complaints').snapshots(),
          builder: (context, complaintsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                final totalAlerts = sosSnapshot.data?.docs.length ?? 0;
                final totalComplaints = complaintsSnapshot.data?.docs.length ?? 0;
                final totalUsers = usersSnapshot.data?.docs.length ?? 0;

                // Calculate resolved percentages
                final resolvedAlerts = sosSnapshot.data?.docs
                    .where((doc) => doc['status'] == 'resolved')
                    .length ?? 0;
                final resolvedComplaints = complaintsSnapshot.data?.docs
                    .where((doc) => doc['status'] == 'resolved')
                    .length ?? 0;

                final alertResolutionRate = totalAlerts > 0
                    ? ((resolvedAlerts / totalAlerts) * 100).round()
                    : 0;
                final complaintResolutionRate = totalComplaints > 0
                    ? ((resolvedComplaints / totalComplaints) * 100).round()
                    : 0;

                return Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Emergency Alerts',
                        totalAlerts.toString(),
                        '$alertResolutionRate% Resolved',
                        Icons.warning,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Complaints',
                        totalComplaints.toString(),
                        '$complaintResolutionRate% Resolved',
                        Icons.report_problem,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Total Users',
                        totalUsers.toString(),
                        'System Users',
                        Icons.people,
                        Colors.blue,
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

  Widget _buildAnalyticsCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyAlertsChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Alerts Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('sos_alerts').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final alerts = snapshot.data!.docs;
                  final dailyData = _calculateDailyAlertData(alerts);

                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: dailyData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
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

  List<int> _calculateDailyAlertData(List<QueryDocumentSnapshot> alerts) {
    final now = DateTime.now();
    final dailyCounts = List<int>.filled(7, 0);

    for (final alert in alerts) {
      final timestamp = alert['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final alertDate = timestamp.toDate();
        final difference = now.difference(alertDate).inDays;
        if (difference < 7) {
          dailyCounts[6 - difference]++;
        }
      }
    }

    return dailyCounts;
  }

  Widget _buildComplaintsAnalytics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complaints by Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('complaints').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final complaints = snapshot.data!.docs;
                  final categoryData = _calculateComplaintCategories(complaints);

                  return PieChart(
                    PieChartData(
                      sections: categoryData.entries.map((entry) {
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          color: _getCategoryColor(entry.key),
                          title: '${entry.key}\n${entry.value}',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
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

  Map<String, int> _calculateComplaintCategories(List<QueryDocumentSnapshot> complaints) {
    final categories = <String, int>{};

    for (final complaint in complaints) {
      final type = complaint['type'] ?? 'Other';
      categories[type] = (categories[type] ?? 0) + 1;
    }

    return categories;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
        return Colors.red;
      case 'facility':
        return Colors.blue;
      case 'academic':
        return Colors.green;
      case 'security':
        return Colors.orange;
      case 'administrative':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildUserActivity() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Activity Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;
                final roleDistribution = _calculateRoleDistribution(users);

                return Column(
                  children: roleDistribution.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatRole(entry.key),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: LinearProgressIndicator(
                              value: entry.value / users.length,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getRoleColor(entry.key),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${entry.value}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _calculateRoleDistribution(List<QueryDocumentSnapshot> users) {
    final roles = <String, int>{};

    for (final user in users) {
      final role = user['role'] ?? 'unknown';
      roles[role] = (roles[role] ?? 0) + 1;
    }

    return roles;
  }

  String _formatRole(String role) {
    switch (role) {
      case 'student':
        return 'Student Nurses';
      case 'faculty':
        return 'Faculty';
      case 'security':
        return 'Security';
      case 'admin':
        return 'Admins';
      case 'hod':
        return 'HODs';
      default:
        return role;
    }
  }

  Widget _buildDepartmentStats() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Department-wise Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('complaints').snapshots(),
                  builder: (context, complaintsSnapshot) {
                    if (!usersSnapshot.hasData || !complaintsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = usersSnapshot.data!.docs;
                    final complaints = complaintsSnapshot.data!.docs;
                    final departmentStats = _calculateDepartmentStats(users, complaints);

                    return Column(
                      children: departmentStats.entries.map((entry) {
                        final stats = entry.value;
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getDepartmentColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                entry.key[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(entry.key),
                          subtitle: Text('${stats['users']} users • ${stats['complaints']} complaints'),
                          trailing: Chip(
                            label: Text(
                              '${stats['alerts']} alerts',
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Map<String, int>> _calculateDepartmentStats(
      List<QueryDocumentSnapshot> users, List<QueryDocumentSnapshot> complaints) {
    final stats = <String, Map<String, int>>{};

    // Initialize departments
    const departments = [
      'Nursing', 'Medical-Surgical', 'Pediatrics', 'Obstetrics',
      'Psychiatric', 'Community Health', 'Administration', 'Security'
    ];

    for (final dept in departments) {
      stats[dept] = {'users': 0, 'complaints': 0, 'alerts': 0};
    }

    // Count users per department
    for (final user in users) {
      final department = user['department'];
      if (department != null && stats.containsKey(department)) {
        stats[department]!['users'] = stats[department]!['users']! + 1;
      }
    }

    // Count complaints per department
    for (final complaint in complaints) {
      final department = complaint['department'];
      if (department != null && stats.containsKey(department)) {
        stats[department]!['complaints'] = stats[department]!['complaints']! + 1;
      }
    }

    return stats;
  }

  Color _getDepartmentColor(String department) {
    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.red, Colors.teal, Colors.indigo, Colors.amber
    ];
    final index = department.hashCode % colors.length;
    return colors[index];
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'faculty':
        return Colors.blue;
      case 'security':
        return Colors.orange;
      case 'hod':
        return Colors.purple;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}