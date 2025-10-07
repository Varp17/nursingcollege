import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vibration/vibration.dart';

class StudentSosScreen extends StatefulWidget {
  const StudentSosScreen({super.key});

  @override
  State<StudentSosScreen> createState() => _StudentSosScreenState();
}

class _StudentSosScreenState extends State<StudentSosScreen> {
  String? chosenType;
  String? chosenLocation;
  final TextEditingController desc = TextEditingController();
  bool anonymous = false;
  bool sending = false;

  final List<String> types = ["Standard SOS", "Girls SOS"];
  final List<String> locations = [
    "Ground Floor", "First Floor", "Second Floor", "Classroom",
    "Laboratory", "Library", "Canteen", "Parking", "Outside Campus"
  ];

  Future<void> _sendSOS(String status) async {
    setState(() => sending = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final user = FirebaseAuth.instance.currentUser;

    final payload = {
      'studentUid': anonymous ? 'anonymous' : uid,
      'studentName': anonymous ? 'Anonymous' : user?.displayName ?? 'Student',
      'type': chosenType ?? 'SOS',
      'location': chosenLocation ?? 'Unknown',
      'description': desc.text.trim().isNotEmpty ? desc.text.trim() : null,
      'anonymous': anonymous,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // Save to incidents collection
      final docRef = await FirebaseFirestore.instance.collection('incidents').add(payload);
      final incidentId = docRef.id;
      await docRef.update({'incidentId': incidentId});

      // 🔥 FREE: Create real-time security alert
      await _createSecurityAlert(incidentId, payload);

      setState(() {
        chosenType = null;
        chosenLocation = null;
        desc.clear();
        anonymous = false;
      });

      Vibration.vibrate(duration: 300);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ SOS sent! Security will be notified immediately'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send SOS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => sending = false);
    }
  }

  // 🔥 FREE: Create security alert that triggers real-time updates
  Future<void> _createSecurityAlert(String incidentId, Map<String, dynamic> incidentData) async {
    try {
      final alertData = {
        'incidentId': incidentId,
        'studentName': incidentData['studentName'],
        'location': incidentData['location'],
        'type': incidentData['type'],
        'description': incidentData['description'],
        'timestamp': FieldValue.serverTimestamp(),
        'priority': 'high',
        'status': 'new', // new, acknowledged, resolved
        'alertType': 'sos_emergency',
        'readBy': [], // Track which security users have seen this
      };

      await FirebaseFirestore.instance
          .collection('security_alerts')
          .doc(incidentId)
          .set(alertData);

      print('🔔 Security alert created: $incidentId');
    } catch (e) {
      print('Error creating security alert: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send SOS'), backgroundColor: Colors.redAccent),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send SOS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Select SOS Type:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...types.map((e) => RadioListTile(
                  title: Text(e),
                  value: e,
                  groupValue: chosenType,
                  onChanged: (v) => setState(() => chosenType = v))),
              const SizedBox(height: 16),
              const Text('Select Location:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...locations.map((e) => RadioListTile(
                  title: Text(e),
                  value: e,
                  groupValue: chosenLocation,
                  onChanged: (v) => setState(() => chosenLocation = v))),
              const SizedBox(height: 16),
              TextField(
                controller: desc,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Optional description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              Row(children: [
                Checkbox(value: anonymous, onChanged: (v) => setState(() => anonymous = v ?? false)),
                const Text('Send anonymously')
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: sending ? null : () => _sendSOS('sent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(sending ? 'Sending SOS...' : '🚨 SEND EMERGENCY SOS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}