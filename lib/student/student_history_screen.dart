// student/student_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentHistoryScreen extends StatefulWidget {
  const StudentHistoryScreen({super.key});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  String _selectedFilter = 'all';
  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'All Reports'},
    {'value': 'incidents', 'label': 'SOS Incidents'},
    {'value': 'reports', 'label': 'Reports'},
    {'value': 'complaints', 'label': 'Complaints'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My History'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: 'Filter by Type',
                border: OutlineInputBorder(),
              ),
              items: _filters.map((filter) {
                return DropdownMenuItem(
                  value: filter['value'],
                  child: Text(filter['label']!),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
          ),

          // History List
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Center(child: Text('Please login'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .where('studentUid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final incidents = snapshot.data!.docs;

        if (incidents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No history yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text('Your reports will appear here'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final doc = incidents[index];
            final incident = doc.data() as Map<String, dynamic>;
            return _HistoryItem(incident: incident);
          },
        );
      },
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> incident;

  const _HistoryItem({required this.incident});

  @override
  Widget build(BuildContext context) {
    final timestamp = (incident['timestamp'] as Timestamp).toDate();
    final status = incident['status'] ?? 'pending';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          _getTypeIcon(incident['type']),
          color: _getStatusColor(status),
        ),
        title: Text(
          incident['type'] ?? 'SOS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (incident['description'] != null)
              Text(
                incident['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 12),
                SizedBox(width: 4),
                Text(
                  incident['location'] ?? 'Unknown',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: _StatusChip(status: status),
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'SOS':
        return Icons.warning;
      case 'Standard SOS':
        return Icons.emergency;
      case 'Girls SOS':
        return Icons.female;
      default:
        return Icons.report;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'acknowledged':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'PENDING';
        break;
      case 'acknowledged':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        label = 'ACKNOWLEDGED';
        break;
      case 'resolved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'RESOLVED';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        label = status.toUpperCase();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}