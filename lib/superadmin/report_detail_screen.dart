// superadmin/report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportDetailScreen extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> report;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = (report['timestamp'] as Timestamp).toDate();
    final status = report['status'] ?? 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Text('Report Details'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          ReportStatusDropdown(reportId: reportId, currentStatus: status),
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
                            report['title'] ?? 'Report',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        StatusChip(status: status),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ID: $reportId',
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
                InfoRow(label: 'Name', value: report['studentName'] ?? 'Unknown'),
                InfoRow(label: 'Department', value: report['department'] ?? 'Not specified'),
                InfoRow(label: 'College', value: report['college'] ?? 'Not specified'),
                InfoRow(label: 'Section', value: report['section'] ?? 'Not specified'),
              ],
            ),
            SizedBox(height: 16),

            // Report Details
            InfoSection(
              title: 'Report Details',
              icon: Icons.assignment,
              children: [
                InfoRow(label: 'Category', value: report['category'] ?? 'General'),
                InfoRow(label: 'Priority', value: report['priority'] ?? 'Medium'),
                if (report['location'] != null)
                  InfoRow(label: 'Location', value: report['location']!),
                InfoRow(label: 'Submitted', value: DateFormat('MMM dd, yyyy - HH:mm').format(timestamp)),
              ],
            ),
            SizedBox(height: 16),

            // Description
            InfoSection(
              title: 'Description',
              icon: Icons.description,
              children: [
                Text(
                  report['description'] ?? 'No description provided',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
            SizedBox(height: 16),

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
                if (report['acknowledgedAt'] != null)
                  TimelineItem(
                    status: 'Acknowledged',
                    time: (report['acknowledgedAt'] as Timestamp).toDate(),
                    isActive: true,
                    acknowledgedBy: report['acknowledgedBy'],
                  ),
                if (report['resolvedAt'] != null)
                  TimelineItem(
                    status: 'Resolved',
                    time: (report['resolvedAt'] as Timestamp).toDate(),
                    isActive: true,
                    resolvedBy: report['resolvedBy'],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Status Dropdown for Reports
class ReportStatusDropdown extends StatefulWidget {
  final String reportId;
  final String currentStatus;

  const ReportStatusDropdown({
    required this.reportId,
    required this.currentStatus,
  });

  @override
  State<ReportStatusDropdown> createState() => _ReportStatusDropdownState();
}

class _ReportStatusDropdownState extends State<ReportStatusDropdown> {
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
          .collection('reports')
          .doc(widget.reportId)
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