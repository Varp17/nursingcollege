import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vibration/vibration.dart';

class StudentSosScreen extends StatefulWidget {
  const StudentSosScreen({super.key});

  @override
  State<StudentSosScreen> createState() => _StudentSosScreenState();
}

class _StudentSosScreenState extends State<StudentSosScreen>
    with SingleTickerProviderStateMixin {
  String? chosenType;
  String? chosenLocation;
  String? lastSentType;
  final TextEditingController desc = TextEditingController();
  bool anonymous = false;
  bool sending = false;

  final List<String> types = ["Standard SOS", "Girls SOS"];
  final List<String> locations = [
    "Ground Floor",
    "First Floor",
    "Second Floor",
    "Classroom",
    "Laboratory",
    "Library",
    "Canteen",
    "Parking",
    "Outside Campus"
  ];

  late AnimationController _popupController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _popupController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(
      parent: _popupController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _popupController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _popupController.dispose();
    desc.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSendSOS() async {
    if (chosenType == null || chosenLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select type and location')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm SOS"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Type: $chosenType"),
            Text("Location: $chosenLocation"),
            if (desc.text.isNotEmpty) Text("Description: ${desc.text}"),
            Text("Send anonymously: ${anonymous ? 'Yes' : 'No'}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Send SOS")),
        ],
      ),
    );

    if (confirmed == true) _sendSOS();
  }

  Future<void> _sendSOS() async {
    setState(() => sending = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    final payload = {
      'studentUid': anonymous ? 'anonymous' : uid,
      'type': chosenType,
      'location': chosenLocation,
      'description': desc.text.trim().isNotEmpty ? desc.text.trim() : null,
      'anonymous': anonymous,
      'status': 'sent',
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      final docRef = await FirebaseFirestore.instance.collection('incidents').add(payload);
      lastSentType = chosenType;

      _popupController.forward();
      await Future.delayed(const Duration(seconds: 4));
      _popupController.reverse();

      setState(() {
        chosenType = null;
        chosenLocation = null;
        desc.clear();
        anonymous = false;
      });

      Vibration.vibrate(duration: 300);

      print('✅ SOS sent. Document ID: ${docRef.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SOS: $e')),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send SOS'), backgroundColor: Colors.redAccent),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send SOS',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select SOS Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SOSChoiceGrid(
                    choices: types,
                    selected: chosenType,
                    onSelect: (s) => setState(() => chosenType = s),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SOSChoiceGrid(
                    choices: locations,
                    selected: chosenLocation,
                    onSelect: (s) => setState(() => chosenLocation = s),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: desc,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Optional description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(value: anonymous, onChanged: (v) => setState(() => anonymous = v ?? false)),
                      const Text('Send anonymously')
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: sending ? null : _confirmAndSendSOS,
                      child: Text(sending ? 'Sending...' : 'Send SOS', style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          if (_popupController.status != AnimationStatus.dismissed)
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Card(
                    color: Colors.greenAccent.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        lastSentType == "Girls SOS"
                            ? "Your Girls SOS has been sent discreetly"
                            : "Your Standard SOS has been sent",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SOSChoiceGrid extends StatelessWidget {
  final List<String> choices;
  final String? selected;
  final Function(String) onSelect;

  const SOSChoiceGrid({
    super.key,
    required this.choices,
    required this.onSelect,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 3.5,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: choices.map((e) {
        final isSelected = e == selected;
        return GestureDetector(
          onTap: () => onSelect(e),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.redAccent : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 8)]
                  : [],
            ),
            child: Text(
              e,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
