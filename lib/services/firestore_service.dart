// lib/services/firestore_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_role.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create alert (SOS)
  Future<String> createAlert(Map<String, dynamic> alertData) async {
    final docRef = _db.collection('incidents').doc(); // changed from 'alerts'
    alertData['status'] = alertData['status'] ?? 'sent'; // default "sent"
    alertData['timestamp'] = FieldValue.serverTimestamp();
    await docRef.set(alertData);
    return docRef.id;
  }

  // Update alert
  Future<void> updateAlert(String alertId, Map<String, dynamic> update) async {
    update['last_update'] = FieldValue.serverTimestamp();
    await _db.collection('incidents').doc(alertId).update(update);
  }

  // Assign guard
  Future<void> assignGuard(String alertId, String guardId) async {
    await updateAlert(alertId, {
      'assigned_guard_id': guardId,
      'status': 'accepted',
      'last_update': FieldValue.serverTimestamp()
    });
  }

  // Upload voice note
  Future<String> uploadVoiceNote(String alertId, File file) async {
    final ref = _storage
        .ref()
        .child('voice_notes/$alertId/${DateTime.now().millisecondsSinceEpoch}.aac');
    final uploadTask = await ref.putFile(file);
    final url = await uploadTask.ref.getDownloadURL();
    await _db.collection('incidents').doc(alertId).update({'voice_note_url': url});
    return url;
  }

  // Stream alerts for a section
  Stream<QuerySnapshot> streamAlertsForSection(String section) {
    return _db
        .collection('incidents')
        .where('location_name', isEqualTo: section)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Save FCM token
  Future<void> saveFcmToken(String uid, String token) async {
    await _db.collection('fcm_tokens').doc(uid).set({
      'token': token,
      'updated_at': FieldValue.serverTimestamp()
    });
  }

  // Get tokens for a section (for guard devices)
  Future<List<String>> getTokensForSection(String section) async {
    final guards = await _db
        .collection('users')
        .where('role', isEqualTo: 'security')
        .where('sections', arrayContains: section)
        .get();
    List<String> tokens = [];
    for (final g in guards.docs) {
      final tdoc = await _db.collection('fcm_tokens').doc(g.id).get();
      if (tdoc.exists && tdoc.data()?['token'] != null) tokens.add(tdoc.data()!['token']);
    }
    return tokens;
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'];
  }

  // Get full user details
  Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // Map Firestore string role to UserRole enum
  UserRole mapRoleFromString(String? role) {
    switch (role) {
      case 'student':
        return UserRole.student;
      case 'security':
        return UserRole.security;
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
        return UserRole.superadmin;
      default:
        return UserRole.student; // fallback default
    }
  }

  // Create/Update user profile
  Future<void> createOrUpdateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }
}