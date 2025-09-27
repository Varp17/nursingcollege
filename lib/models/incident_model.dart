import 'package:cloud_firestore/cloud_firestore.dart';

class Incident {
  final String studentUid;
  final String type;
  final String? location;
  final String? otherLocation;
  final String? issue;
  final String? description;
  final String? voiceUrl;
  final bool discreet;
  final bool autoSentOnTimeout;
  final Timestamp createdAt;

  Incident({
    required this.studentUid,
    required this.type,
    this.location,
    this.otherLocation,
    this.issue,
    this.description,
    this.voiceUrl,
    required this.discreet,
    required this.autoSentOnTimeout,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'type': type,
      'location': location,
      'otherLocation': otherLocation,
      'issue': issue,
      'description': description,
      'voiceUrl': voiceUrl,
      'discreet': discreet,
      'autoSentOnTimeout': autoSentOnTimeout,
      'createdAt': createdAt,
      'status': 'sent',
    };
  }
}
