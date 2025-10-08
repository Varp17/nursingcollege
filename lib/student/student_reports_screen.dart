// student/student_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentReportsScreen extends StatefulWidget {
  const StudentReportsScreen({super.key});

  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedCategory = 'Safety Concern';
  String _selectedPriority = 'Medium';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Safety Concern',
    'Infrastructure Issue',
    'Harassment',
    'Theft',
    'Other'
  ];

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High'
  ];

  Future<void> _submitReport() async {
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

      await FirebaseFirestore.instance.collection('reports').add({
        'studentUid': user.uid,
        'studentName': userData['name'] ?? 'Student',
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'location': _locationController.text.isEmpty ? null : _locationController.text,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'section': userData['section'],
        'college': userData['college'],
        'department': userData['department'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Report submitted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error submitting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to submit report. Please try again.'),
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
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Report'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'File a Report',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Submit a detailed report about any issues or concerns',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 20),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              SizedBox(height: 16),

              // Priority
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPriority = value!),
              ),
              SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Report Title',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
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
                  'Submit Report',
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