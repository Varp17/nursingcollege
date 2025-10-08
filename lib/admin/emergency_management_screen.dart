import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmergencyManagementScreen extends StatefulWidget {
  final String username;
  final String department;

  const EmergencyManagementScreen({
    super.key,
    required this.username,
    required this.department,
  });

  @override
  State<EmergencyManagementScreen> createState() => _EmergencyManagementScreenState();
}

class _EmergencyManagementScreenState extends State<EmergencyManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'pending';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts Management'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert),
            onPressed: () => _createNewEmergencyAlert(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters and Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search alerts...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('Pending Alerts')),
                          DropdownMenuItem(value: 'inProgress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                          DropdownMenuItem(value: 'all', child: Text('All Alerts')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterStatus = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Emergency Alerts List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('sos_alerts')
                  .where('department', isEqualTo: widget.department)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var alerts = snapshot.data!.docs;

                // Apply filters
                if (_filterStatus != 'all') {
                  alerts = alerts.where((doc) => doc['status'] == _filterStatus).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  alerts = alerts.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final alertType = data['alertType']?.toString().toLowerCase() ?? '';
                    final location = data['location']?.toString().toLowerCase() ?? '';
                    final reportedBy = data['reportedBy']?.toString().toLowerCase() ?? '';
                    return alertType.contains(_searchQuery) ||
                        location.contains(_searchQuery) ||
                        reportedBy.contains(_searchQuery);
                  }).toList();
                }

                if (alerts.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    final data = alert.data() as Map<String, dynamic>;
                    return _buildEmergencyCard(data, alert.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewEmergencyAlert(context),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add_alert, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _filterStatus == 'pending'
                ? 'No Pending Emergency Alerts'
                : 'No Emergency Alerts Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus == 'pending'
                ? 'All emergency alerts have been addressed'
                : 'Try changing your filters',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(Map<String, dynamic> data, String alertId) {
    final status = data['status'] ?? 'pending';
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final priority = data['priority'] ?? 'high';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEmergencyDetails(context, data, alertId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['alertType'] ?? 'Emergency Alert',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      data['location'] ?? 'Location not specified',
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Reported by: ${data['reportedBy'] ?? 'Unknown'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeAgo(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (data['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  data['description']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityChip(priority),
                  const Spacer(),
                  if (status == 'pending')
                    ElevatedButton(
                      onPressed: () => _updateAlertStatus(alertId, 'inProgress'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Start Response'),
                    ),
                  if (status == 'inProgress')
                    ElevatedButton(
                      onPressed: () => _updateAlertStatus(alertId, 'resolved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Mark Resolved'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.red;
        text = 'PENDING';
      case 'inProgress':
        color = Colors.orange;
        text = 'IN PROGRESS';
      case 'resolved':
        color = Colors.green;
        text = 'RESOLVED';
      default:
        color = Colors.grey;
        text = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    String text;

    switch (priority) {
      case 'high':
        color = Colors.red;
        text = 'HIGH PRIORITY';
      case 'medium':
        color = Colors.orange;
        text = 'MEDIUM PRIORITY';
      case 'low':
        color = Colors.green;
        text = 'LOW PRIORITY';
      default:
        color = Colors.grey;
        text = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.red;
      case 'inProgress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  void _showEmergencyDetails(BuildContext context, Map<String, dynamic> data, String alertId) {
    showDialog(
      context: context,
      builder: (context) => EmergencyDetailsDialog(
        data: data,
        alertId: alertId,
        username: widget.username,
        onStatusUpdate: (newStatus) {
          _updateAlertStatus(alertId, newStatus);
        },
      ),
    );
  }

  void _updateAlertStatus(String alertId, String newStatus) {
    _firestore.collection('sos_alerts').doc(alertId).update({
      'status': newStatus,
      'updatedBy': widget.username,
      'updatedAt': FieldValue.serverTimestamp(),
      if (newStatus == 'inProgress') 'assignedTo': widget.username,
      if (newStatus == 'resolved') 'resolvedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alert status updated to $newStatus')),
      );
    });
  }

  void _createNewEmergencyAlert(BuildContext context) {
    final alertTypeController = TextEditingController();
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'high';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create Emergency Alert'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: alertTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Alert Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    items: const [
                      DropdownMenuItem(value: 'high', child: Text('High Priority')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium Priority')),
                      DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                    ],
                    onChanged: (value) => setState(() => selectedPriority = value!),
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _createAlert(
                    alertTypeController.text,
                    locationController.text,
                    descriptionController.text,
                    selectedPriority,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Create Alert', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createAlert(String alertType, String location, String description, String priority) {
    if (alertType.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    _firestore.collection('sos_alerts').add({
      'alertType': alertType,
      'location': location,
      'description': description.isNotEmpty ? description : null,
      'priority': priority,
      'status': 'pending',
      'department': widget.department,
      'reportedBy': widget.username,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency alert created successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating alert: $error')),
      );
    });
  }
}

class EmergencyDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final String alertId;
  final String username;
  final Function(String) onStatusUpdate;

  const EmergencyDetailsDialog({
    super.key,
    required this.data,
    required this.alertId,
    required this.username,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final resolvedAt = data['resolvedAt'] != null
        ? (data['resolvedAt'] as Timestamp).toDate()
        : null;
    final updatedAt = data['updatedAt'] != null
        ? (data['updatedAt'] as Timestamp).toDate()
        : null;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emergency Alert Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Alert Information
            _buildDetailSection('Alert Information', [
              _buildDetailRow('Alert Type:', data['alertType'] ?? 'Emergency'),
              _buildDetailRow('Location:', data['location'] ?? 'Not specified'),
              _buildDetailRow('Priority:', data['priority']?.toString().toUpperCase() ?? 'HIGH'),
              _buildDetailRow('Status:', data['status']?.toString().toUpperCase() ?? 'PENDING'),
              if (data['description'] != null)
                _buildDetailRow('Description:', data['description']!),
            ]),

            const SizedBox(height: 20),

            // Reporting Information
            _buildDetailSection('Reporting Information', [
              _buildDetailRow('Reported by:', data['reportedBy'] ?? 'Unknown'),
              _buildDetailRow('Department:', data['department'] ?? 'Not specified'),
              _buildDetailRow('Reported on:', DateFormat('MMM d, yyyy - HH:mm').format(timestamp)),
            ]),

            if (data['assignedTo'] != null) ...[
              const SizedBox(height: 20),
              _buildDetailSection('Assignment', [
                _buildDetailRow('Assigned to:', data['assignedTo']!),
                if (updatedAt != null)
                  _buildDetailRow('Last updated:', DateFormat('MMM d, yyyy - HH:mm').format(updatedAt)),
              ]),
            ],

            if (resolvedAt != null) ...[
              const SizedBox(height: 20),
              _buildDetailSection('Resolution', [
                _buildDetailRow('Resolved by:', data['resolvedBy'] ?? 'Unknown'),
                _buildDetailRow('Resolved at:', DateFormat('MMM d, yyyy - HH:mm').format(resolvedAt)),
              ]),
            ],

            const SizedBox(height: 20),

            // Actions
            if (data['status'] != 'resolved')
              _buildDetailSection('Actions', [
                Row(
                  children: [
                    if (data['status'] == 'pending')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            onStatusUpdate('inProgress');
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Response'),
                        ),
                      ),
                    if (data['status'] == 'pending') const SizedBox(width: 12),
                    if (data['status'] == 'inProgress' || data['status'] == 'pending')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            onStatusUpdate('resolved');
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Mark Resolved'),
                        ),
                      ),
                  ],
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}