import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/side_menu.dart';
import '../models/user_role.dart';
import '../security/emergency_alert_screen.dart';
import '../services/notification_service.dart';
import '../main.dart';

class SecurityDashboard extends StatefulWidget {
  final String username;
  final UserRole role;

  const SecurityDashboard({super.key, required this.username, required this.role});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _shownAlertIds = [];
  final List<OverlayEntry> _activeOverlays = [];

  Color statusColor(String status) {
    switch (status) {
      case 'sent':
        return Colors.orange.shade300;
      case 'acknowledged':
      case 'resolved':
        return Colors.green.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize notifications
    NotificationService().init(widget.username);

    // Listen for new incidents in real-time
    _firestore
        .collection('incidents')
        .where('status', isEqualTo: 'sent')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!_shownAlertIds.contains(doc.id)) {
          _shownAlertIds.add(doc.id);
          _showOverlay(data, doc.id);
        }
      }
    });
  }

  /// Overlay popup for new incidents
  void _showOverlay(Map<String, dynamic> data, String incidentId) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final topOffset = 50 + (_activeOverlays.length * 130.0);
        return Positioned(
          top: topOffset,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EmergencyAlertScreen(incidentId: incidentId)));
                overlayEntry.remove();
                _activeOverlays.remove(overlayEntry);
              },
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("⚠️ ${data['type'] ?? 'SOS'} Alert",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("Student: ${data['studentName'] ?? 'Anonymous'}"),
                    Text("Location: ${data['location'] ?? 'Unknown'}"),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () {
                            _firestore
                                .collection('incidents')
                                .doc(incidentId)
                                .update({'status': 'acknowledged'});
                            overlayEntry.remove();
                            _activeOverlays.remove(overlayEntry);
                          },
                          child: const Text("Acknowledge"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            _firestore
                                .collection('incidents')
                                .doc(incidentId)
                                .update({'status': 'resolved'});
                            overlayEntry.remove();
                            _activeOverlays.remove(overlayEntry);
                          },
                          child: const Text("Resolve"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(MyApp.navigatorKey.currentContext!)?.insert(overlayEntry);
    _activeOverlays.add(overlayEntry);

    // Auto remove after 10s
    Future.delayed(const Duration(seconds: 10), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
        _activeOverlays.remove(overlayEntry);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Dashboard"),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: SideMenu(role: widget.role, username: widget.username),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('incidents')
            .where('status', isEqualTo: 'sent')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final incidents = snapshot.data!.docs;
          if (incidents.isEmpty) return const Center(child: Text("No pending incidents"));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final doc = incidents[index];
              final data = doc.data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => _showOverlay(data, doc.id),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: statusColor(data['status'] ?? 'sent'),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("⚠️ ${data['type'] ?? 'SOS'}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text("Student: ${data['studentName'] ?? 'Anonymous'}"),
                        Text("Location: ${data['location'] ?? 'Unknown'}"),
                        Text("Desc: ${data['description'] ?? 'None'}"),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () {
                                _firestore
                                    .collection('incidents')
                                    .doc(doc.id)
                                    .update({'status': 'acknowledged'});
                              },
                              child: const Text("Ack"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () {
                                _firestore
                                    .collection('incidents')
                                    .doc(doc.id)
                                    .update({'status': 'resolved'});
                              },
                              child: const Text("Res"),
                            ),
                          ],
                        )
                      ],
                    ),
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
