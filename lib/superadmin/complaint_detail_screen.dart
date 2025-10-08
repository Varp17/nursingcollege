// superadmin/complaint_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final String complaintId;
  final Map<String, dynamic> complaint;

  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
    required this.complaint,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = (complaint['timestamp'] as Timestamp).toDate();
    final status = complaint['status'] ?? 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Text('Complaint Details'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          ComplaintStatusDropdown(complaintId: complaintId, currentStatus: status),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            complaint['type'] ?? 'Complaint',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                        StatusChip(status: status),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ID: $complaintId',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Student Information
            InfoSection(
              title: 'Submitted By',
              icon: Icons.person,
              children: [
                InfoRow(label: 'Name', value: complaint['studentName'] ?? 'Unknown'),
                InfoRow(label: 'Department', value: complaint['department'] ?? 'Not specified'),
                InfoRow(label: 'College', value: complaint['college'] ?? 'Not specified'),
                InfoRow(label: 'Section', value: complaint['section'] ?? 'Not specified'),
              ],
            ),
            SizedBox(height: 16),

            // Complaint Details
            InfoSection(
              title: 'Complaint Details',
              icon: Icons.feedback,
              children: [
                InfoRow(label: 'Type', value: complaint['type'] ?? 'General'),
                InfoRow(label: 'Submitted', value: DateFormat('MMM dd, yyyy - HH:mm').format(timestamp)),
              ],
            ),
            SizedBox(height: 16),

            // Complaint Content
            InfoSection(
              title: 'Complaint',
              icon: Icons.description,
              children: [
                Text(
                  complaint['complaint'] ?? 'No complaint details provided',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Suggestion
            if (complaint['suggestion'] != null && complaint['suggestion'].isNotEmpty)
              Column(
                children: [
                  InfoSection(
                    title: 'Suggestion for Improvement',
                    icon: Icons.lightbulb_outline,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          complaint['suggestion'],
                          style: TextStyle(fontSize: 14, height: 1.4, color: Colors.green.shade800),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),

            // Timeline
            InfoSection(
              title: 'Status Timeline',
              icon: Icons.history,
              children: [
                TimelineItem(
                  status: 'Submitted',
                  time: timestamp,
                  isActive: true,
                ),
                if (complaint['acknowledgedAt'] != null)
                  TimelineItem(
                    status: 'Acknowledged',
                    time: (complaint['acknowledgedAt'] as Timestamp).toDate(),
                    isActive: true,
                    acknowledgedBy: complaint['acknowledgedBy'],
                  ),
                if (complaint['resolvedAt'] != null)
                  TimelineItem(
                    status: 'Resolved',
                    time: (complaint['resolvedAt'] as Timestamp).toDate(),
                    isActive: true,
                    resolvedBy: complaint['resolvedBy'],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Status Dropdown for Complaints
class ComplaintStatusDropdown extends StatefulWidget {
  final String complaintId;
  final String currentStatus;

  const ComplaintStatusDropdown({
    required this.complaintId,
    required this.currentStatus,
  });

  @override
  State<ComplaintStatusDropdown> createState() => _ComplaintStatusDropdownState();
}

class _ComplaintStatusDropdownState extends State<ComplaintStatusDropdown> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedStatus,
      onChanged: (String? newValue) {
        if (newValue != null) {
          _updateStatus(newValue);
        }
      },
      items: <String>['pending', 'acknowledged', 'resolved']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value.toUpperCase()),
        );
      }).toList(),
    );
  }

  void _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaintId)
          .update({
        'status': newStatus,
        '${newStatus}At': FieldValue.serverTimestamp(),
        '${newStatus}By': 'Super Admin',
      });

      setState(() {
        _selectedStatus = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${newStatus.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Shared Components (Copy these to all detail screens)
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'acknowledged':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'resolved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const InfoSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue.shade800),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineItem extends StatelessWidget {
  final String status;
  final DateTime time;
  final bool isActive;
  final String? acknowledgedBy;
  final String? resolvedBy;

  const TimelineItem({
    required this.status,
    required this.time,
    required this.isActive,
    this.acknowledgedBy,
    this.resolvedBy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(time),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (acknowledgedBy != null)
                  Text(
                    'By: $acknowledgedBy',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (resolvedBy != null)
                  Text(
                    'By: $resolvedBy',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}