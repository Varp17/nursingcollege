import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/side_menu.dart';

class SecurityDashboard extends StatefulWidget {
  final String username;
  final UserRole role;

  const SecurityDashboard({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  final Set<String> _shownAlerts = {}; // Track shown incidents

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Dashboard"),
      ),
      drawer: SideMenu(role: widget.role, username: widget.username),
      body: Stack(
        children: [
          // Real-time incident list
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('incidents')
                .where('status', whereIn: ['sent', 'acknowledged'])
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final incidents = snapshot.data!.docs;

              // Show alerts in real-time
              for (var doc in incidents) {
                final id = doc.id;
                final data = doc.data()! as Map<String, dynamic>;
                if (!_shownAlerts.contains(id) && data['status'] == 'sent') {
                  _shownAlerts.add(id);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showEmergencyAlert(context, data, id);
                  });
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: incidents.length,
                itemBuilder: (context, index) {
                  final data = incidents[index].data()! as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(data['type'] ?? 'Unknown'),
                      subtitle: Text(
                          'Location: ${data['location'] ?? 'Unknown'}\nIssue: ${data['issue'] ?? 'Unknown'}'),
                      trailing: Text(data['status']),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEmergencyAlert(
      BuildContext context, Map<String, dynamic> incident, String id) {
    final isGirls = incident['discreet'] ?? false;
    final bgColor = isGirls ? Colors.pink.shade700 : Colors.red.shade700;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: bgColor,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    isGirls ? "Girls SOS Alert!" : "Standard SOS Alert!",
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Location: ${incident['location'] ?? 'Unknown'}\nIssue: ${incident['issue'] ?? 'Unknown'}",
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('incidents')
                          .doc(id)
                          .update({'status': 'acknowledged'});
                      _shownAlerts.remove(id);
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text("Acknowledge", style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    HapticFeedback.vibrate();
  }
}
