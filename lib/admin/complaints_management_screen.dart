import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ComplaintsManagementScreen extends StatefulWidget {
  final String username;
  final String department;

  const ComplaintsManagementScreen({
    super.key,
    required this.username,
    required this.department,
  });

  @override
  State<ComplaintsManagementScreen> createState() => _ComplaintsManagementScreenState();
}

class _ComplaintsManagementScreenState extends State<ComplaintsManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all';
  String _filterPriority = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints Management'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddComplaintDialog(context),
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
                    labelText: 'Search complaints...',
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
                          DropdownMenuItem(value: 'all', child: Text('All Status')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'inProgress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterStatus = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterPriority,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Priority')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterPriority = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Complaints List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('complaints')
                  .where('department', isEqualTo: widget.department)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var complaints = snapshot.data!.docs;

                // Apply filters
                if (_filterStatus != 'all') {
                  complaints = complaints.where((doc) => doc['status'] == _filterStatus).toList();
                }

                if (_filterPriority != 'all') {
                  complaints = complaints.where((doc) => doc['priority'] == _filterPriority).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  complaints = complaints.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title']?.toString().toLowerCase() ?? '';
                    final description = data['description']?.toString().toLowerCase() ?? '';
                    final type = data['type']?.toString().toLowerCase() ?? '';
                    return title.contains(_searchQuery) ||
                        description.contains(_searchQuery) ||
                        type.contains(_searchQuery);
                  }).toList();
                }

                if (complaints.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.report_problem, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No Complaints Found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    final data = complaint.data() as Map<String, dynamic>;
                    return _buildComplaintCard(data, complaint.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> data, String complaintId) {
    final status = data['status'] ?? 'pending';
    final priority = data['priority'] ?? 'medium';
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showComplaintDetails(context, data, complaintId),
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
                      data['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      _buildStatusChip(status),
                      const SizedBox(width: 8),
                      _buildPriorityChip(priority),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['description'] ?? 'No description provided',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    data['type'] ?? 'General',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    data['reportedBy'] ?? 'Unknown',
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
              if (data['assignedTo'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.assignment_ind, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned to: ${data['assignedTo']}',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
      case 'inProgress':
        color = Colors.blue;
      case 'resolved':
        color = Colors.green;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'high':
        color = Colors.red;
      case 'medium':
        color = Colors.orange;
      case 'low':
        color = Colors.green;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        priority.toUpperCase(),
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
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

  void _showComplaintDetails(BuildContext context, Map<String, dynamic> data, String complaintId) {
    showDialog(
      context: context,
      builder: (context) => ComplaintDetailsDialog(
        data: data,
        complaintId: complaintId,
        username: widget.username,
        onStatusUpdate: (newStatus) {
          _updateComplaintStatus(complaintId, newStatus);
        },
        onAssign: (assignTo) {
          _assignComplaint(complaintId, assignTo);
        },
      ),
    );
  }

  void _updateComplaintStatus(String complaintId, String newStatus) {
    _firestore.collection('complaints').doc(complaintId).update({
      'status': newStatus,
      'updatedBy': widget.username,
      'updatedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Complaint status updated to $newStatus')),
      );
    });
  }

  void _assignComplaint(String complaintId, String assignTo) {
    _firestore.collection('complaints').doc(complaintId).update({
      'assignedTo': assignTo,
      'assignedAt': FieldValue.serverTimestamp(),
      'assignedBy': widget.username,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Complaint assigned to $assignTo')),
      );
    });
  }

  void _showAddComplaintDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'General';
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Log New Complaint'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Complaint Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'General', child: Text('General')),
                      DropdownMenuItem(value: 'Medical', child: Text('Medical')),
                      DropdownMenuItem(value: 'Facility', child: Text('Facility')),
                      DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                      DropdownMenuItem(value: 'Security', child: Text('Security')),
                      DropdownMenuItem(value: 'Administrative', child: Text('Administrative')),
                    ],
                    onChanged: (value) => setState(() => selectedType = value!),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium Priority')),
                      DropdownMenuItem(value: 'high', child: Text('High Priority')),
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
                  _createComplaint(
                    titleController.text,
                    descriptionController.text,
                    selectedType,
                    selectedPriority,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Create Complaint'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createComplaint(String title, String description, String type, String priority) {
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    _firestore.collection('complaints').add({
      'title': title,
      'description': description,
      'type': type,
      'priority': priority,
      'status': 'pending',
      'department': widget.department,
      'reportedBy': widget.username,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint logged successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating complaint: $error')),
      );
    });
  }
}

class ComplaintDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final String complaintId;
  final String username;
  final Function(String) onStatusUpdate;
  final Function(String) onAssign;

  const ComplaintDetailsDialog({
    super.key,
    required this.data,
    required this.complaintId,
    required this.username,
    required this.onStatusUpdate,
    required this.onAssign,
  });

  @override
  State<ComplaintDetailsDialog> createState() => _ComplaintDetailsDialogState();
}

class _ComplaintDetailsDialogState extends State<ComplaintDetailsDialog> {
  String? _selectedAssignee;

  @override
  Widget build(BuildContext context) {
    final timestamp = widget.data['timestamp'] != null
        ? (widget.data['timestamp'] as Timestamp).toDate()
        : DateTime.now();

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
                  'Complaint Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Complaint Information
            _buildDetailSection('Complaint Information', [
              _buildDetailRow('Title:', widget.data['title'] ?? 'No Title'),
              _buildDetailRow('Description:', widget.data['description'] ?? 'No description'),
              _buildDetailRow('Category:', widget.data['type'] ?? 'General'),
              _buildDetailRow('Priority:', widget.data['priority']?.toString().toUpperCase() ?? 'MEDIUM'),
              _buildDetailRow('Status:', widget.data['status']?.toString().toUpperCase() ?? 'PENDING'),
              _buildDetailRow('Reported by:', widget.data['reportedBy'] ?? 'Unknown'),
              _buildDetailRow('Department:', widget.data['department'] ?? 'Not specified'),
              _buildDetailRow('Reported on:', DateFormat('MMM d, yyyy - HH:mm').format(timestamp)),
            ]),

            const SizedBox(height: 20),

            // Assignment Section
            _buildDetailSection('Assignment', [
              if (widget.data['assignedTo'] != null) ...[
                _buildDetailRow('Assigned to:', widget.data['assignedTo']!),
                if (widget.data['assignedAt'] != null)
                  _buildDetailRow('Assigned on:',
                      DateFormat('MMM d, yyyy - HH:mm')
                          .format((widget.data['assignedAt'] as Timestamp).toDate())),
              ] else ...[
                const Text('Not assigned', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                _buildAssignmentDropdown(),
              ],
            ]),

            const SizedBox(height: 20),

            // Actions
            _buildDetailSection('Actions', [
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: widget.data['status'] ?? 'pending',
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'inProgress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                      ],
                      onChanged: (newStatus) {
                        widget.onStatusUpdate(newStatus!);
                        Navigator.pop(context);
                      },
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_selectedAssignee != null || widget.data['assignedTo'] != null)
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedAssignee != null) {
                          widget.onAssign(_selectedAssignee!);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Assign'),
                    ),
                ],
              ),
            ]),

            const SizedBox(height: 20),

            // Timeline (if available)
            if (widget.data['updates'] != null)
              _buildDetailSection('Timeline', [
                // Would show status update history
                const Text('No updates available', style: TextStyle(color: Colors.grey)),
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

  Widget _buildAssignmentDropdown() {
    // In a real app, this would fetch security team members from Firestore
    const securityTeam = ['Security Officer 1', 'Security Officer 2', 'Security Team A'];

    return DropdownButtonFormField<String>(
      value: _selectedAssignee,
      items: securityTeam.map((member) {
        return DropdownMenuItem(value: member, child: Text(member));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedAssignee = value;
        });
      },
      decoration: const InputDecoration(
        labelText: 'Assign to Security Team',
        border: OutlineInputBorder(),
      ),
    );
  }
}