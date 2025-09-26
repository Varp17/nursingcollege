// lib/src/app_state.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppState extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? role;
  bool approved = false;

  Future<void> loadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snap = await _db.collection("users").doc(user.uid).get();
    if (!snap.exists) return;

    final data = snap.data()!;
    role = data["role"];
    approved = data["approved"] ?? false;
    notifyListeners();
  }

  void clear() {
    role = null;
    approved = false;
    notifyListeners();
  }
}
