import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class SecurityAlertsScreen extends StatefulWidget {
  @override
  _SecurityAlertsScreenState createState() => _SecurityAlertsScreenState();
}

class _SecurityAlertsScreenState extends State<SecurityAlertsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestPermissions();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    await Permission.location.request();
  }

  Future<void> _sendAlert(String alertType, String message) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Store alert in Firestore
      await _firestore.collection('security_alerts').add({
        'userId': user.uid,
        'userEmail': user.email,
        'alertType': alertType,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'location': null, // You can add location services here
        'status': 'active',
      });

      // Show local notification
      await _showNotification(alertType, message);

      // Vibrate device
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 1000);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$alertType alert sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'security_alerts_channel',
      'Security Alerts',
      channelDescription: 'Notifications for security alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      0,
      title,
      body,
      details,
    );
  }

  Widget _buildAlertButton(String alertType, String message, Color color, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          icon: Icon(icon, size: 24),
          label: Text(
            alertType,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          onPressed: _isLoading ? null : () => _sendAlert(alertType, message),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Alerts'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              // Navigate to alert history
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlertHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Emergency Alerts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Tap any button to send an immediate alert to security personnel',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),

            // Emergency Buttons Grid
            Expanded(
              child: Column(
                children: [
                  // First Row
                  Row(
                    children: [
                      _buildAlertButton(
                        'MEDICAL\nEMERGENCY',
                        'Medical emergency assistance required',
                        Colors.red,
                        Icons.medical_services,
                      ),
                      _buildAlertButton(
                        'FIRE\nALARM',
                        'Fire emergency reported',
                        Colors.orange,
                        Icons.fire_extinguisher,
                      ),
                    ],
                  ),

                  // Second Row
                  Row(
                    children: [
                      _buildAlertButton(
                        'SECURITY\nTHREAT',
                        'Security threat detected',
                        Colors.purple,
                        Icons.security,
                      ),
                      _buildAlertButton(
                        'NATURAL\nDISASTER',
                        'Natural disaster alert',
                        Colors.brown,
                        Icons.nature,
                      ),
                    ],
                  ),

                  // Third Row - Full width
                  Row(
                    children: [
                      _buildAlertButton(
                        'ACTIVE\nSHOOTER',
                        'Active shooter situation',
                        Colors.black,
                        Icons.warning,
                      ),
                      _buildAlertButton(
                        'SUSPICIOUS\nACTIVITY',
                        'Suspicious activity reported',
                        Colors.blueGrey,
                        Icons.people,
                      ),
                    ],
                  ),

                  // All Clear Button
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.check_circle, size: 24),
                      label: Text(
                        'ALL CLEAR / FALSE ALARM',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isLoading ? null : () => _sendAlert('ALL CLEAR', 'False alarm or situation resolved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Alert History Screen (you can expand this later)
class AlertHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alert History'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Alert history will be implemented here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}