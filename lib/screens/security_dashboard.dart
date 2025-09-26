import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});
  @override
  State<SecurityDashboardScreen> createState() => _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // optional: subscribe to a 'security' topic to receive FCM messages
    FirebaseMessaging.instance.subscribeToTopic('security');
    FirebaseMessaging.onMessage.listen((message) {
      // Vibrate on receiving foreground FCM notification
      Vibration.vibrate(duration: 600);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance.collection('incidents')
        .where('status', isEqualTo: 'sent')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Security - Incident Queue')),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No active incidents'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;
              // vibrate when new doc appears (careful: this will vibrate on each rebuild)
              Vibration.vibrate(duration: 400);
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${data['type'] ?? 'SOS'} • ${data['section'] ?? ''}'),
                  subtitle: Text('Time: ${data['createdAt'] ?? ''}\nAnonymous: ${data['anonymous'] ?? false}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(onPressed: () async {
                        await d.reference.update({'status': 'accepted', 'acceptedAt': FieldValue.serverTimestamp(), 'guardId': 'guard_demo'});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accepted')));
                      }, child: const Text('Accept')),
                      TextButton(onPressed: () async {
                        await d.reference.update({'status': 'declined'});
                      }, child: const Text('Decline')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
