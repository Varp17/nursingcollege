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

  String _selectedType = 'Academic';
  bool _isSubmitting = false;

  final List<String> _complaintTypes = [
    'Academic',
    'Administrative',
    'Infrastructure',
    'Faculty',
    'Canteen',
    'Transport',
    'Other'
  ];

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user data for additional fields
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      await FirebaseFirestore.instance.collection('complaints').add({
        'studentUid': user.uid,
        'studentName': userData['name'] ?? 'Student',
        'type': _selectedType,
        'complaint': _complaintController.text,
        'suggestion': _suggestionController.text.isEmpty ? null : _suggestionController.text,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'section': userData['section'],
        'college': userData['college'],
        'department': userData['department'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear form
      _complaintController.clear();
      _suggestionController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Complaint submitted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error submitting complaint: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to submit complaint. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Complaint'),
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
                'File a Complaint',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Share your concerns and suggestions for improvement',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 20),

              // Complaint Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Complaint Type',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Complaint Details',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe your complaint';
                  }
                  if (value.length < 10) {
                    return 'Please provide more details (at least 10 characters)';
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
                  labelText: 'Suggestions for Improvement (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Submitting...'),
                  ],
                )
                    : Text(
                  'Submit Complaint',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}