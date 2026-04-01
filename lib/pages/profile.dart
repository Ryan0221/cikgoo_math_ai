import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  Future<void> _signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF223257),
                  Color(0xFF1A2A49),
                  Color(0xFF0E1A2E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PopupMenuButton<String>(
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
                              content: const Text(
                                  "Language settings coming soon!"),
                              backgroundColor: Colors.blueAccent.withValues(
                                  alpha: 0.8),
                            ),
                          );
                        } else if (choice == 'Change Password') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  "To come"),
                              backgroundColor: Colors.blueAccent.withValues(
                                  alpha: 0.8),
                            ),
                          );
                        } else if (choice == 'Logout') {
                          _signOut(context);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem<String>(
                            value: 'Switch Language',
                            child: Row(
                              children: [
                                Icon(Icons.language, color: Colors.white70,
                                    size: 22),
                                SizedBox(width: 22),
                                Text('Switch Language', style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 1),
                          const PopupMenuItem<String>(
                            value: 'Change Password',
                            child: Row(
                              children: [
                                Icon(Icons.password, color: Colors.white70,
                                    size: 22),
                                SizedBox(width: 22),
                                Text('Change Password', style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 1.5),
                          const PopupMenuItem<String>(
                            value: 'Logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.redAccent,
                                    size: 22),
                                SizedBox(width: 22),
                                Text('Log Out', style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ];
                      },
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
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.9,
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
                                    color: Colors.greenAccent.withValues(
                                        alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white.withValues(
                                    alpha: 0.1),
                                backgroundImage: user?.photoURL != null
                                    ? NetworkImage(user!.photoURL!)
                                    : null,
                                child: user?.photoURL == null
                                    ? const Icon(Icons.person, size: 32,
                                    color: Colors.white54)
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
                                      color: Colors.white.withValues(
                                          alpha: 0.6),
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
                                      color: Colors.white.withValues(
                                          alpha: 0.2),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white70,
                                    size: 20, // Reduced size for better fit
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
        ],
      ),
    );
  }
}
