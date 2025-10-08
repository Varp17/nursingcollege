import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DepartmentManagementScreen extends StatefulWidget {
  final String username;

  const DepartmentManagementScreen({super.key, required this.username});

  @override
  State<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _departments = [
    'Nursing',
    'Medical-Surgical',
    'Pediatrics',
    'Obstetrics',
    'Psychiatric',
    'Community Health',
    'Administration',
    'Security',
    'General'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Management'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Department Overview Chart
            _buildDepartmentOverview(),
            const SizedBox(height: 20),

            // Department Details
            _buildDepartmentDetails(),
            const SizedBox(height: 20),

            // Department Performance
            _buildDepartmentPerformance(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentOverview() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Department Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs;
                  final departmentData = _calculateDepartmentDistribution(users);

                  return PieChart(
                    PieChartData(
                      sections: departmentData.entries.map((entry) {
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          color: _getDepartmentColor(entry.key),
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

  Widget _buildDepartmentDetails() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Department Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('complaints').snapshots(),
                  builder: (context, complaintsSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('sos_alerts').snapshots(),
                      builder: (context, alertsSnapshot) {
                        if (!usersSnapshot.hasData || !complaintsSnapshot.hasData || !alertsSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final departmentStats = _calculateDetailedDepartmentStats(
                          usersSnapshot.data!.docs,
                          complaintsSnapshot.data!.docs,
                          alertsSnapshot.data!.docs,
                        );

                        return Column(
                          children: departmentStats.entries.map((entry) {
                            final stats = entry.value;
                            return _buildDepartmentStatsCard(entry.key, stats);
                          }).toList(),
                        );
                      },
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

  Widget _buildDepartmentStatsCard(String department, Map<String, int> stats) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getDepartmentColor(department),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      department[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    department,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Users', stats['users']!.toString(), Icons.people),
                _buildStatItem('Complaints', stats['complaints']!.toString(), Icons.report_problem),
                _buildStatItem('Alerts', stats['alerts']!.toString(), Icons.warning),
                _buildStatItem('Faculty', stats['faculty']!.toString(), Icons.person),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDepartmentPerformance() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Department Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('complaints').snapshots(),
              builder: (context, complaintsSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('sos_alerts').snapshots(),
                  builder: (context, alertsSnapshot) {
                    if (!complaintsSnapshot.hasData || !alertsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final performanceData = _calculateDepartmentPerformance(
                      complaintsSnapshot.data!.docs,
                      alertsSnapshot.data!.docs,
                    );

                    return Column(
                      children: performanceData.entries.map((entry) {
                        final performance = entry.value;
                        return _buildPerformanceRow(entry.key, performance);
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

  Widget _buildPerformanceRow(String department, Map<String, double> performance) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              department,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Complaint Resolution: '),
                    Text(
                      '${performance['complaintResolution']!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getPerformanceColor(performance['complaintResolution']!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: performance['complaintResolution']! / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getPerformanceColor(performance['complaintResolution']!),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Alert Response: '),
                    Text(
                      '${performance['alertResponse']!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getPerformanceColor(performance['alertResponse']!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: performance['alertResponse']! / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getPerformanceColor(performance['alertResponse']!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateDepartmentDistribution(List<QueryDocumentSnapshot> users) {
    final distribution = <String, int>{};

    for (final dept in _departments) {
      distribution[dept] = 0;
    }

    for (final user in users) {
      final department = user['department'];
      if (department != null && distribution.containsKey(department)) {
        distribution[department] = distribution[department]! + 1;
      }
    }

    return distribution;
  }

  Map<String, Map<String, int>> _calculateDetailedDepartmentStats(
      List<QueryDocumentSnapshot> users,
      List<QueryDocumentSnapshot> complaints,
      List<QueryDocumentSnapshot> alerts,
      ) {
    final stats = <String, Map<String, int>>{};

    for (final dept in _departments) {
      stats[dept] = {
        'users': 0,
        'complaints': 0,
        'alerts': 0,
        'faculty': 0,
      };
    }

    // Count users and faculty per department
    for (final user in users) {
      final department = user['department'];
      if (department != null && stats.containsKey(department)) {
        stats[department]!['users'] = stats[department]!['users']! + 1;
        if (user['role'] == 'faculty' || user['role'] == 'hod') {
          stats[department]!['faculty'] = stats[department]!['faculty']! + 1;
        }
      }
    }

    // Count complaints per department
    for (final complaint in complaints) {
      final department = complaint['department'];
      if (department != null && stats.containsKey(department)) {
        stats[department]!['complaints'] = stats[department]!['complaints']! + 1;
      }
    }

    // Count alerts per department
    for (final alert in alerts) {
      final department = alert['department'];
      if (department != null && stats.containsKey(department)) {
        stats[department]!['alerts'] = stats[department]!['alerts']! + 1;
      }
    }

    return stats;
  }

  Map<String, Map<String, double>> _calculateDepartmentPerformance(
      List<QueryDocumentSnapshot> complaints,
      List<QueryDocumentSnapshot> alerts,
      ) {
    final performance = <String, Map<String, double>>{};

    for (final dept in _departments) {
      performance[dept] = {
        'complaintResolution': 0.0,
        'alertResponse': 0.0,
      };
    }

    // Calculate complaint resolution rates
    for (final dept in _departments) {
      final deptComplaints = complaints.where((c) => c['department'] == dept).toList();
      final resolvedComplaints = deptComplaints.where((c) => c['status'] == 'resolved').length;

      performance[dept]!['complaintResolution'] = deptComplaints.isNotEmpty
          ? (resolvedComplaints / deptComplaints.length) * 100
          : 0.0;
    }

    // Calculate alert response rates (simplified)
    for (final dept in _departments) {
      final deptAlerts = alerts.where((a) => a['department'] == dept).toList();
      final respondedAlerts = deptAlerts.where((a) => a['status'] == 'resolved').length;

      performance[dept]!['alertResponse'] = deptAlerts.isNotEmpty
          ? (respondedAlerts / deptAlerts.length) * 100
          : 0.0;
    }

    return performance;
  }

  Color _getDepartmentColor(String department) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.brown,
    ];
    final index = _departments.indexOf(department) % colors.length;
    return colors[index];
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}