// lib/providers/sos_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';

class SosProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> _activeAlerts = [];
  List<Map<String, dynamic>> _solvedComplaints = [];
  List<Map<String, dynamic>> _myComplaints = [];
  bool _isLoading = false;
  String? _error;
  int _unreadAlerts = 0;

  List<Map<String, dynamic>> get activeAlerts => _activeAlerts;
  List<Map<String, dynamic>> get solvedComplaints => _solvedComplaints;
  List<Map<String, dynamic>> get myComplaints => _myComplaints;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadAlerts => _unreadAlerts;

  // Enhanced SOS Types
  final List<Map<String, dynamic>> sosTypes = [
    {'type': 'Harassment', 'icon': '🚨', 'priority': 'high'},
    {'type': 'Ragging', 'icon': '⚠️', 'priority': 'high'},
    {'type': 'Patient Violent', 'icon': '🥊', 'priority': 'critical'},
    {'type': 'Fighting in Parking', 'icon': '⚔️', 'priority': 'medium'},
    {'type': 'Student needs Help', 'icon': '🆘', 'priority': 'medium'},
    {'type': 'Medical Emergency', 'icon': '🏥', 'priority': 'critical'},
    {'type': 'Fire Emergency', 'icon': '🔥', 'priority': 'critical'},
    {'type': 'Theft', 'icon': '💰', 'priority': 'medium'},
    {'type': 'Infrastructure Issue', 'icon': '🏗️', 'priority': 'low'},
    {'type': 'Other Emergency', 'icon': '📢', 'priority': 'low'},
  ];

  // Enhanced Locations
  final List<String> locations = [
    'Main Parking',
    'ICU Ward',
    'Emergency Ward',
    'OPD Section',
    'Hostel Block A',
    'Hostel Block B',
    'Library',
    'Canteen',
    'Classroom Block',
    'Administration Block',
    'Nursing Station',
    'Laboratory',
    'Sports Ground',
    'Other'
  ];

  Future<void> sendSosAlert({
    required String type,
    required String location,
    String? description,
    bool anonymous = false,
    required String userId,
    required String userName,
    String? userPhoto,
    String? voiceNoteUrl,
    String? imageUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      Position position = await _getCurrentLocation();

      // Create SOS alert document
      DocumentReference docRef = await _firestore.collection('sos_alerts').add({
        'type': type,
        'location': location,
        'description': description,
        'anonymous': anonymous,
        'userId': anonymous ? null : userId,
        'userName': anonymous ? 'Anonymous' : userName,
        'userPhoto': anonymous ? null : userPhoto,
        'status': 'active',
        'priority': _getPriorityLevel(type),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'voiceNoteUrl': voiceNoteUrl,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'acknowledgedBy': [],
        'resolvedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Trigger emergency alert for security
      await _triggerEmergencyAlert();

      _isLoading = false;
      notifyListeners();

      print("✅ SOS Alert sent successfully: ${docRef.id}");
    } catch (e) {
      _error = 'Failed to send SOS: $e';
      _isLoading = false;
      notifyListeners();
      print("❌ SOS Alert failed: $e");
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied. Please allow location access in settings.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in app settings.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  String _getPriorityLevel(String type) {
    switch (type) {
      case 'Medical Emergency':
      case 'Fire Emergency':
      case 'Patient Violent':
        return 'critical';
      case 'Harassment':
      case 'Ragging':
        return 'high';
      case 'Fighting in Parking':
      case 'Student needs Help':
      case 'Theft':
        return 'medium';
      default:
        return 'low';
    }
  }

  Future<void> _triggerEmergencyAlert() async {
    // Enhanced vibration pattern for emergency
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [1000, 500, 1000, 500, 1000]);
    }

    // Play emergency sound
    try {
      await _audioPlayer.play(UrlSource('assets/sounds/emergency_alert.mp3'));
    } catch (e) {
      print('Could not play emergency sound: $e');
    }
  }

  // Real-time listener for active alerts (Security)
  void listenToActiveAlerts() {
    _firestore
        .collection('sos_alerts')
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _activeAlerts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Update unread count and trigger vibration for new alerts
      if (_activeAlerts.isNotEmpty) {
        _unreadAlerts = _activeAlerts.length;
        _triggerNewAlertVibration();
      }

      notifyListeners();
    }, onError: (error) {
      _error = 'Failed to load active alerts: $error';
      notifyListeners();
    });
  }

  void _triggerNewAlertVibration() {
    // Short vibration for new alerts
    Vibration.vibrate(duration: 500);
  }

  // For students to see their complaints
  void listenToMyComplaints(String userId) {
    _firestore
        .collection('sos_alerts')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _myComplaints = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      notifyListeners();
    });
  }

  // For admin to see solved complaints
  void listenToSolvedComplaints() {
    _firestore
        .collection('sos_alerts')
        .where('status', isEqualTo: 'resolved')
        .orderBy('resolvedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _solvedComplaints = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      notifyListeners();
    });
  }

  Future<void> acknowledgeAlert(String alertId, String securityName, String securityId) async {
    try {
      await _firestore.collection('sos_alerts').doc(alertId).update({
        'acknowledgedBy': FieldValue.arrayUnion([securityName]),
        'acknowledgedByIds': FieldValue.arrayUnion([securityId]),
        'acknowledgedAt': FieldValue.serverTimestamp(),
        'status': 'acknowledged',
      });
    } catch (e) {
      _error = 'Failed to acknowledge alert: $e';
      notifyListeners();
    }
  }

  Future<void> resolveAlert(String alertId, String resolvedBy, String resolutionNotes) async {
    try {
      await _firestore.collection('sos_alerts').doc(alertId).update({
        'status': 'resolved',
        'resolvedBy': resolvedBy,
        'resolutionNotes': resolutionNotes,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = 'Failed to resolve alert: $e';
      notifyListeners();
    }
  }

  // Get analytics data for superadmin
  Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Get monthly stats
      final monthlyQuery = await _firestore
          .collection('sos_alerts')
          .where('timestamp', isGreaterThan: startOfMonth)
          .get();

      final totalAlerts = monthlyQuery.docs.length;
      final resolvedAlerts = monthlyQuery.docs.where((doc) => doc['status'] == 'resolved').length;
      final activeAlerts = monthlyQuery.docs.where((doc) => doc['status'] == 'active').length;

      // Get alerts by type
      Map<String, int> alertsByType = {};
      for (var doc in monthlyQuery.docs) {
        final type = doc['type'];
        alertsByType[type] = (alertsByType[type] ?? 0) + 1;
      }

      // Get alerts by location
      Map<String, int> alertsByLocation = {};
      for (var doc in monthlyQuery.docs) {
        final location = doc['location'];
        alertsByLocation[location] = (alertsByLocation[location] ?? 0) + 1;
      }

      return {
        'totalAlerts': totalAlerts,
        'resolvedAlerts': resolvedAlerts,
        'activeAlerts': activeAlerts,
        'resolutionRate': totalAlerts > 0 ? (resolvedAlerts / totalAlerts) * 100 : 0,
        'alertsByType': alertsByType,
        'alertsByLocation': alertsByLocation,
        'averageResponseTime': await _calculateAverageResponseTime(),
      };
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  Future<double> _calculateAverageResponseTime() async {
    // Implementation for calculating average response time
    return 5.2; // Placeholder
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void markAlertsAsRead() {
    _unreadAlerts = 0;
    notifyListeners();
  }
}