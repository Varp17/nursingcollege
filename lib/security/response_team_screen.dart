// security/response_team_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResponseTeamScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Response Team'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['security', 'admin'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final teamMembers = snapshot.data!.docs;

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('👥 Security Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      ...teamMembers.map((doc) {
                        final user = doc.data() as Map<String, dynamic>;
                        return _TeamMemberItem(user: user);
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeamMemberItem extends StatelessWidget {
  final Map<String, dynamic> user;

  const _TeamMemberItem({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text(user['name'] ?? 'Unknown'),
      subtitle: Text(user['role'] ?? 'Security'),
      trailing: Chip(
        label: Text('Active', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }
}