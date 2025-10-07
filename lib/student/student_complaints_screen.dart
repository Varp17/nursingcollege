// student/student_complaints_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentComplaintsScreen extends StatefulWidget {
  const StudentComplaintsScreen({super.key});

  @override
  State<StudentComplaintsScreen> createState() => _StudentComplaintsScreenState();
}

class _StudentComplaintsScreenState extends State<StudentComplaintsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _complaintController = TextEditingController();
  final TextEditingController _suggestionController = TextEditingController();

  String _selectedType = 'General Complaint';
  bool _isSubmitting = false;

  final List<String> _complaintTypes = [
    'General Complaint',
    'Faculty Issue',
    'Infrastructure',
    'Administrative',
    'Academic',
    'Other'
  ];

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('complaints').add({
        'studentUid': user?.uid,
        'studentName': user?.displayName ?? 'Student',
        'type': _selectedType,
        'complaint': _complaintController.text,
        'suggestion': _suggestionController.text.isNotEmpty ? _suggestionController.text : null,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear form
      _complaintController.clear();
      _suggestionController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Complaint submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to submit complaint: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Complaint'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Submit a Complaint',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Complaint Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Complaint Type',
                  border: OutlineInputBorder(),
                ),
                items: _complaintTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              SizedBox(height: 16),

              // Complaint Details
              TextFormField(
                controller: _complaintController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Complaint Details',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe your complaint';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Suggestions (Optional)
              TextFormField(
                controller: _suggestionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Suggestions (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(width: 12),
                    Text('Submitting...'),
                  ],
                )
                    : Text('Submit Complaint'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}