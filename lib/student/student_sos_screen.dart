import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Brand {
  static const deepTeal = Color(0xFF0F4C75);
  static const sosCoral = Color(0xFFE63946);
  static const softGrey = Color(0xFFF4F6F8);
  static const navy = Color(0xFF0C2D48);
  static const pastelPink = Color(0xFFFFC7CF);
  static const r2xl = 24.0;

  static const gap8 = SizedBox(height: 8);
  static const gap12 = SizedBox(height: 12);
  static const gap16 = SizedBox(height: 16);
  static const gap24 = SizedBox(height: 24);

  static TextStyle titleLg(BuildContext c) =>
      Theme.of(c).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w700);
  static TextStyle bodyMd(BuildContext c) => Theme.of(c).textTheme.bodyMedium!;
}

class StudentSosScreen extends StatefulWidget {
  const StudentSosScreen({super.key});

  @override
  State<StudentSosScreen> createState() => _StudentSosScreenState();
}

class _StudentSosScreenState extends State<StudentSosScreen> {
  String? _selectedLocation;
  String? _otherLocation;
  String? _selectedIssue;
  String? _otherIssue;
  String _selectedType = 'standard';
  bool _overlayVisible = false;
  bool _confirmShown = false;
  int _remaining = 0;
  Timer? _timer;

  final List<String> _locations = [
    "Ground Floor","First Floor","Second Floor","Classroom","Laboratory",
    "Library","Canteen","Parking","Outside Campus"
  ];

  final List<String> _issues = [
    "Creating ruckus","Harmful chemical","Crowd","Injury","Person help",
    "Ambulance","Other"
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown(String type) {
    _selectedType = type;
    _confirmShown = false;
    _overlayVisible = true;
    _remaining = 15;
    setState(() {});
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining -= 1);
      HapticFeedback.vibrate();

      if (!_confirmShown && _remaining <= 10) {
        _confirmShown = true;
        _showConfirmSheet(type);
      }

      if (_remaining <= 0) {
        t.cancel();
        _sendIncident(autoFromTimer: true);
      }
    });
  }

  void _cancelAll() {
    _timer?.cancel();
    _resetOverlay();
  }

  void _resetOverlay() {
    setState(() {
      _overlayVisible = false;
      _remaining = 0;
      _confirmShown = false;
      _selectedLocation = null;
      _otherLocation = null;
      _selectedIssue = null;
      _otherIssue = null;
    });
  }

  Future<void> _sendIncident({bool autoFromTimer = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final payload = {
      'studentUid': uid,
      'type': _selectedType,
      'location': _selectedLocation ?? (_otherLocation?.trim().isNotEmpty == true ? _otherLocation!.trim() : null),
      'issue': _selectedIssue ?? (_otherIssue?.trim().isNotEmpty == true ? _otherIssue!.trim() : null),
      'status': 'sent',
      'discreet': _selectedType=='girls',
      'countdownSeconds': 15,
      'confirmedAt5s': _confirmShown,
      'autoSentOnTimeout': autoFromTimer,
      'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      await FirebaseFirestore.instance.collection('incidents').add(payload);
      _overlayVisible = false;
      setState(() {});
      _showStudentSentDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SOS: $e')),
      );
    } finally {
      _timer?.cancel();
    }
  }

  void _showConfirmSheet(String type) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20,20,20,28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("Are you sure you want to alert?", style: Brand.titleLg(ctx)),
          Brand.gap12,
          Text("A ${type=='standard'?'Standard':'Girls'} SOS will be sent to Security/Admin.\nYou can still cancel before countdown finishes.",
              style: Brand.bodyMd(ctx), textAlign: TextAlign.center),
          Brand.gap16,
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () { Navigator.pop(ctx); _cancelAll(); }, child: const Text("Cancel"))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: type=='standard'?Brand.deepTeal:Brand.sosCoral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.r2xl)),
              ),
              onPressed: () { Navigator.pop(ctx); _sendIncident(); },
              child: const Text("Send Now"),
            )),
          ])
        ]),
      ),
    );
  }

  void _showStudentSentDialog() {
    if (!mounted) return;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('SOS Sent'),
        content: Text(_selectedType=='standard'
            ? 'Your Standard SOS has been sent to Security/Admin.'
            : 'Your Girls SOS has been sent discreetly.'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _resetOverlay(); }, child: const Text('OK'))
        ],
      ),
    );
  }

  Widget _gridSelection(List<String> items, String? selectedValue, Function(String) onSelect) {
    return GridView.count(
      shrinkWrap: true, crossAxisCount: 3, childAspectRatio: 2.5,
      crossAxisSpacing: 8, mainAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((e) {
        final selected = selectedValue == e;
        return GestureDetector(
          onTap: () => setState(() => onSelect(e)),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Brand.deepTeal : Colors.white,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(e, style: TextStyle(color: selected?Colors.white:Colors.black)),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety & SOS'), backgroundColor: Brand.deepTeal),
      backgroundColor: Brand.softGrey,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Select Location', style: Brand.titleLg(context)),
                Brand.gap12,
                _gridSelection(_locations, _selectedLocation, (val) => _selectedLocation=val),
                Brand.gap24,
                Text('Select Incident Type', style: Brand.titleLg(context)),
                Brand.gap12,
                _gridSelection(_issues, _selectedIssue, (val) => _selectedIssue=val),
                Brand.gap24,
                Row(
                  children: [
                    Expanded(child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Brand.deepTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: ()=>_startCountdown('standard'),
                      child: const Text('Send Standard SOS'),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Brand.sosCoral,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: ()=>_startCountdown('girls'),
                      child: const Text('Send Girls SOS'),
                    )),
                  ],
                ),
              ],
            ),
          ),
          if(_overlayVisible) _countdownOverlay(context),
        ],
      ),
    );
  }

  Widget _countdownOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black38,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Sending SOS in $_remaining s', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: _cancelAll,
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            )
          ]),
        ),
      ),
    );
  }
}
