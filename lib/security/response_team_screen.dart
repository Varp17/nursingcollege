// lib/security/response_team_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResponseTeamScreen extends StatefulWidget {
  @override
  State<ResponseTeamScreen> createState() => _ResponseTeamScreenState();
}

class _ResponseTeamScreenState extends State<ResponseTeamScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Response Team'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Team Statistics
          _buildTeamStats(),

          // Team Members List
          Expanded(
            child: _buildTeamList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('security_status').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Team data unavailable')),
            ),
          );
        }

        final teamMembers = snapshot.data!.docs;
        final availableCount = teamMembers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Available';
        }).length;

        final busyCount = teamMembers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Busy';
        }).length;

        final onWayCount = teamMembers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'On My Way';
        }).length;

        return Card(
          margin: EdgeInsets.all(16),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '👥 Security Team Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TeamStat(
                      count: availableCount.toString(),
                      label: 'Available',
                      color: Colors.green,
                    ),
                    _TeamStat(
                      count: onWayCount.toString(),
                      label: 'On Way',
                      color: Colors.blue,
                    ),
                    _TeamStat(
                      count: busyCount.toString(),
                      label: 'Busy',
                      color: Colors.orange,
                    ),
                    _TeamStat(
                      count: teamMembers.length.toString(),
                      label: 'Total',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('security_status')
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final teamMembers = snapshot.data!.docs;

        if (teamMembers.isEmpty) {
          return Center(
            child: Text('No security team members found'),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: teamMembers.length,
          itemBuilder: (context, index) {
            final member = teamMembers[index];
            final memberData = member.data() as Map<String, dynamic>;

            return _TeamMemberCard(
              memberData: memberData,
              memberId: member.id,
            );
          },
        );
      },
    );
  }
}

class _TeamStat extends StatelessWidget {
  final String count;
  final String label;
  final Color color;

  const _TeamStat({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final Map<String, dynamic> memberData;
  final String memberId;

  const _TeamMemberCard({
    required this.memberData,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    final status = memberData['status'] ?? 'Unknown';
    final name = memberData['name'] ?? 'Security Officer';
    final updatedAt = memberData['updatedAt'] as Timestamp?;
    final timeAgo = updatedAt != null ? _getTimeAgo(updatedAt.toDate()) : 'Unknown';
    final currentLocation = memberData['currentLocation'] ?? 'Location unavailable';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.2),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status'),
            Text('Location: $currentLocation', style: TextStyle(fontSize: 12)),
            Text('Updated: $timeAgo', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (status == 'On My Way') ...[
              SizedBox(height: 4),
              Icon(Icons.directions_run, size: 16, color: Colors.blue),
            ],
          ],
        ),
        onTap: () {
          _showTeamMemberDetails(context, memberData);
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available': return Colors.green;
      case 'On My Way': return Colors.blue;
      case 'Busy': return Colors.orange;
      case 'Off Duty': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Available': return Icons.check_circle;
      case 'On My Way': return Icons.directions_run;
      case 'Busy': return Icons.do_not_disturb;
      case 'Off Duty': return Icons.offline_bolt;
      default: return Icons.person;
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  void _showTeamMemberDetails(BuildContext context, Map<String, dynamic> memberData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Team Member Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${memberData['name'] ?? 'Unknown'}'),
            Text('Status: ${memberData['status'] ?? 'Unknown'}'),
            Text('Location: ${memberData['currentLocation'] ?? 'Not available'}'),
            Text('Last Update: ${_getTimeAgo((memberData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}