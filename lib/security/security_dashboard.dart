// lib/security/security_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vibration/vibration.dart';
import '../common/side_menu.dart';
import '../models/user_role.dart';
import '../theme/theme.dart';
// Import your screens
import 'security_alerts_screen.dart';
import 'security_history_screen.dart';
import 'response_team_screen.dart';
import 'pending_sos_screen.dart';
import 'security_alerts_screen.dart';

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
  String _securityStatus = "Available";
  final List<String> _shownAlertIds = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeSecurityData();
    _setupRealtimeAlerts();
  }

  void _initializeSecurityData() {
    _alertsStream = FirebaseFirestore.instance
        .collection('security_alerts')
        .where('status', isEqualTo: 'new')
        .orderBy('timestamp', descending: true)
        .snapshots();

    _incidentsStream = FirebaseFirestore.instance
        .collection('incidents')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();

    // Load security status
    _loadSecurityStatus();
  }

  void _loadSecurityStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('security_status')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _securityStatus = doc.data()?['status'] ?? "Available";
        });
      }
    }
  }

  void _setupRealtimeAlerts() {
    FirebaseFirestore.instance
        .collection('security_alerts')
        .where('status', isEqualTo: 'new')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added && !_shownAlertIds.contains(doc.doc.id)) {
          _shownAlertIds.add(doc.doc.id);
          final data = doc.doc.data();
          if (data != null) {
            _showDetailedEmergencyPopup(data, doc.doc.id);
          }
        }
      }
    });
  }

  Future<void> _acknowledgeAlert(String alertId, String securityName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('security_alerts')
          .doc(alertId)
          .update({
        'status': 'acknowledged',
        'acknowledgedBy': securityName,
        'acknowledgedByUid': user?.uid,
        'acknowledgedAt': FieldValue.serverTimestamp(),
        'readBy': FieldValue.arrayUnion([user?.uid]),
      });

      // Also update the incident
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(alertId)
          .update({
        'status': 'acknowledged',
        'acknowledgedBy': securityName,
        'acknowledgedByUid': user?.uid,
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Alert acknowledged by $securityName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error acknowledging alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Main Dashboard Screen - CORRECTED
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Welcome and Status
          _buildHeader(),
          SizedBox(height: 20),

          // Quick Actions
          _buildQuickActions(),
          SizedBox(height: 20),

          // Quick Stats Row
          _buildQuickStats(),
          SizedBox(height: 20),

          // Security Status Section
          _buildStatusSection(),
          SizedBox(height: 20),

          // Active Alerts Section
          _buildActiveAlertsSection(),
          SizedBox(height: 20),

          // Recent Incidents
          _buildRecentIncidents(),
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
            'Security Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Welcome, ${widget.username}!',
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
                '$activeAlerts Active Alert${activeAlerts != 1 ? 's' : ''} • Status: $_securityStatus',
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

  // Quick Actions Section
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
                _QuickActionCard(
                  title: 'Send Alert',
                  icon: Icons.warning,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SecurityAlertsScreen()),
                    );
                  },
                ),
                _QuickActionCard(
                  title: 'Team Status',
                  icon: Icons.people,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ResponseTeamScreen()),
                    );
                  },
                ),
                _QuickActionCard(
                  title: 'Live Incidents',
                  icon: Icons.live_tv,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PendingSOSScreen()),
                    );
                  },
                ),
                _QuickActionCard(
                  title: 'History',
                  icon: Icons.history,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SecurityHistoryScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _incidentsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildDataUnavailable('Quick Stats');
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

  Widget _buildStatusSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🛡️ Security Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusButton(
                  status: "Available",
                  currentStatus: _securityStatus,
                  icon: Icons.check_circle,
                  color: Colors.green,
                  onTap: () => _updateStatus("Available"),
                ),
                _StatusButton(
                  status: "On My Way",
                  currentStatus: _securityStatus,
                  icon: Icons.directions_run,
                  color: Colors.blue,
                  onTap: () => _updateStatus("On My Way"),
                ),
                _StatusButton(
                  status: "Busy",
                  currentStatus: _securityStatus,
                  icon: Icons.do_not_disturb,
                  color: Colors.orange,
                  onTap: () => _updateStatus("Busy"),
                ),
                _StatusButton(
                  status: "Off Duty",
                  currentStatus: _securityStatus,
                  icon: Icons.offline_bolt,
                  color: Colors.red,
                  onTap: () => _updateStatus("Off Duty"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAlertsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _alertsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildDataUnavailable('Active Alerts');
        }

        final alerts = snapshot.data!.docs;
        final alertCount = alerts.length;

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

                if (alertCount == 0)
                  _buildNoAlertsState()
                else
                  Column(
                    children: [
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

                      if (alertCount > 3)
                        Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PendingSOSScreen(),
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

  Widget _buildRecentIncidents() {
    return StreamBuilder<QuerySnapshot>(
      stream: _incidentsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildDataUnavailable('Recent Incidents');
        }

        final incidents = snapshot.data!.docs.take(5).toList();

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Recent Incidents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                if (incidents.isEmpty)
                  _buildEmptyState('No recent incidents')
                else
                  Column(
                    children: incidents.map((doc) {
                      final incident = doc.data() as Map<String, dynamic>;
                      return _RecentIncidentItem(incident: incident);
                    }).toList(),
                  ),

                SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SecurityHistoryScreen()),
                      );
                    },
                    icon: Icon(Icons.arrow_forward),
                    label: Text('View Full History'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper methods for empty states
  Widget _buildDataUnavailable(String title) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.signal_wifi_off, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              '$title Unavailable',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
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

  void _handleAlertTap(Map<String, dynamic> alert, String alertId) {
    _showDetailedEmergencyPopup(alert, alertId);
  }

  void _showDetailedEmergencyPopup(Map<String, dynamic> alert, String alertId) async {
    // Vibrate for emergency
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => EmergencyAlertDialog(
        alert: alert,
        alertId: alertId,
        securityName: widget.username,
        onAcknowledge: () => _acknowledgeAlert(alertId, widget.username),
        onResolve: () => _resolveAlert(alertId, widget.username),
        alertData: {},
        incidentId: '',
      ),
    );
  }

  Future<void> _resolveAlert(String alertId, String securityName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('security_alerts')
          .doc(alertId)
          .update({
        'status': 'resolved',
        'resolvedBy': securityName,
        'resolvedByUid': user?.uid,
        'resolvedAt': FieldValue.serverTimestamp(),
        'readBy': FieldValue.arrayUnion([user?.uid]),
      });

      // Also update the incident
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(alertId)
          .update({
        'status': 'resolved',
        'resolvedBy': securityName,
        'resolvedByUid': user?.uid,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Alert resolved by $securityName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error resolving alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('security_status')
          .doc(user.uid)
          .set({
        'status': newStatus,
        'name': widget.username,
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      setState(() {
        _securityStatus = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Security Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              setState(() {
                _currentIndex = 1; // Navigate to Alerts screen
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      drawer: SideMenu(
        role: UserRole.security,
        username: widget.username,
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Team',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return PendingSOSScreen();
      case 2:
        return ResponseTeamScreen();
      case 3:
        return SecurityHistoryScreen();
      default:
        return _buildDashboard();
    }
  }
}

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
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

class _StatusButton extends StatelessWidget {
  final String status;
  final String currentStatus;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.status,
    required this.currentStatus,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentStatus == status;

    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: isSelected ? color : Colors.grey,
          iconSize: 28,
          onPressed: onTap,
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? color : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Active Alert Item with Priority
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
    final priority = _getPriorityLevel(alert);
    final priorityColor = _getPriorityColor(priority);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: priorityColor.withOpacity(0.1),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning, color: priorityColor, size: 20),
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
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

  String _getPriorityLevel(Map<String, dynamic> alert) {
    final type = (alert['type'] ?? '').toString().toLowerCase();
    final priority = (alert['priority'] ?? 'medium').toString().toLowerCase();

    if (priority != 'medium') return priority;

    if (type.contains('medical') || type.contains('shooter') || type.contains('fire')) {
      return 'high';
    } else if (type.contains('security') || type.contains('threat')) {
      return 'high';
    } else if (type.contains('suspicious') || type.contains('harassment')) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.blue;
      default: return Colors.grey;
    }
  }
}

// Recent Incident Item with Response Time
class _RecentIncidentItem extends StatelessWidget {
  final Map<String, dynamic> incident;

  const _RecentIncidentItem({required this.incident});

  @override
  Widget build(BuildContext context) {
    final timestamp = (incident['timestamp'] as Timestamp).toDate();
    final status = incident['status'] ?? 'pending';
    final responseTime = _calculateResponseTime(incident);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _getStatusColor(status),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        incident['type'] ?? 'Incident',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${incident['location']} • ${_formatTime(timestamp)}',
            style: TextStyle(fontSize: 12),
          ),
          if (responseTime != null) ...[
            SizedBox(height: 2),
            Text(
              'Response: $responseTime',
              style: TextStyle(
                fontSize: 10,
                color: _getResponseTimeColor(responseTime),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String? _calculateResponseTime(Map<String, dynamic> incident) {
    if (incident['acknowledgedAt'] != null) {
      final reportedAt = (incident['timestamp'] as Timestamp).toDate();
      final acknowledgedAt = (incident['acknowledgedAt'] as Timestamp).toDate();
      final minutes = acknowledgedAt.difference(reportedAt).inMinutes;
      return '${minutes}m';
    }
    return null;
  }

  Color _getResponseTimeColor(String responseTime) {
    final minutes = int.tryParse(responseTime.replaceAll('m', '')) ?? 0;
    if (minutes < 5) return Colors.green;
    if (minutes < 15) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'acknowledged': return Colors.blue;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class EmergencyAlertDialog extends StatelessWidget {
  final Map<String, dynamic> alert;
  final String alertId;
  final String securityName;
  final VoidCallback onAcknowledge; // Changed to VoidCallback
  final VoidCallback onResolve;     // Changed to VoidCallback
  final Map<String, dynamic> alertData;
  final String incidentId;

  const EmergencyAlertDialog({
    Key? key,
    required this.alert,
    required this.alertId,
    required this.securityName,
    required this.onAcknowledge,
    required this.onResolve,
    required this.alertData,
    required this.incidentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timestamp = (alert['timestamp'] as Timestamp).toDate();
    final timeAgo = _getTimeAgo(timestamp);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🚨 EMERGENCY ALERT',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            Text(
              'Student: ${alert['studentName'] ?? 'Unknown'}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            Text('Location: ${alert['location'] ?? 'Unknown'}'),
            SizedBox(height: 8),

            Text('Type: ${alert['type'] ?? 'Emergency'}'),
            SizedBox(height: 8),

            Text('Time: $timeAgo'),
            SizedBox(height: 16),

            if (alert['additionalInfo'] != null) ...[
              Text('Additional Info: ${alert['additionalInfo']}'),
              SizedBox(height: 16),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAcknowledge, // Now uses VoidCallback directly
                    icon: Icon(Icons.check_circle),
                    label: Text('Acknowledge'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onResolve, // Now uses VoidCallback directly
                    icon: Icon(Icons.verified),
                    label: Text('Resolve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
// Keep your existing EmergencyAlertDialog class as it is
// ... (your existing EmergencyAlertDialog code remains the same)