import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyAlertScreen extends StatelessWidget {
  final String incidentId;

  const EmergencyAlertScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    final incidentRef =
    FirebaseFirestore.instance.collection('incidents').doc(incidentId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🚨 Emergency Alert"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: incidentRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Incident not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Type: ${data['type'] ?? 'SOS'}",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Location: ${data['section'] ?? 'Unknown'}"),
                    const SizedBox(height: 8),
                    Text("Status: ${data['status'] ?? 'pending'}"),
                    const SizedBox(height: 8),
                    if (data['timestamp'] != null)
                      Text("Reported at: ${data['timestamp'].toDate()}"),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await incidentRef.update({
                          'status': 'acknowledged',
                          'acknowledged_at': FieldValue.serverTimestamp(),
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("Acknowledge Incident"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
