import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<User?> register({
    required String email,
    required String password,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;
    String? token = await FirebaseMessaging.instance.getToken();

    await _db.collection('users').doc(uid).set({
      'email': email,
      'role': role,
      'approved': role == "student" ? true : false, // students auto-approved
      'createdAt': FieldValue.serverTimestamp(),
      'fcmToken': token,
    });

    return cred.user;
  }

  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update FCM token on login
    String? token = await FirebaseMessaging.instance.getToken();
    await _db.collection('users').doc(cred.user!.uid).update({
      'fcmToken': token,
    });

    return cred.user;
  }

  Future<String?> getUserRole(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data()?['role'];
  }

  Future<bool> isApproved(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data()?['approved'] ?? false;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
