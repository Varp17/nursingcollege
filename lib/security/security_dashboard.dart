import 'package:collegesafety/common/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/app_drawer.dart';

class SecurityDashboard extends StatelessWidget {
  const SecurityDashboard({super.key, required String username, required UserRole role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Security Dashboard")),
      drawer: const AppDrawer(role: "security"),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("complaints")
            .where("status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var complaints = snapshot.data!.docs;

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              var data = complaints[index];
              return Card(
                child: ListTile(
                  title: Text(data["type"]),
                  subtitle: Text("Status: ${data["status"]}"),
                  trailing: ElevatedButton(
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection("complaints")
                          .doc(data.id)
                          .update({"status": "resolved"});
                    },
                    child: const Text("Resolve"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
