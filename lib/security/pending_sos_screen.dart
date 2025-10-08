// lib/security/pending_sos_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PendingSOSScreen extends StatefulWidget {
  const PendingSOSScreen({super.key});

  @override
  State<PendingSOSScreen> createState() => _PendingSOSScreenState();

}

class _PendingSOSScreenState extends State<PendingSOSScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> _shownAlertIds = [];

  @override
  void initState() {
    super.initState();
    _setupRealtimeAlerts();
  }

  void _setupRealtimeAlerts() {
    _firestore
        .collection('security_alerts')
        .where('status', isEqualTo: 'new')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added && !_shownAlertIds.contains(doc.doc.id)) {
          _shownAlertIds.add(doc.doc.id);
          final data = doc.doc.data();
          if (data != null) {
            _showEmergencyPopup(data, doc.doc.id);
          }
        }
      }
    });
  }

  void _showEmergencyPopup(Map<String, dynamic> data, String incidentId) async {
    // Vibrate for emergency
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1000);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmergencyAlertDialog(
        alertData: data,
        incidentId: incidentId,
        onAcknowledge: () => _updateAlertStatus(incidentId, 'acknowledged'),
        onResolve: () => _updateAlertStatus(incidentId, 'resolved'), alert: {}, securityName: '', alertId: '',
      ),
    );
  }

  Future<void> _updateAlertStatus(String alertId, String status) async {
    final user = _auth.currentUser;
    final userName = user?.displayName ?? 'Security';

    try {
      await _firestore
          .collection('security_alerts')
          .doc(alertId)
          .update({
        'status': status,
        '${status}By': userName,
        '${status}At': FieldValue.serverTimestamp(),
      });

      // Also update the incident
      await _firestore
          .collection('incidents')
          .doc(alertId)
          .update({
        'status': status,
        '${status}By': userName,
        '${status}At': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert marked as ${status.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pending SOS Alerts"),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('security_alerts')
            .where('status', isEqualTo: 'new')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: Text('No data available'));
          }

          final alerts = snapshot.data!.docs;

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    "No Pending Alerts",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "All emergencies are handled",
                    style: TextStyle(color: Colors.grey),
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
              final alertData = alert.data() as Map<String, dynamic>;

              return EmergencyAlertCard(
                alertData: alertData,
                alertId: alert.id,
                onAcknowledge: () => _updateAlertStatus(alert.id, 'acknowledged'),
                onResolve: () => _updateAlertStatus(alert.id, 'resolved'),
              );
            },
          );
        },
      ),
    );
  }
}

class EmergencyAlertDialog extends StatelessWidget {
  final Map<String, dynamic> alertData;
  final String incidentId;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;

  const EmergencyAlertDialog({
    required this.alertData,
    required this.incidentId,
    required this.onAcknowledge,
    required this.onResolve, required Map<String, dynamic> alert, required String securityName, required String alertId,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = (alertData['timestamp'] as Timestamp).toDate();

    return AlertDialog(
      backgroundColor: Colors.red[50],
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 28),
          SizedBox(width: 10),
          Text(
            '🚨 EMERGENCY SOS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(icon: Icons.person, label: 'Student', value: alertData['studentName'] ?? 'Unknown'),
            _InfoRow(icon: Icons.location_on, label: 'Location', value: alertData['location'] ?? 'Unknown'),
            _InfoRow(icon: Icons.warning, label: 'Emergency Type', value: alertData['type'] ?? 'SOS'),
            if (alertData['description'] != null && alertData['description'].toString().isNotEmpty)
              _InfoRow(icon: Icons.description, label: 'Description', value: alertData['description']),
            _InfoRow(icon: Icons.access_time, label: 'Time', value: _formatTime(timestamp)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('MINIMIZE', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            onAcknowledge();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: Text('ACKNOWLEDGE', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () {
            onResolve();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: Text('RESOLVE', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class EmergencyAlertCard extends StatelessWidget {
  final Map<String, dynamic> alertData;
  final String alertId;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;

  const EmergencyAlertCard({
    required this.alertData,
    required this.alertId,
    required this.onAcknowledge,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = (alertData['timestamp'] as Timestamp).toDate();
    final timeAgo = _getTimeAgo(timestamp);

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.red.shade50,
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
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      alertData['type'] ?? 'EMERGENCY',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SOS',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _InfoRow(icon: Icons.person, label: 'Student', value: alertData['studentName'] ?? 'Unknown'),
            _InfoRow(icon: Icons.location_on, label: 'Location', value: alertData['location'] ?? 'Unknown'),
            if (alertData['description'] != null && alertData['description'].toString().isNotEmpty)
              _InfoRow(icon: Icons.description, label: 'Description', value: alertData['description']),
            _InfoRow(icon: Icons.access_time, label: 'Reported', value: timeAgo),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAcknowledge,
                    icon: Icon(Icons.check, size: 18),
                    label: Text('Acknowledge'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onResolve,
                    icon: Icon(Icons.verified, size: 18),
                    label: Text('Resolve'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}