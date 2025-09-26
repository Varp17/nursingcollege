import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/app_drawer.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      drawer: const AppDrawer(role: "admin"),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("complaints").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var complaints = snapshot.data!.docs;

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              var data = complaints[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data["type"]),
                  subtitle: Text("Status: ${data["status"]}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
