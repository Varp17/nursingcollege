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
                filled: true,
                fillColor: Colors.grey.shade50,
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
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Please login to view history'),
          ],
        ),
      );
    }

    // Determine which collection to query based on filter
    CollectionReference collection;
    String documentType;

    switch (_selectedFilter) {
      case 'incidents':
        collection = FirebaseFirestore.instance.collection('incidents');
        documentType = 'incident';
        break;
      case 'reports':
        collection = FirebaseFirestore.instance.collection('reports');
        documentType = 'report';
        break;
      case 'complaints':
        collection = FirebaseFirestore.instance.collection('complaints');
        documentType = 'complaint';
        break;
      default:
      // For 'all', we'll show incidents by default
        collection = FirebaseFirestore.instance.collection('incidents');
        documentType = 'incident';
    }

    return StreamBuilder<QuerySnapshot>(
      stream: collection
          .where('studentUid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                Text('Your ${_filters.firstWhere((f) => f['value'] == _selectedFilter)['label']!.toLowerCase()} will appear here'),
              ],
            ),
          );
        }

        final documents = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            final data = doc.data() as Map<String, dynamic>;
            return _HistoryItem(
              data: data,
              documentType: documentType,
            );
          },
        );
      },
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final String documentType;

  const _HistoryItem({
    required this.data,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final status = data['status'] ?? 'pending';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getTypeIcon(documentType, data['type']),
            color: _getStatusColor(status),
          ),
        ),
        title: Text(
          _getTitle(documentType, data),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['description'] != null && data['description'].toString().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  data['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            if (data['location'] != null && data['location'].toString().isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on, size: 12, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    data['location'],
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: _StatusChip(status: status),
      ),
    );
  }

  String _getTitle(String docType, Map<String, dynamic> data) {
    switch (docType) {
      case 'incident':
        return data['type'] ?? 'SOS Incident';
      case 'report':
        return data['title'] ?? 'Report';
      case 'complaint':
        return data['type'] ?? 'Complaint';
      default:
        return 'Document';
    }
  }

  IconData _getTypeIcon(String docType, String? specificType) {
    switch (docType) {
      case 'incident':
        return Icons.warning;
      case 'report':
        return Icons.assignment;
      case 'complaint':
        return Icons.feedback;
      default:
        return Icons.description;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'acknowledged':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
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