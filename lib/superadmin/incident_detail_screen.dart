// superadmin/incident_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class IncidentDetailScreen extends StatelessWidget {
  final String incidentId;
  final Map<String, dynamic> incident;

  const IncidentDetailScreen({
    super.key,
    required this.incidentId,
    required this.incident,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = (incident['timestamp'] as Timestamp).toDate();
    final status = incident['status'] ?? 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Text('Incident Details'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        actions: [
          IncidentStatusDropdown(incidentId: incidentId, currentStatus: status),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
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
                        Text(
                          incident['type'] ?? 'SOS Incident',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                        StatusChip(status: status),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ID: $incidentId',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Student Information
            InfoSection(
              title: 'Student Information',
              icon: Icons.person,
              children: [
                InfoRow(label: 'Name', value: incident['studentName'] ?? 'Unknown'),
                InfoRow(label: 'Email', value: incident['studentEmail'] ?? 'Not provided'),
                InfoRow(label: 'Anonymous', value: incident['anonymous'] == true ? 'Yes' : 'No'),
                InfoRow(label: 'Department', value: incident['department'] ?? 'Not specified'),
                InfoRow(label: 'College', value: incident['college'] ?? 'Not specified'),
                InfoRow(label: 'Section', value: incident['section'] ?? 'Not specified'),
              ],
            ),
            SizedBox(height: 16),

            // Incident Details
            InfoSection(
              title: 'Incident Details',
              icon: Icons.warning,
              children: [
                InfoRow(label: 'Location', value: incident['location'] ?? 'Unknown'),
                InfoRow(label: 'Priority', value: incident['priority'] ?? 'Medium'),
                InfoRow(label: 'Reported Time', value: DateFormat('MMM dd, yyyy - HH:mm').format(timestamp)),
              ],
            ),
            SizedBox(height: 16),

            // Description
            if (incident['description'] != null && incident['description'].isNotEmpty)
              Column(
                children: [
                  InfoSection(
                    title: 'Description',
                    icon: Icons.description,
                    children: [
                      Text(
                        incident['description'],
                        style: TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),

            // Timeline
            InfoSection(
              title: 'Timeline',
              icon: Icons.history,
              children: [
                TimelineItem(
                  status: 'Reported',
                  time: timestamp,
                  isActive: true,
                ),
                if (incident['acknowledgedAt'] != null)
                  TimelineItem(
                    status: 'Acknowledged',
                    time: (incident['acknowledgedAt'] as Timestamp).toDate(),
                    isActive: true,
                    acknowledgedBy: incident['acknowledgedBy'],
                  ),
                if (incident['resolvedAt'] != null)
                  TimelineItem(
                    status: 'Resolved',
                    time: (incident['resolvedAt'] as Timestamp).toDate(),
                    isActive: true,
                    resolvedBy: incident['resolvedBy'],
                  ),
              ],
            ),
            SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendNotification(context),
                    icon: Icon(Icons.notification_important),
                    label: Text('Notify Security'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewOnMap(context),
                    icon: Icon(Icons.map),
                    label: Text('View on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendNotification(BuildContext context) {
    // Implement notification logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Security team notified about this incident')),
    );
  }

  void _viewOnMap(BuildContext context) async {
    final location = incident['location'];
    if (location != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}';
      try {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch maps')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not available')),
      );
    }
  }
}

// Status Dropdown for Incidents
class IncidentStatusDropdown extends StatefulWidget {
  final String incidentId;
  final String currentStatus;

  const IncidentStatusDropdown({
    required this.incidentId,
    required this.currentStatus,
  });

  @override
  State<IncidentStatusDropdown> createState() => _IncidentStatusDropdownState();
}

class _IncidentStatusDropdownState extends State<IncidentStatusDropdown> {
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
          .collection('incidents')
          .doc(widget.incidentId)
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