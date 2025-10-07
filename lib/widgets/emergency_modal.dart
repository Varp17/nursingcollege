// widgets/emergency_modal.dart
import 'package:flutter/material.dart';

class EmergencyModal extends StatelessWidget {
  final Map<String, dynamic> incident;

  const EmergencyModal({Key? key, required this.incident}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.red[50],
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 10),
          Text('🚨 EMERGENCY SOS'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Student: ${incident['studentName']}'),
          Text('Description: ${incident['description']}'),
          if (incident['location'] != null && incident['location'].isNotEmpty)
            Text('Location: Available'),
          Text('Priority: ${incident['priority']?.toUpperCase() ?? 'MEDIUM'}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('ACKNOWLEDGE'),
        ),
      ],
    );
  }
}