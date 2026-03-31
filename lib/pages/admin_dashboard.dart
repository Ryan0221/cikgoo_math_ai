import 'package:flutter/material.dart';
import 'package:cikgoo_math_ai/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> _signOut(BuildContext context) async {
    await GoogleSignIn().signOut(); // Sign out from Google
    await FirebaseAuth.instance.signOut(); // Sign out from Firebase
  }

  void _showAddNoteDialog(BuildContext context) {
    final TextEditingController idController = TextEditingController();
    double selectedAlignX = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Course Node"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: "Node ID (e.g., Chapter 6)"),
              ),
              const SizedBox(height: 20),
              const Text("Position on screen (Left to Right):"),
              // A simple slider to pick the X alignment (-1.0 to 1.0)
              StatefulBuilder(
                  builder: (context, setState) {
                    return Slider(
                      value: selectedAlignX,
                      min: -1.0,
                      max: 1.0,
                      divisions: 10,
                      label: selectedAlignX.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          selectedAlignX = value;
                        });
                      },
                    );
                  }
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (idController.text.isNotEmpty) {
                  // 1. Call your new service!
                  // (isRevision is false because this is the Notes tab)
                  await FirestoreService().addPathNode(idController.text, false, selectedAlignX);

                  // 2. Close the dialog and show a success message
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Successfully added to Firebase!")),
                    );
                  }
                }
              },
              child: const Text("Save to Database"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add an AppBar with a logout button
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.red[900],
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: const Center(
        child: Text("Notes list will go here!"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red[800],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add New Note", style: TextStyle(color: Colors.white)),
        onPressed: () => _showAddNoteDialog(context),
      ),
    );
  }
}