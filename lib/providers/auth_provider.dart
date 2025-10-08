// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _userRole;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userUid = prefs.getString('user_uid');
    String? userRole = prefs.getString('user_role');

    if (userUid != null) {
      _user = _auth.currentUser;
      _userRole = userRole;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _error = 'Sign in cancelled';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      await _checkAndCreateUserRecord();
      await _saveUserData();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Sign in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _checkAndCreateUserRecord() async {
    if (_user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(_user!.uid)
            .get();

        if (userDoc.exists) {
          _userRole = userDoc.get('role');
        } else {
          // Default role for new users
          _userRole = 'student';
          await _firestore.collection('users').doc(_user!.uid).set({
            'uid': _user!.uid,
            'email': _user!.email,
            'name': _user!.displayName,
            'role': _userRole,
            'phone': _user!.phoneNumber,
            'photoUrl': _user!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        _userRole = 'student';
      }
    }
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', _user!.uid);
    await prefs.setString('user_role', _userRole ?? 'student');
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _user = null;
      _userRole = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Sign out failed: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}