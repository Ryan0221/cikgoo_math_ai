import 'package:flutter/material.dart';
import 'package:cikgoo_math_ai/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'admin_add.dart';
import 'admin_view.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Navigation State
  int _selectedIndex = 0;
  final List<String> _navItems = ['View', 'Edit', 'Add', 'User Feedback'];
  final List<Color> activeColors = [
    const Color(0xFF42E012),  // View
    Colors.orange,            // Edit
    Colors.red,               // Add
    Colors.black,             // User Feedback
  ];

  // Firebase Logout Method
  Future<void> _signOut(BuildContext context) async {
    await GoogleSignIn().signOut(); // Sign out from Google
    await FirebaseAuth.instance.signOut(); // Sign out from Firebase
  }

  // Your existing dialog method
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
    // Dynamic pages based on your tabs
    final List<Widget> pages = [
      const ViewContentPanel(),
      const Center(child: Text("Edit Content", style: TextStyle(fontSize: 24))),
      const AddContentPanel(),
      const Center(child: Text("User Feedback Content", style: TextStyle(fontSize: 24))),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        actions: [
          // The settings icon is now a PopupMenuButton
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_outlined, color: Colors.black, size: 28),
            tooltip: 'Settings',
            onSelected: (value) {
              if (value == 'logout') {
                _signOut(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Text('Sign Out', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        //padding: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: EdgeInsetsGeometry.directional(bottom: 16.0, start: 16.0, end: 16.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200], // The grey background now wraps everything
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Removed SingleChildScrollView so the Row is constrained to the grey box width
              Row(
                children: List.generate(_navItems.length, (index) {
                  bool isActive = _selectedIndex == index;

                  // 2. Wrap with Expanded so each pill takes exactly equal space (1/4 of total)
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: AnimatedContainer(

                        duration: const Duration(milliseconds: 200),
                        // 3. Set your specific height here
                        height: 70,
                        // 4. Align text to the center since the container width is now fixed
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          // Use the list to assign a unique color when active!
                          color: isActive ? activeColors[index] : Colors.grey[400],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 0.5),
                        ),
                        child: Text(
                          _navItems[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Main Content Area inside the grey box
              Expanded(
                child: pages[_selectedIndex],
              ),
            ],
          ),
        ),
      ),
    );
  }
}