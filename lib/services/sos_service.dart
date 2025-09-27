import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/incident_model.dart';

class SosService {
  static Future<String?> uploadVoice(String path) async {
    final file = File(path);
    final fileName = 'sos_${DateTime.now().millisecondsSinceEpoch}.aac';
    final ref = FirebaseStorage.instance.ref().child('sos_audios/$fileName');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  static Future<void> sendIncident(Incident incident) async {
    await FirebaseFirestore.instance
        .collection('incidents')
        .add(incident.toMap());
  }
}
