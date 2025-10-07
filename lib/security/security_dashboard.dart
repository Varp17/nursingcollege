// security/security_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';

// Import your screens
import 'security_alerts_screen.dart';
import 'security_history_screen.dart';
import 'area_analytics_screen.dart';
import 'response_team_screen.dart';

class SecurityDashboard extends StatefulWidget {
  final String username;
  final dynamic role;

  const SecurityDashboard({
    Key? key,
    required this.username,
    required this.role,
  }) : super(key: key);

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  int _currentIndex = 0;
  late Stream<QuerySnapshot> _alertsStream;
  late Stream<QuerySnapshot> _incidentsStream;

  @override
  void initState() {
    super.initState();
    _alertsStream = FirebaseFirestore.instance
        .collection('security_alerts')
        .where('status', isEqualTo: 'new')
        .snapshots();

    _incidentsStream = FirebaseFirestore.instance
        .collection('incidents')
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
          // Header with Welcome
          _buildHeader(),
          SizedBox(height: 20),

          // Quick Stats Row
          _buildQuickStats(),
          SizedBox(height: 20),

          // Active Alerts Section
          _buildActiveAlertsSection(),
          SizedBox(height: 20),

          // Analytics Overview
          _buildAnalyticsOverview(),
          SizedBox(height: 20),

          // Quick Actions Grid
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
            'Security Command Center',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _alertsStream,
            builder: (context, snapshot) {
              final activeAlerts = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Text(
                '$activeAlerts Active Alert${activeAlerts != 1 ? 's' : ''}',
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

        final resolvedCount = incidents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'resolved';
        }).length;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Today',
                value: todayIncidents.toString(),
                subtitle: 'Incidents',
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
                value: resolvedCount.toString(),
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

  Widget _buildActiveAlertsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _alertsStream,
      builder: (context, snapshot) {
        final alerts = snapshot.hasData ? snapshot.data!.docs : [];
        final alertCount = alerts.length;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Active Alerts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: alertCount > 0 ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$alertCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                if (!snapshot.hasData)
                  Center(child: CircularProgressIndicator())
                else if (alertCount == 0)
                  _buildNoAlertsState()
                else
                  Column(
                    children: [
                      // Alert list (max 3 items)
                      ...alerts.take(3).map((doc) {
                        final alert = doc.data() as Map<String, dynamic>;
                        return _ActiveAlertItem(
                          alert: alert,
                          alertId: doc.id,
                          onTap: () {
                            _handleAlertTap(alert, doc.id);
                          },
                        );
                      }).toList(),

                      // View All button if more than 3 alerts
                      if (alertCount > 3)
                        Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SecurityAlertsScreen(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.list_alt, size: 18),
                              label: Text('View All $alertCount Alerts'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                foregroundColor: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoAlertsState() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 48, color: Colors.green),
          SizedBox(height: 12),
          Text(
            'All Clear!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'No active security alerts',
            style: TextStyle(color: Colors.green.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: _incidentsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final incidents = snapshot.data!.docs;
        final totalIncidents = incidents.length;
        final resolvedCount = incidents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'resolved';
        }).length;

        final responseRate = totalIncidents > 0 ? (resolvedCount / totalIncidents) : 0.0;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 Analytics Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          CircularPercentIndicator(
                            radius: 40,
                            lineWidth: 8,
                            percent: responseRate,
                            center: Text(
                              '${(responseRate * 100).toInt()}%',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            progressColor: Colors.green,
                            backgroundColor: Colors.green.shade100,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Response\nRate',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          CircularPercentIndicator(
                            radius: 40,
                            lineWidth: 8,
                            percent: 0.75,
                            center: Text(
                              '8min',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            progressColor: Colors.blue,
                            backgroundColor: Colors.blue.shade100,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Avg Response\nTime',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.orange, width: 4),
                            ),
                            child: Center(
                              child: Text(
                                resolvedCount.toString(),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Resolved\nTotal',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AreaAnalyticsScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.analytics),
                  label: Text('View Detailed Analytics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade800,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  title: 'Active Alerts',
                  icon: Icons.warning,
                  color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SecurityAlertsScreen())),
                ),
                _ActionCard(
                  title: 'Incident History',
                  icon: Icons.history,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SecurityHistoryScreen())),
                ),
                _ActionCard(
                  title: 'Area Analytics',
                  icon: Icons.analytics,
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AreaAnalyticsScreen())),
                ),
                _ActionCard(
                  title: 'Response Team',
                  icon: Icons.people,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ResponseTeamScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAlertTap(Map<String, dynamic> alert, String alertId) {
    _showEmergencyPopup(alert, alertId);
  }

  void _showEmergencyPopup(Map<String, dynamic> alert, String alertId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[50],
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('🚨 EMERGENCY SOS'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${alert['studentName']}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Location: ${alert['location']}'),
            SizedBox(height: 8),
            Text('Type: ${alert['type']}'),
            if (alert['description'] != null) ...[
              SizedBox(height: 8),
              Text('Description: ${alert['description']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('MINIMIZE'),
          ),
          ElevatedButton(
            onPressed: () {
              _acknowledgeAlert(alertId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('ACKNOWLEDGE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    try {
      await FirebaseFirestore.instance
          .collection('security_alerts')
          .doc(alertId)
          .update({
        'status': 'acknowledged',
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Alert acknowledged'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecurityAlertsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildDashboard() : SecurityAlertsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Alerts',
          ),
        ],
      ),
    );
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

class _ActiveAlertItem extends StatelessWidget {
  final Map<String, dynamic> alert;
  final String alertId;
  final VoidCallback onTap;

  const _ActiveAlertItem({
    required this.alert,
    required this.alertId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = (alert['timestamp'] as Timestamp).toDate();
    final timeAgo = _getTimeAgo(timestamp);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: Colors.red.shade50,
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning, color: Colors.red, size: 20),
        ),
        title: Text(
          alert['studentName'] ?? 'Unknown Student',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    alert['location'] ?? 'Unknown Location',
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'SOS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
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