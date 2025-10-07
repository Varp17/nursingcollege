import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';

class EmergencyModal {
  static final List<OverlayEntry> _activeOverlays = [];

  /// Show a new SOS alert overlay
  static void show(BuildContext? context, Map<String, dynamic> data, String incidentId) {
    if (context == null) return;

    Vibration.vibrate(duration: 600);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (ctx) {
        final topOffset = 50.0 + (_activeOverlays.length * 130.0);

        return Positioned(
          top: topOffset,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                overlayEntry.remove();
                _activeOverlays.remove(overlayEntry);
              },
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                offset: Offset(0, 0),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.shade100,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("🚨 ${data['type'] ?? 'SOS'} Alert",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Student: ${data['studentName'] ?? 'Anonymous'}"),
                      Text("Location: ${data['location'] ?? 'Unknown'}"),
                      if (data['description'] != null) Text("Desc: ${data['description']}"),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () {
                              FirebaseFirestore.instance
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
                              FirebaseFirestore.instance
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
          ),
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
    _activeOverlays.add(overlayEntry);

    // Auto-remove overlay after 8s
    Future.delayed(const Duration(seconds: 8), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
        _activeOverlays.remove(overlayEntry);
      }
    });
  }
}
