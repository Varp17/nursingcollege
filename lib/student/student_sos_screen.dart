import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('sos_alerts').add(payload);

      lastSentType = chosenType;

      _popupController.forward();
      await Future.delayed(const Duration(seconds: 2));
      _popupController.reverse();

      setState(() {
        chosenType = null;
        chosenLocation = null;
        desc.clear();
        anonymous = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send SOS: $e')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send SOS')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Hero(
                    tag: 'sos-hero',
                    child: Text(
                      'Send SOS',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Choose Type:'),
                  const SizedBox(height: 8),
                  SOSChoiceGrid(
                    choices: types,
                    selected: chosenType,
                    onSelect: (s) => setState(() => chosenType = s),
                  ),
                  const SizedBox(height: 16),
                  const Text('Choose Location:'),
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
                    decoration: const InputDecoration(
                      hintText: 'Optional description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: anonymous,
                        onChanged: (v) => setState(() => anonymous = v ?? false),
                      ),
                      const Text('Send anonymously')
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: sending ? null : _confirmAndSendSOS,
                      child: Text(sending ? 'Sending...' : 'Record & Auto-send'),
                    ),
                  ),
                  const SizedBox(height: 120), // Add padding for floating button
                ],
              ),
            ),
          ),
          // Central floating circular SOS button
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: sending ? null : _confirmAndSendSOS,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // SOS Sent popup
          if (_popupController.status != AnimationStatus.dismissed)
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Card(
                    color: Colors.greenAccent.shade100,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        lastSentType == "Girls SOS"
                            ? "Your Girls SOS has been sent discreetly"
                            : "Your Standard SOS has been sent",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
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
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 6)]
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
