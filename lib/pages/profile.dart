import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/theme_manager.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool _isAdminOrSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  // --- NEW: Check if the user is an admin or super admin ---
  Future<void> _checkAdminRole() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role'];

          if (role == 'admin' || role == 'super admin') {
            setState(() {
              _isAdminOrSuperAdmin = true;
            });
          }
        }
      } catch (e) {
        debugPrint("Error checking admin role: $e");
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // --- NEW: Password Dialog Function ---
  void _showPasswordDialog(BuildContext context, User user, bool hasPassword) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2A49), // Matches your dark theme
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            // Smart title based on whether they already have a password
            hasPassword ? "Change Password" : "Set Account Password",
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter new password (12 ~ 64 length containing uppercase, lowercase, number, and special character)",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.greenAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password must be at least 6 characters."), backgroundColor: Colors.redAccent),
                  );
                  return;
                }

                try {
                  // This one Firebase method handles BOTH updating and adding passwords!
                  await user.updatePassword(passwordController.text);

                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(hasPassword ? "Password changed successfully!" : "Password linked! You can now login with Email/Password."),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog

                    // The classic Firebase "Recent Login Required" security trap
                    if (e.code == 'requires-recent-login') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Security alert: Please log out and log back in to verify your identity before changing your password."),
                          backgroundColor: Colors.redAccent,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${e.message}"), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                }
              },
              child: const Text("Save", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // --- NEW: Theme Selection Dialog ---
  void _showThemeDialog(BuildContext context, bool isDark) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1A2A49) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Select Theme", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeTile("Light Mode", Icons.light_mode, 'light', isDark),
                _buildThemeTile("Dark Mode (Pure)", Icons.dark_mode, 'dark_none', isDark),
                _buildThemeTile("Dark Mode (Starry)", Icons.auto_awesome, 'dark_starry', isDark),
              ],
            ),
          );
        }
    );
  }

  Widget _buildThemeTile(String title, IconData icon, String themeValue, bool isDark) {
    Color textColor = isDark ? Colors.white : Colors.black87;
    bool isSelected = appThemeNotifier.value == themeValue;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blueAccent : textColor),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.blueAccent : textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blueAccent) : null,
      onTap: () {
        appThemeNotifier.value = themeValue;
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    // Listen to theme to adjust text colors
    return ValueListenableBuilder<String>(
        valueListenable: appThemeNotifier,
        builder: (context, themeStr, child) {
          bool isDark = themeStr.startsWith('dark');
          Color textColor = isDark ? Colors.white : Colors.black87;
          Color subTextColor = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54;

          return Scaffold(
            // 1. MAKE SCAFFOLD TRANSPARENT SO THE GLOBAL BACKGROUND SHOWS THROUGH!
            backgroundColor: Colors.transparent,

          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- NEW: Admin Dashboard Button ---
                        if (_isAdminOrSuperAdmin) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 28,
                            ),
                            tooltip: 'Return to Admin Dashboard',
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/admin_dashboard');
                            },
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Existing Settings Menu
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 28,
                          ),
                          color: const Color(0xFF1A2A49),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          onSelected: (String choice) {
                            if (choice == 'Switch Language') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Language settings coming soon!"),
                                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.8),
                                ),
                              );
                            } else if (choice == 'Change Password') {
                              if (user != null) {
                                bool hasPassword = user.providerData.any((userInfo) => userInfo.providerId == 'password');
                                _showPasswordDialog(context, user, hasPassword);
                              }
                            } else if (choice == 'Logout') {
                              _signOut(context);
                            }
                          },

                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem<String>(
                                value: 'Change Theme',
                                child: Row(
                                  children: [
                                    Icon(Icons.palette, color: isDark ? Colors.white70 : Colors.black54, size: 22),
                                    const SizedBox(width: 22),
                                    Text('Change Theme', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Switch Language',
                                child: Row(
                                  children: [
                                    Icon(Icons.language, color: Colors.white70, size: 22),
                                    SizedBox(width: 22),
                                    Text('Switch Language', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              const PopupMenuItem<String>(
                                value: 'Change Password',
                                child: Row(
                                  children: [
                                    Icon(Icons.password, color: Colors.white70, size: 22),
                                    SizedBox(width: 22),
                                    Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(height: 1.5),
                              const PopupMenuItem<String>(
                                value: 'Logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.redAccent, size: 22),
                                    SizedBox(width: 22),
                                    Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // PROFILE PICTURE
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.greenAccent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                backgroundImage: user?.photoURL != null
                                    ? NetworkImage(user!.photoURL!)
                                    : null,
                                child: user?.photoURL == null
                                    ? const Icon(Icons.person, size: 32, color: Colors.white54)
                                    : null,
                              ),
                            ),

                            const SizedBox(width: 15),

                            // USER DETAILS
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName ?? 'Welcome!',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? 'No email found',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // EDIT BUTTON
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // TODO: Add edit profile logic
                                },
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          );
        }
    );
  }
}