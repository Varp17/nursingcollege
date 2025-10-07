import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';

class EmergencyAlertScreen extends StatefulWidget {
  final String incidentId;

  const EmergencyAlertScreen({super.key, required this.incidentId});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _incidentData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchIncident();
    Vibration.vibrate(pattern: [0, 500, 200, 500]);
  }

  Future<void> _fetchIncident() async {
    final doc = await _firestore.collection('incidents').doc(widget.incidentId).get();
    if (doc.exists) {
      setState(() {
        _incidentData = doc.data();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incident not found")),
      );
    }
  }

  Future<void> _updateStatus(String status) async {
    await _firestore.collection('incidents').doc(widget.incidentId).update({
      'status': status,
      if (status == 'acknowledged') 'acknowledged_at': FieldValue.serverTimestamp(),
      if (status == 'resolved') 'resolved_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Incident marked as $status")),
    );
    Navigator.pop(context);
  }

  String _timeSince(Timestamp? ts) {
    if (ts == null) return "Unknown";
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inHours < 1) return "${diff.inMinutes} min ago";
    if (diff.inDays < 1) return "${diff.inHours} hr ago";
    return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Alert"),
        backgroundColor: Colors.redAccent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _incidentData == null
          ? const Center(child: Text("Incident data not available"))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.red.shade100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🚨 ${_incidentData!['type'] ?? 'SOS'}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text("Student: ${_incidentData!['studentName'] ?? 'Anonymous'}"),
                    Text("Location: ${_incidentData!['location'] ?? 'Unknown'}"),
                    Text(
                        "Desc: ${_incidentData!['description'] ?? 'None'}"),
                    const SizedBox(height: 8),
                    Text(
                      "Sent: ${_timeSince(_incidentData!['timestamp'])}",
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          onPressed: () => _updateStatus('acknowledged'),
                          child: const Text("Acknowledge"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => _updateStatus('resolved'),
                          child: const Text("Resolve"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Optional: History / timeline
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('incidents')
                    .doc(widget.incidentId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  return ListView(
                    children: [
                      _buildStatusTile(
                          "Sent", data['timestamp'], data['status'] == 'sent'),
                      _buildStatusTile("Acknowledged",
                          data['acknowledged_at'], data['status'] == 'acknowledged'),
                      _buildStatusTile("Resolved",
                          data['resolved_at'], data['status'] == 'resolved'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTile(String label, Timestamp? ts, bool active) {
    return ListTile(
      leading: Icon(
        active ? Icons.check_circle : Icons.radio_button_unchecked,
        color: active ? Colors.green : Colors.grey,
      ),
      title: Text(label),
      subtitle: ts != null ? Text(_timeSince(ts)) : null,
    );
  }
}
