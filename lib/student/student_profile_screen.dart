// student/student_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          userData = doc.data()!;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.purple.shade100,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.purple,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      userData!['name'] ?? 'Student',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      userData!['email'] ?? user?.email ?? '',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Chip(
                      label: Text(
                        userData!['role']?.toUpperCase() ?? 'STUDENT',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Profile Details
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _ProfileItem(
                      icon: Icons.school,
                      label: 'Student ID',
                      value: userData!['studentId'] ?? 'Not set',
                    ),
                    _ProfileItem(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: userData!['phone'] ?? 'Not set',
                    ),
                    _ProfileItem(
                      icon: Icons.location_city,
                      label: 'Department',
                      value: userData!['department'] ?? 'Not set',
                    ),
                    _ProfileItem(
                      icon: Icons.calendar_today,
                      label: 'Member since',
                      value: _formatDate(userData!['createdAt']),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Emergency Contact
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'In case of emergency, use the SOS button to immediately alert campus security.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to SOS screen
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.warning),
                      label: Text('Go to Emergency SOS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
    }
    return 'Unknown';
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}