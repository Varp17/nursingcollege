import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _sending = false;
  String _selectedType = 'Medical Emergency';
  String _selectedSection = 'General Ward';
  bool _anonymous = false;

  Future<void> _sendSOS() async {
    setState(()=>_sending=true);
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'anonymous';
    final id = const Uuid().v4();
    final docRef = FirebaseFirestore.instance.collection('incidents').doc(id);
    await docRef.set({
      'id': id,
      'type': _selectedType,
      'section': _selectedSection,
      'anonymous': _anonymous,
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
      'studentUid': uid,
      'confidence': 'medium',
    });
    // Cloud Function triggers on new document and sends FCM to security
    setState(()=>_sending=false);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('SOS Sent'),
      content: Text('Incident sent for $_selectedType at $_selectedSection'),
      actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('OK'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Home')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Emergency', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946), padding: const EdgeInsets.symmetric(vertical:24, horizontal:48)),
              onPressed: _sending ? null : _sendSOS,
              child: _sending ? const CircularProgressIndicator() : const Text('SOS', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'Harassment', child: Text('Harassment')),
                DropdownMenuItem(value: 'Ragging', child: Text('Ragging')),
                DropdownMenuItem(value: 'Patient Violence', child: Text('Patient Violence')),
                DropdownMenuItem(value: 'Fight in Parking', child: Text('Fight in Parking')),
                DropdownMenuItem(value: 'Medical Emergency', child: Text('Medical Emergency')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v){ if (v!=null) setState(()=>_selectedType=v); },
              decoration: const InputDecoration(labelText: 'SOS Type'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSection,
              items: const [
                DropdownMenuItem(value: 'Parking', child: Text('Parking')),
                DropdownMenuItem(value: 'Waiting Lounge', child: Text('Waiting Lounge')),
                DropdownMenuItem(value: 'ICU-1', child: Text('ICU-1')),
                DropdownMenuItem(value: 'General Ward', child: Text('General Ward')),
                DropdownMenuItem(value: 'ER', child: Text('ER')),
                DropdownMenuItem(value: 'Classroom Block A', child: Text('Classroom Block A')),
                DropdownMenuItem(value: 'Library', child: Text('Library')),
                DropdownMenuItem(value: 'Canteen', child: Text('Canteen')),
                DropdownMenuItem(value: 'Hostel (Girls)', child: Text('Hostel (Girls)')),
                DropdownMenuItem(value: 'Hostel (Boys)', child: Text('Hostel (Boys)')),
              ],
              onChanged: (v){ if (v!=null) setState(()=>_selectedSection=v); },
              decoration: const InputDecoration(labelText: 'Section'),
            ),
            SwitchListTile(title: const Text('Send Anonymously'), value: _anonymous, onChanged: (v)=>setState(()=>_anonymous=v)),
          ],
        ),
      ),
    );
  }
}
