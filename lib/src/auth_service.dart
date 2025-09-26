import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'student' | 'security' | 'admin'
    String? fcmToken,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'approved': role == 'student',
      'fcmToken': fcmToken ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> ensureSuperadminDocument(String email) async {
    final q = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (q.docs.isEmpty) {
      await _db.collection('users').add({
        'email': email,
        'role': 'superadmin',
        'approved': true,
        'fullName': 'Super Admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final doc = q.docs.first;
      await doc.reference.update({'role': 'superadmin', 'approved': true});
    }
  }

  Future<void> updateFcmTokenForUid(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }
}
