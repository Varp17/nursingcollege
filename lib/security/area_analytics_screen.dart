// security/area_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AreaAnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Area Analytics'),
        backgroundColor: Colors.green.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('incidents').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final incidents = snapshot.data!.docs;
          final locationStats = _calculateLocationStats(incidents);

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📍 Location-wise Incidents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      ...locationStats.entries.map((entry) =>
                          _LocationStatItem(location: entry.key, count: entry.value)
                      ).toList(),
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

  Map<String, int> _calculateLocationStats(List<QueryDocumentSnapshot> incidents) {
    Map<String, int> stats = {};
    for (var incident in incidents) {
      final data = incident.data() as Map<String, dynamic>;
      final location = data['location'] ?? 'Unknown';
      stats[location] = (stats[location] ?? 0) + 1;
    }
    return stats;
  }
}

class _LocationStatItem extends StatelessWidget {
  final String location;
  final int count;

  const _LocationStatItem({required this.location, required this.count});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.location_on, color: Colors.blue),
      title: Text(location),
      trailing: Chip(label: Text('$count')),
    );
  }
}