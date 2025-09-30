// lib/security/pending_sos_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';

class PendingSOSScreen extends StatefulWidget {
  const PendingSOSScreen({super.key});

  @override
  State<PendingSOSScreen> createState() => _PendingSOSScreenState();
}

class _PendingSOSScreenState extends State<PendingSOSScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _shownAlertIds = [];
  OverlayEntry? _overlayEntry;
  bool _isShowingOverlay = false;

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
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Listen to SOS alerts in real-time
    _firestore
        .collection('sos_alerts')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var alert in snapshot.docs) {
        if (!_shownAlertIds.contains(alert.id)) {
          _shownAlertIds.add(alert.id);
          _showSlidingPopup(alert);
        }
      }
    });
  }

  void _showSlidingPopup(QueryDocumentSnapshot alert) {
    if (_isShowingOverlay) return;

    final data = alert.data() as Map<String, dynamic>;
    final description = data['description'] ?? "No description";
    final location = data['location'] ?? "Unknown";

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        right: 16,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(12),
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
                  const Text(
                    "⚠️ SOS Alert",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text("Location: $location"),
                  const SizedBox(height: 2),
                  Text("Description: $description"),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _firestore
                          .collection('sos_alerts')
                          .doc(alert.id)
                          .update({'status': 'resolved'});
                      _removeOverlay();
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

    Overlay.of(context)?.insert(_overlayEntry!);
    _isShowingOverlay = true;

    // Vibrate device
    Vibration.vibrate(duration: 500);

    _animationController.forward();

    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _animationController.reverse().then((_) => _removeOverlay());
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowingOverlay = false;
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
        title: const Text("Pending SOS Alerts"),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('sos_alerts')
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final alerts = snapshot.data!.docs;

          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                "No pending SOS alerts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final data = alerts[index];
              final alertData = data.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    alertData['type'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Location: ${alertData['location'] ?? 'Unknown'}\nDescription: ${alertData['description'] ?? 'None'}",
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      _firestore
                          .collection('sos_alerts')
                          .doc(data.id)
                          .update({'status': 'resolved'});
                    },
                    child: const Text('Resolve'),
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
