import 'package:flutter/material.dart';
import 'package:cikgoo_math_ai/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_add.dart';
import 'admin_edit.dart';
import 'admin_user_feedback.dart';
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

  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkSuperAdminStatus();
  }

  // Checks if the current logged-in user is a "super admin"
  Future<void> _checkSuperAdminStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['role'] == 'super admin') {
            setState(() {
              _isSuperAdmin = true;
            });
          }
        }
      } catch (e) {
        debugPrint("Error checking super admin status: $e");
      }
    }
  }

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
      const EditContentPanel(),
      const AddContentPanel(),
      const UserFeedbackPanel(),
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
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black, size: 28),
            tooltip: 'View as User',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/first_page');
            },
          ),
          // 1. NEW: The User Management Button (Only visible to super admin)
          if (_isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.manage_accounts, color: Colors.black, size: 28),
              tooltip: 'User Management',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const UserManagementDialog(),
                );
              },
            ),

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

// NEW: User Management Dialog Class
// -----------------------------------------------------------------------------
class UserManagementDialog extends StatefulWidget {
  const UserManagementDialog({Key? key}) : super(key: key);

  @override
  State<UserManagementDialog> createState() => _UserManagementDialogState();
}

class _UserManagementDialogState extends State<UserManagementDialog> {
  bool _isLoading = true;
  int _activeTab = 0; // 0 = Admin, 1 = User

  List<Map<String, dynamic>> _allUsers = [];

  // Tracks ONLY the changes made before saving. Map format: {uid: newRole}
  final Map<String, String> _pendingChanges = {};

  final List<String> _availableRoles = ['admin', 'user'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> users = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['uid'] = doc.id;
        // Never include super admins in this management list
        if (data['role'] != 'super admin') {
          users.add(data);
        }
      }

      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching users: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // Create a batch operation to save all changes at once
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var entry in _pendingChanges.entries) {
        DocumentReference docRef = FirebaseFirestore.instance.collection('users').doc(entry.key);
        batch.update(docRef, {'role': entry.value});
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User roles updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error saving roles: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // NEW LOGIC: Keep users visible in their original tab while editing
    List<Map<String, dynamic>> filteredUsers = _allUsers.where((user) {
      String originalRole = user['role'] ?? 'user';
      String? pendingRole = _pendingChanges[user['uid']];
      String currentRole = pendingRole ?? originalRole;

      if (_activeTab == 0) {
        // ADMIN TAB: Show if they WERE an admin, OR if they are BEING MADE an admin
        return originalRole == 'admin' || currentRole == 'admin';
      } else {
        // USER TAB: Show if they WERE a user, OR if they are BEING MADE a user
        return originalRole != 'admin' || currentRole != 'admin';
      }
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.grey[300], // Matches the mockup's outer grey container
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "User Management",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 1. TABS (Admin / User)
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _activeTab == 0 ? Colors.grey[700] : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Admin",
                          style: TextStyle(
                            color: _activeTab == 0 ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _activeTab == 1 ? Colors.grey[700] : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "User",
                          style: TextStyle(
                            color: _activeTab == 1 ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. THE TABLE AREA (White Background)
            Container(
              height: 350, // Fixed height to keep dialog sized properly
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  // Table Headers
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text("Name", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                        Expanded(flex: 3, child: Text("Email Address", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text("Role", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.grey),

                  // Table Data
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
                      itemBuilder: (context, index) {
                        var user = filteredUsers[index];
                        String uid = user['uid'];
                        String currentRole = _pendingChanges[uid] ?? user['role'] ?? 'user';
                        bool isModified = _pendingChanges.containsKey(uid);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Row(
                            children: [
                              // Name Column
                              Expanded(
                                flex: 2,
                                child: Text(
                                  user['name'] ?? user['displayName'] ?? 'Unknown',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              // Email Column
                              Expanded(
                                flex: 3,
                                child: Text(
                                  user['email'] ?? 'No Email',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              // Role Dropdown Column
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    // The background turns yellow if this specific user was modified!
                                    color: isModified ? Colors.yellow[300] : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: currentRole,
                                      isExpanded: true,
                                      iconSize: 16,
                                      style: const TextStyle(fontSize: 12, color: Colors.black),
                                      onChanged: (String? newValue) {
                                        if (newValue != null && newValue != user['role']) {
                                          setState(() {
                                            _pendingChanges[uid] = newValue;
                                          });
                                        } else if (newValue == user['role']) {
                                          // If they change it back to the original, remove the yellow highlight
                                          setState(() {
                                            _pendingChanges.remove(uid);
                                          });
                                        }
                                      },
                                      items: _availableRoles.map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. BOTTOM BUTTONS (Complete / Cancel)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3DCF00), // Exact green from mockup
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _pendingChanges.isEmpty ? null : _saveChanges,
                    child: const Text("Complete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.pop(context), // Instantly discards changes
                    child: const Text("Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}