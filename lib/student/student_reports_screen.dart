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
      await FirebaseFirestore.instance.collection('reports').add({
        'studentUid': user?.uid,
        'studentName': user?.displayName ?? 'Student',
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'location': _locationController.text,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Report submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to submit report: $e'),
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
                    : Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}