import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("College Safety Dashboard")),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComplaintScreen()),
            );
          },
          child: const Text("🚨 SOS"),
        ),
      ),
    );
  }
}

class ComplaintScreen extends StatelessWidget {
  const ComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final complaints = [
      "Harassment",
      "Ragging",
      "Patient Violence",
      "Fighting in Parking",
      "Student Needs Help",
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Select Complaint Type")),
      body: ListView.builder(
        itemCount: complaints.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(complaints[index]),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${complaints[index]} reported!")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
