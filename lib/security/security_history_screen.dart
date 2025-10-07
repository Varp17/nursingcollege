// security/security_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SecurityHistoryScreen extends StatefulWidget {
  const SecurityHistoryScreen({super.key});

  @override
  State<SecurityHistoryScreen> createState() => _SecurityHistoryScreenState();
}

class _SecurityHistoryScreenState extends State<SecurityHistoryScreen> {
  String _selectedFilter = 'all'; // all, pending, acknowledged, resolved
  String _selectedTimeFilter = 'all'; // all, today, week, month
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter options
  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'All Incidents'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'acknowledged', 'label': 'Acknowledged'},
    {'value': 'resolved', 'label': 'Resolved'},
  ];

  final List<Map<String, String>> _timeFilters = [
    {'value': 'all', 'label': 'All Time'},
    {'value': 'today', 'label': 'Today'},
    {'value': 'week', 'label': 'This Week'},
    {'value': 'month', 'label': 'This Month'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Incident History'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _buildFilterSection(),

          // Statistics Cards
          _buildStatisticsCards(),

          // Incidents List
          Expanded(
            child: _buildIncidentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search incidents...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            SizedBox(height: 12),

            // Filter Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: _statusFilters.map((filter) {
                      return DropdownMenuItem(
                        value: filter['value'],
                        child: Text(filter['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTimeFilter,
                    decoration: InputDecoration(
                      labelText: 'Time Period',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: _timeFilters.map((filter) {
                      return DropdownMenuItem(
                        value: filter['value'],
                        child: Text(filter['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }

        final incidents = snapshot.data!.docs;
        final filteredIncidents = _applyFilters(incidents);

        final today = DateTime.now();
        final todayIncidents = incidents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'] as Timestamp;
          return _isSameDay(timestamp.toDate(), today);
        }).length;

        final pendingCount = incidents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'pending';
        }).length;

        final resolvedCount = incidents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'resolved';
        }).length;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          height: 100,
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total',
                  value: filteredIncidents.length.toString(),
                  color: Colors.blue,
                  icon: Icons.list_alt,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: "Today's",
                  value: todayIncidents.toString(),
                  color: Colors.green,
                  icon: Icons.today,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'Pending',
                  value: pendingCount.toString(),
                  color: Colors.orange,
                  icon: Icons.pending,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'Resolved',
                  value: resolvedCount.toString(),
                  color: Colors.purple,
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncidentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final incidents = snapshot.data!.docs;
        final filteredIncidents = _applyFilters(incidents);

        if (filteredIncidents.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredIncidents.length,
          itemBuilder: (context, index) {
            final doc = filteredIncidents[index];
            final incident = doc.data() as Map<String, dynamic>;
            final incidentId = doc.id;

            return _IncidentCard(
              incident: incident,
              incidentId: incidentId,
              onTap: () => _showIncidentDetails(incident, incidentId),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'No incidents found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showIncidentDetails(Map<String, dynamic> incident, String incidentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _IncidentDetailsSheet(
          incident: incident,
          incidentId: incidentId,
          onStatusUpdate: () => setState(() {}),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> incidents) {
    List<QueryDocumentSnapshot> filtered = incidents;

    // Status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == _selectedFilter;
      }).toList();
    }

    // Time filter
    final now = DateTime.now();
    if (_selectedTimeFilter != 'all') {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] as Timestamp;
        final incidentDate = timestamp.toDate();

        switch (_selectedTimeFilter) {
          case 'today':
            return _isSameDay(incidentDate, now);
          case 'week':
            return incidentDate.isAfter(now.subtract(Duration(days: 7)));
          case 'month':
            return incidentDate.isAfter(now.subtract(Duration(days: 30)));
          default:
            return true;
        }
      }).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final studentName = (data['studentName'] ?? '').toString().toLowerCase();
        final location = (data['location'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();
        final type = (data['type'] ?? '').toString().toLowerCase();

        return studentName.contains(_searchQuery) ||
            location.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            type.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// Incident Card Widget
class _IncidentCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  final String incidentId;
  final VoidCallback onTap;

  const _IncidentCard({
    required this.incident,
    required this.incidentId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = (incident['timestamp'] as Timestamp).toDate();
    final status = incident['status'] ?? 'pending';
    final isAnonymous = incident['anonymous'] == true;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusChip(status: status),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(timestamp),
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Student and Location
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.blue),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isAnonymous ? 'Anonymous Student' : incident['studentName'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(incident['location'] ?? 'Unknown Location'),
                  ),
                ],
              ),
              SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(incident['type'] ?? 'SOS'),
                  ),
                ],
              ),

              // Description if available
              if (incident['description'] != null && incident['description'].toString().isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  incident['description'],
                  style: TextStyle(color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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

// Statistics Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Incident Details Bottom Sheet
class _IncidentDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> incident;
  final String incidentId;
  final VoidCallback onStatusUpdate;

  const _IncidentDetailsSheet({
    required this.incident,
    required this.incidentId,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = (incident['timestamp'] as Timestamp).toDate();
    final isAnonymous = incident['anonymous'] == true;

    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),

          Text(
            'Incident Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          // Incident Information
          _DetailRow(icon: Icons.person, label: 'Student', value: isAnonymous ? 'Anonymous' : incident['studentName']),
          _DetailRow(icon: Icons.location_on, label: 'Location', value: incident['location']),
          _DetailRow(icon: Icons.warning, label: 'Type', value: incident['type']),
          _DetailRow(icon: Icons.access_time, label: 'Time', value: DateFormat('MMM dd, yyyy - HH:mm').format(timestamp)),

          if (incident['description'] != null && incident['description'].toString().isNotEmpty) ...[
            SizedBox(height: 12),
            Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(incident['description']),
          ],

          SizedBox(height: 20),

          // Status Update Buttons
          if (incident['status'] != 'resolved') ...[
            Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                if (incident['status'] == 'pending')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('acknowledged', context),
                      icon: Icon(Icons.check),
                      label: Text('Acknowledge'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ),
                if (incident['status'] == 'pending') SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus('resolved', context),
                    icon: Icon(Icons.verified),
                    label: Text('Resolve'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String newStatus, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(incidentId)
          .update({
        'status': newStatus,
        '${newStatus}At': FieldValue.serverTimestamp(),
      });

      onStatusUpdate();
      Navigator.pop(context);

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

// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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