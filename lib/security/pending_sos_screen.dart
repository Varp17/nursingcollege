// lib/security/pending_sos_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PendingSOSScreen extends StatefulWidget {
  const PendingSOSScreen({super.key});

  @override
  State<PendingSOSScreen> createState() => _PendingSOSScreenState();
}

class _PendingSOSScreenState extends State<PendingSOSScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _shownAlertIds = [];

  @override
  void initState() {
    super.initState();

    // Initialize FCM notifications
    _initFCM();

    // Listen to Firestore for new pending incidents (real-time)
    _firestore
        .collection('incidents')
        .where('status', isEqualTo: 'sent')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var alert in snapshot.docs) {
        if (!_shownAlertIds.contains(alert.id)) {
          _shownAlertIds.add(alert.id);
          _showCenteredPopup(alert.data(), alert.id);
        }
      }
    });
  }

  Future<void> _initFCM() async {
    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((msg) {
      final data = msg.data;
      final incidentId = data['incidentId'];
      if (incidentId != null && !_shownAlertIds.contains(incidentId)) {
        _firestore.collection('incidents').doc(incidentId).get().then((doc) {
          if (doc.exists) {
            _shownAlertIds.add(incidentId);
            _showCenteredPopup(doc.data()!, incidentId);
          }
        });
      }
    });

    // Handle taps when app is backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final data = msg.data;
      final incidentId = data['incidentId'];
      if (incidentId != null) {
        _firestore.collection('incidents').doc(incidentId).get().then((doc) {
          if (doc.exists) {
            _showCenteredPopup(doc.data()!, incidentId);
          }
        });
      }
    });
  }

  void _showCenteredPopup(Map<String, dynamic> data, String incidentId) {
    showDialog(
      context: context,
      barrierDismissible: false, // forces user to act
      builder: (context) => AlertDialog(
        title: Text("🚨 ${data['type'] ?? 'SOS'} Alert"),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text("Student: ${data['studentName'] ?? 'Anonymous'}"),
              Text("Section: ${data['section'] ?? 'Unknown'}"),
              Text("Location: ${data['location'] ?? 'Unknown'}"),
              Text("Description: ${data['description'] ?? 'None'}"),
              if (data['timestamp'] != null)
                Text("Reported at: ${(data['timestamp'] as Timestamp).toDate()}"),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _firestore
                  .collection('incidents')
                  .doc(incidentId)
                  .update({'status': 'acknowledged'});
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Acknowledge"),
          ),
          ElevatedButton(
            onPressed: () {
              _firestore
                  .collection('incidents')
                  .doc(incidentId)
                  .update({'status': 'resolved'});
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Resolve"),
          ),
        ],
      ),
    );

    // Vibrate device for alert
    Vibration.vibrate(duration: 500);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending SOS Alerts"),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('incidents')
            .where('status', isEqualTo: 'sent')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final alerts = snapshot.data!.docs;

          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                "No pending SOS alerts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final data = alerts[index];
              final alertData = data.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    alertData['type'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Location: ${alertData['location'] ?? 'Unknown'}\nDescription: ${alertData['description'] ?? 'None'}",
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      _firestore
                          .collection('incidents')
                          .doc(data.id)
                          .update({'status': 'resolved'});
                    },
                    child: const Text('Resolve'),
                  ),
                  onTap: () => _showCenteredPopup(alertData, data.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
