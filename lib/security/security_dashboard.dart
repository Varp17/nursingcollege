import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../common/side_menu.dart';
import '../models/user_role.dart';

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

class _SecurityDashboardState extends State<SecurityDashboard>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _shownAlertIds = [];
  final List<OverlayEntry> _activeOverlays = [];

  late final AnimationController _animationController;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Listen to Firestore SOS alerts
    _firestore
        .collection('sos_alerts')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(_handleNewAlerts);

    // Listen to FCM foreground messages
    FirebaseMessaging.onMessage.listen((msg) {
      final data = msg.data;
      if (data['type'] == 'sos_alert') {
        _handleFCMAlert(data);
      }
    });
  }

  void _handleNewAlerts(QuerySnapshot snapshot) {
    for (var doc in snapshot.docs) {
      if (!_shownAlertIds.contains(doc.id)) {
        _shownAlertIds.add(doc.id);
        _showSlidingPopup(doc);
      }
    }
  }

  void _handleFCMAlert(Map<String, dynamic> data) {
    final fakeDoc = {
      'id': data['alertId'],
      'location': data['location'] ?? 'Unknown',
      'description': data['description'] ?? 'No description',
    };
    if (!_shownAlertIds.contains(data['alertId'])) {
      _shownAlertIds.add(data['alertId']);
      _showSlidingPopupFromData(fakeDoc);
    }
  }

  void _showSlidingPopupFromData(Map<String, dynamic> data) {
    final overlayEntry = _createOverlay(
      data['id'],
      data['location'],
      data['description'],
    );
    Overlay.of(context)?.insert(overlayEntry);
    _activeOverlays.add(overlayEntry);
  }

  void _showSlidingPopup(QueryDocumentSnapshot alert) {
    final data = alert.data() as Map<String, dynamic>;
    final overlayEntry = _createOverlay(
      alert.id,
      data['location'] ?? 'Unknown',
      data['description'] ?? 'No description',
    );
    Overlay.of(context)?.insert(overlayEntry);
    _activeOverlays.add(overlayEntry);

    // Vibrate device
    Vibration.vibrate(duration: 500);
  }

  OverlayEntry _createOverlay(String id, String location, String description) {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: 50 + (_activeOverlays.length * 100),
        right: 16,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(12),
              width: 280,
              decoration: BoxDecoration(
                color: Colors.redAccent.shade100,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("⚠️ SOS Alert",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("Location: $location"),
                  const SizedBox(height: 2),
                  Text("Description: $description"),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _firestore
                          .collection('sos_alerts')
                          .doc(id)
                          .update({'status': 'resolved'});
                      _removeOverlay(id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 36),
                    ),
                    child: const Text("Resolve"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _removeOverlay(String id) {
    if (_activeOverlays.isNotEmpty) {
      _activeOverlays.first.remove();
      _activeOverlays.removeAt(0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
            .collection("complaints")
            .where("status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var complaints = snapshot.data!.docs;

          if (complaints.isEmpty) {
            return const Center(
              child: Text(
                "No pending complaints",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              var data = complaints[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  title: Text(
                    data["type"] ?? "Unknown",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    "Status: ${data["status"]}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _firestore
                          .collection("complaints")
                          .doc(data.id)
                          .update({"status": "resolved"});
                    },
                    child: const Text("Resolve"),
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
