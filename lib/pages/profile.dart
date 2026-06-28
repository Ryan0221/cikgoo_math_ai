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

                        // --- NEW: Settings Dialog Button ---
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: 'Settings',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const SettingsDialog(),
                            );
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

// ============================================================================
// NEW: SETTINGS DIALOG (POPUP)
// ============================================================================

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {

  Future<void> _signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.of(context).pop();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Updated to match the frosted glass theme
  void _showPasswordDialog(BuildContext context, User user, bool hasPassword, bool isDark) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2A49).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasPassword ? "Change Password" : "Set Account Password",
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Enter new password (Min. 6 chars)",
                      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (passwordController.text.length < 6) return;
                          try {
                            await user.updatePassword(passwordController.text);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text("Save", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Updated Theme Dialog with 2 Rows for Dark Mode
  void _showThemeDialog(BuildContext context, bool isDark) {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2A49).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Select Theme", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // OPTION 1: Light Mode
                    _buildThemeTile("Light Mode", Icons.light_mode, 'light', isDark),

                    const Divider(height: 30, color: Colors.grey),

                    // OPTION 2: Dark Mode Container
                    _buildDarkThemeSection(isDark),
                  ],
                ),
              ),
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

  Widget _buildDarkThemeSection(bool isDark) {
    bool isDarkActive = appThemeNotifier.value.startsWith('dark');
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkActive ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDarkActive ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.transparent),
      ),
      child: Column(
        children: [
          // Row 1: Base Dark Mode
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.dark_mode, color: isDarkActive ? Colors.blueAccent : textColor),
            title: Text("Dark Mode", style: TextStyle(color: isDarkActive ? Colors.blueAccent : textColor, fontWeight: isDarkActive ? FontWeight.bold : FontWeight.normal)),
            onTap: () {
              appThemeNotifier.value = 'dark_none';
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          // Row 2: The 4 Effects
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEffectButton('dark_starry', Icons.auto_awesome, "Stars"),
              _buildEffectButton('dark_rain', Icons.water_drop, "Rain"),
              _buildEffectButton('dark_snow', Icons.ac_unit, "Snow"),
              _buildEffectButton('dark_leaves', Icons.eco, "Leaves"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEffectButton(String themeValue, IconData icon, String label) {
    bool isSelected = appThemeNotifier.value == themeValue;
    return InkWell(
      onTap: () {
        appThemeNotifier.value = themeValue;
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<String>(
      valueListenable: appThemeNotifier,
      builder: (context, themeStr, child) {
        bool isDark = themeStr.startsWith('dark');
        Color textColor = isDark ? Colors.white : Colors.black87;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2A49).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Hugs content tightly
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), // Spacer for centering
                      Text('Settings', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSettingsTile(
                    icon: Icons.palette,
                    title: 'Change Theme',
                    textColor: textColor,
                    isDark: isDark,
                    onTap: () => _showThemeDialog(context, isDark),
                  ),
                  _buildSettingsTile(
                    icon: Icons.language,
                    title: 'Switch Language',
                    textColor: textColor,
                    isDark: isDark,
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.password,
                    title: 'Change Password',
                    textColor: textColor,
                    isDark: isDark,
                    onTap: () {
                      if (user != null) {
                        bool hasPassword = user.providerData.any((userInfo) => userInfo.providerId == 'password');
                        _showPasswordDialog(context, user, hasPassword, isDark);
                      }
                    },
                  ),
                  const Divider(height: 30, color: Colors.white),
                  _buildSettingsTile(
                    icon: Icons.logout,
                    title: 'Log Out',
                    textColor: Colors.redAccent,
                    iconColor: Colors.redAccent,
                    isDark: isDark,
                    onTap: () => _signOut(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required Color textColor,
    Color? iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? textColor).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? textColor, size: 24),
      ),
      title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 16)),
      trailing: Icon(Icons.chevron_right, color: textColor.withValues(alpha: 0.5)),
      onTap: onTap,
    );
  }
}