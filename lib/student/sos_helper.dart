// lib/student/sos_helper.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class SosHelper {
  final FirestoreService _fs = FirestoreService();

  Future<String> sendSos({
    required User reporter,
    String? reporterName,
    String? reporterPhone,
    required String type,
    required String locationName,
    Map<String,dynamic>? locationCoords,
    File? voiceNoteFile,
    bool anonymous=false,
    bool safeWalk=false,
  }) async {
    final alertData = {
      'type': type,
      'reporter_id': anonymous ? null : reporter.uid,
      'reporter_name': anonymous ? null : reporterName,
      'reporter_phone': anonymous ? null : reporterPhone,
      'location_name': locationName,
      'location_coords': locationCoords,
      'floor': (locationCoords != null && locationCoords['floor'] != null) ? locationCoords['floor'] : null,
      'status': 'pending',
      'confidence': 'high',
      'safe_walk': {'enabled': safeWalk},
    };

    final alertId = await _fs.createAlert(alertData);

    if (voiceNoteFile != null) {
      final url = await _fs.uploadVoiceNote(alertId, voiceNoteFile);
      // update stored voice url already inside upload
    }

    // You should call cloud function (or client side) to send FCM. Cloud function recommended.
    return alertId;
  }
}
