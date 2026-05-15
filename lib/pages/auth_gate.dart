import 'package:cikgoo_math_ai/pages/first_page.dart';
import 'package:cikgoo_math_ai/pages/sync_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cikgoo_math_ai/pages/login_signup.dart';

import 'admin_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        // 1. While Firebase Auth is checking the user's state, show a loading spinner
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. If the user is actively logged in via Auth, we must now check their role in Firestore
        if (authSnapshot.hasData) {
          final user = authSnapshot.data!;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, firestoreSnapshot) {

              // While waiting for the Firestore document to download, show a loading spinner
              if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // If we successfully retrieved the user's database document
              if (firestoreSnapshot.hasData && firestoreSnapshot.data!.exists) {
                // Extract the role. If it doesn't exist, default to 'user'
                String role = firestoreSnapshot.data!.get('role') ?? 'user';

                // 3. Route them securely based on their database role
                if (role == 'admin' || role == 'super admin') {
                  return const AdminDashboard();
                } else {
                  return const SyncScreen();
                }
              }

              // Fallback: If they are logged in but their Firestore document hasn't been created yet
              // (This happens briefly during the sign-up process)
              return const FirstPage();
            },
          );
        }

        // 4. If they are NOT logged in, show the Login/Signup Screen
        return const LoginSignup();
      },
    );
  }
}