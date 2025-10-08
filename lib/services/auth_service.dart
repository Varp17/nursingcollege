// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  // Register new user
  Future<User?> register(String email, String password, String name, String role) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'approved': role == 'security' ? true : false, // Auto-approve security
        'createdAt': FieldValue.serverTimestamp(),
        'college': '',
        'section': '',
        'phone': '',
      });

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  // Get user role
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc['role'] ?? 'student';
      }
      return 'student';
    } catch (e) {
      return 'student';
    }
  }

  // Check if user is approved
  Future<bool> isApproved(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final role = doc['role'] ?? 'student';
        // Auto-approve security and admin roles
        if (role == 'security' || role == 'admin' || role == 'superadmin') {
          return true;
        }
        return doc['approved'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    }
    return null;
  }

  // Check if profile is complete
  Future<bool> isProfileComplete(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['age'] != null &&
            data['age'].toString().isNotEmpty &&
            data['college'] != null &&
            data['college'].toString().isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}