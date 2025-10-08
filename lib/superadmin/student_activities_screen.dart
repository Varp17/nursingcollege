// superadmin/student_activities_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'incident_detail_screen.dart';
import 'report_detail_screen.dart';
import 'complaint_detail_screen.dart';

class StudentActivitiesScreen extends StatefulWidget {
  const StudentActivitiesScreen({super.key});

  @override
  State<StudentActivitiesScreen> createState() => _StudentActivitiesScreenState();
}

class _StudentActivitiesScreenState extends State<StudentActivitiesScreen> {
  String _selectedTab = 'incidents';
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Activities Monitor'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Selection
          _buildTabBar(),
          // Search Bar
          _buildSearchBar(),
          // Status Filter
          _buildStatusFilter(),
          // Statistics
          _buildStatistics(),
          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          _TabButton(
            title: 'SOS Incidents',
            isSelected: _selectedTab == 'incidents',
            onTap: () => setState(() => _selectedTab = 'incidents'),
            icon: Icons.warning,
            color: Colors.red,
          ),
          SizedBox(width: 8),
          _TabButton(
            title: 'Reports',
            isSelected: _selectedTab == 'reports',
            onTap: () => setState(() => _selectedTab = 'reports'),
            icon: Icons.assignment,
            color: Colors.blue,
          ),
          SizedBox(width: 8),
          _TabButton(
            title: 'Complaints',
            isSelected: _selectedTab == 'complaints',
            onTap: () => setState(() => _selectedTab = 'complaints'),
            icon: Icons.feedback,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by student name, location, or type...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = ['all', 'pending', 'acknowledged', 'resolved'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Filter by Status',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: statuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status == 'all' ? 'All Status' : status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
          ),
          SizedBox(width: 12),
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: IconButton(
        icon: Icon(Icons.download, color: Colors.green.shade800),
        onPressed: _exportData,
      ),
    );
  }

  Widget _buildStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(_selectedTab).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        final documents = snapshot.data!.docs;
        final pending = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'pending';
        }).length;

        final acknowledged = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'acknowledged';
        }).length;

        final resolved = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'resolved';
        }).length;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _StatItem(
                count: pending,
                label: 'Pending',
                color: Colors.orange,
                icon: Icons.pending_actions,
              ),
              SizedBox(width: 8),
              _StatItem(
                count: acknowledged,
                label: 'Acknowledged',
                color: Colors.blue,
                icon: Icons.check_circle_outline,
              ),
              SizedBox(width: 8),
              _StatItem(
                count: resolved,
                label: 'Resolved',
                color: Colors.green,
                icon: Icons.verified,
              ),
              SizedBox(width: 8),
              _StatItem(
                count: documents.length,
                label: 'Total',
                color: Colors.purple,
                icon: Icons.library_books,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_selectedTab == 'incidents') {
      return _IncidentsList(
        statusFilter: _selectedStatus,
        searchQuery: _searchQuery,
      );
    } else if (_selectedTab == 'reports') {
      return _ReportsList(
        statusFilter: _selectedStatus,
        searchQuery: _searchQuery,
      );
    } else {
      return _ComplaintsList(
        statusFilter: _selectedStatus,
        searchQuery: _searchQuery,
      );
    }
  }

  void _exportData() {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export feature coming soon...')),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'acknowledged': return Colors.blue;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
    }
  }
}

// Tab Button Widget
class _TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
                SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Stat Item Widget
class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Incidents List
class _IncidentsList extends StatelessWidget {
  final String statusFilter;
  final String searchQuery;

  const _IncidentsList({
    required this.statusFilter,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('incidents')
        .orderBy('timestamp', descending: true);

    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var incidents = snapshot.data!.docs;

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          incidents = incidents.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final studentName = data['studentName']?.toString().toLowerCase() ?? '';
            final type = data['type']?.toString().toLowerCase() ?? '';
            final location = data['location']?.toString().toLowerCase() ?? '';
            final description = data['description']?.toString().toLowerCase() ?? '';

            return studentName.contains(searchQuery) ||
                type.contains(searchQuery) ||
                location.contains(searchQuery) ||
                description.contains(searchQuery);
          }).toList();
        }

        if (incidents.isEmpty) {
          return _EmptyState(
            icon: Icons.warning,
            message: 'No incidents found',
            subtitle: searchQuery.isNotEmpty
                ? 'No incidents match your search'
                : 'Student SOS incidents will appear here',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final doc = incidents[index];
            final incident = doc.data() as Map<String, dynamic>;
            return _IncidentCard(incident: incident, docId: doc.id);
          },
        );
      },
    );
  }
}

// Reports List
class _ReportsList extends StatelessWidget {
  final String statusFilter;
  final String searchQuery;

  const _ReportsList({
    required this.statusFilter,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('reports')
        .orderBy('timestamp', descending: true);

    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var reports = snapshot.data!.docs;

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          reports = reports.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final studentName = data['studentName']?.toString().toLowerCase() ?? '';
            final title = data['title']?.toString().toLowerCase() ?? '';
            final category = data['category']?.toString().toLowerCase() ?? '';
            final description = data['description']?.toString().toLowerCase() ?? '';

            return studentName.contains(searchQuery) ||
                title.contains(searchQuery) ||
                category.contains(searchQuery) ||
                description.contains(searchQuery);
          }).toList();
        }

        if (reports.isEmpty) {
          return _EmptyState(
            icon: Icons.assignment,
            message: 'No reports found',
            subtitle: searchQuery.isNotEmpty
                ? 'No reports match your search'
                : 'Student reports will appear here',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final doc = reports[index];
            final report = doc.data() as Map<String, dynamic>;
            return _ReportCard(report: report, docId: doc.id);
          },
        );
      },
    );
  }
}

// Complaints List
class _ComplaintsList extends StatelessWidget {
  final String statusFilter;
  final String searchQuery;

  const _ComplaintsList({
    required this.statusFilter,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('complaints')
        .orderBy('timestamp', descending: true);

    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var complaints = snapshot.data!.docs;

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          complaints = complaints.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final studentName = data['studentName']?.toString().toLowerCase() ?? '';
            final type = data['type']?.toString().toLowerCase() ?? '';
            final complaint = data['complaint']?.toString().toLowerCase() ?? '';
            final suggestion = data['suggestion']?.toString().toLowerCase() ?? '';

            return studentName.contains(searchQuery) ||
                type.contains(searchQuery) ||
                complaint.contains(searchQuery) ||
                suggestion.contains(searchQuery);
          }).toList();
        }

        if (complaints.isEmpty) {
          return _EmptyState(
            icon: Icons.feedback,
            message: 'No complaints found',
            subtitle: searchQuery.isNotEmpty
                ? 'No complaints match your search'
                : 'Student complaints will appear here',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final doc = complaints[index];
            final complaint = doc.data() as Map<String, dynamic>;
            return _ComplaintCard(complaint: complaint, docId: doc.id);
          },
        );
      },
    );
  }
}

// Incident Card Widget
class _IncidentCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  final String docId;

  const _IncidentCard({required this.incident, required this.docId});

  @override
  Widget build(BuildContext context) {
    final timestamp = (incident['timestamp'] as Timestamp).toDate();
    final status = incident['status'] ?? 'pending';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IncidentDetailScreen(incidentId: docId, incident: incident),
            ),
          );
        },
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
                      incident['type'] ?? 'SOS Incident',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                  _StatusChip(status: status),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Student: ${incident['studentName'] ?? 'Unknown'}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              if (incident['location'] != null) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      incident['location'],
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              if (incident['description'] != null && incident['description'].isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  incident['description'],
                  style: TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      if (incident['anonymous'] == true)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ANONYMOUS',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                          ),
                        ),
                      SizedBox(width: 8),
                      Text(
                        'View Details →',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Report Card Widget
class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final String docId;

  const _ReportCard({required this.report, required this.docId});

  @override
  Widget build(BuildContext context) {
    final timestamp = (report['timestamp'] as Timestamp).toDate();
    final status = report['status'] ?? 'pending';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailScreen(reportId: docId, report: report),
            ),
          );
        },
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  _StatusChip(status: status),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Category: ${report['category'] ?? 'General'}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Student: ${report['studentName'] ?? 'Unknown'}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              if (report['location'] != null) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      report['location'],
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              if (report['description'] != null && report['description'].isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  report['description'],
                  style: TextStyle(fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(report['priority']).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${report['priority'] ?? 'Medium'}'.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getPriorityColor(report['priority']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'View →',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }
}

// Complaint Card Widget
class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final String docId;

  const _ComplaintCard({required this.complaint, required this.docId});

  @override
  Widget build(BuildContext context) {
    final timestamp = (complaint['timestamp'] as Timestamp).toDate();
    final status = complaint['status'] ?? 'pending';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintDetailScreen(complaintId: docId, complaint: complaint),
            ),
          );
        },
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                  _StatusChip(status: status),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Student: ${complaint['studentName'] ?? 'Unknown'}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              if (complaint['complaint'] != null && complaint['complaint'].isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  complaint['complaint'],
                  style: TextStyle(fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (complaint['suggestion'] != null && complaint['suggestion'].isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Suggestion: ${complaint['suggestion']}',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    'View Details →',
                    style: TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Status Chip Widget
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

// Empty State Widget
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}