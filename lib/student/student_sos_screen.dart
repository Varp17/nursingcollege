// lib/student/student_sos_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vibration/vibration.dart';
import '../theme/theme.dart'; // Add this line
class StudentSosScreen extends StatefulWidget {
  const StudentSosScreen({super.key});

  @override
  State<StudentSosScreen> createState() => _StudentSosScreenState();
}

class _StudentSosScreenState extends State<StudentSosScreen> {
  String? chosenType;
  String? chosenLocation;
  final TextEditingController desc = TextEditingController();
  bool anonymous = false;
  bool sending = false;

  final List<String> types = ["Medical Emergency", "Security Threat", "Fire", "Accident", "Harassment", "Other"];
  final List<String> locations = [
    "Main Building", "Science Block", "Library", "Cafeteria",
    "Sports Ground", "Parking Lot", "Hostel", "Admin Block", "Other"
  ];

  Future<void> _sendSOS() async {
    if (chosenType == null || chosenLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select type and location')),
      );
      return;
    }

    setState(() => sending = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login first')),
      );
      setState(() => sending = false);
      return;
    }

    try {
      // Get user data first
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      // Validate user is approved and has required data
      if (userData['approved'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your account is not yet approved. Please contact administrator.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => sending = false);
        return;
      }

      // Create incident data - ensure all required fields are present
      final incidentData = {
        'studentUid': anonymous ? 'anonymous' : user.uid,
        'studentName': anonymous ? 'Anonymous' : userData['name'] ?? 'Student',
        'studentEmail': anonymous ? null : user.email,
        'type': chosenType!,
        'location': chosenLocation!,
        'description': desc.text.trim().isEmpty ? null : desc.text.trim(),
        'anonymous': anonymous,
        'status': 'pending', // Required field
        'timestamp': FieldValue.serverTimestamp(), // Required field
        'section': userData['section'],
        'college': userData['college'],
        'department': userData['department'],
        'priority': _getPriorityLevel(chosenType!),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Remove null values to avoid validation issues
      incidentData.removeWhere((key, value) => value == null);

      // Save to incidents collection
      final incidentRef = await FirebaseFirestore.instance
          .collection('incidents')
          .add(incidentData);

      // Update with incident ID
      await incidentRef.update({'incidentId': incidentRef.id});

      // Create security alert
      await _createSecurityAlert(incidentRef.id, incidentData);

      // Reset form
      setState(() {
        chosenType = null;
        chosenLocation = null;
        desc.clear();
        anonymous = false;
      });

      // Vibrate for confirmation
      Vibration.vibrate(duration: 500);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚨 SOS Alert Sent! Security has been notified.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

    } catch (e) {
      print('Error sending SOS: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send SOS. Please check your connection and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => sending = false);
    }
  }

// Helper method to determine priority based on emergency type
  String _getPriorityLevel(String type) {
    const highPriority = ['Medical Emergency', 'Security Threat', 'Fire'];
    const mediumPriority = ['Accident', 'Harassment'];

    if (highPriority.contains(type)) return 'high';
    if (mediumPriority.contains(type)) return 'medium';
    return 'low';
  }

// Helper method for user-friendly error messages
  String _getErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to send SOS alerts. Please contact administrator.';
      case 'unauthenticated':
        return 'Please log in to send SOS alerts.';
      case 'invalid-argument':
        return 'Invalid data provided. Please check your inputs.';
      default:
        return 'Network error. Please check your connection and try again.';
    }
  }
  Future<void> _createSecurityAlert(String incidentId, Map<String, dynamic> incidentData) async {
    try {
      final alertData = {
        'incidentId': incidentId,
        'studentName': incidentData['studentName'],
        'location': incidentData['location'],
        'type': incidentData['type'],
        'description': incidentData['description'],
        'timestamp': FieldValue.serverTimestamp(),
        'priority': 'high',
        'status': 'new', // new, acknowledged, resolved
        'section': incidentData['section'],
        'college': incidentData['college'],
        'readBy': [],
      };

      await FirebaseFirestore.instance
          .collection('security_alerts')
          .doc(incidentId)
          .set(alertData);

      print('🔔 Security alert created: $incidentId');
    } catch (e) {
      print('Error creating security alert: $e');
      // Don't throw error here - incident is already created
    }
  }

  Widget _buildTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        return _buildChoiceCard(
          title: type,
          isSelected: chosenType == type,
          onTap: () => setState(() => chosenType = type),
          color: Colors.red,
        );
      },
    );
  }

  Widget _buildLocationGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        return _buildChoiceCard(
          title: location,
          isSelected: chosenLocation == location,
          onTap: () => setState(() => chosenLocation = location),
          color: Colors.blue,
        );
      },
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      color: isSelected ? color : Colors.white,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'Emergency SOS',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 2,
        foregroundColor: AppColors.textGrey,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppGradients.studentGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.studentPrimary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.emergency_outlined, size: 48, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Emergency SOS',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This will immediately notify security personnel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Emergency Type
              Text(
                'Emergency Type *',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 12),
              _buildTypeGrid(),
              SizedBox(height: 24),

              // Location
              Text(
                'Location *',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 12),
              _buildLocationGrid(),
              SizedBox(height: 24),

              // Description
              Text(
                'Additional Details (Optional)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: desc,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the emergency situation...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintStyle: TextStyle(color: AppColors.hintGrey),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Anonymous Option
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Checkbox(
                        value: anonymous,
                        onChanged: (v) => setState(() => anonymous = v ?? false),
                        activeColor: AppColors.studentPrimary,
                      ),
                      Expanded(
                        child: Text(
                          'Send anonymously (security will not see your name)',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: sending ? null : _sendSOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.sosStart.withOpacity(0.4),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.sosGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: sending
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emergency_outlined, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'SEND EMERGENCY ALERT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Only use in case of real emergencies',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.hintGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}