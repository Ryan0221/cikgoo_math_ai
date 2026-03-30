import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Update these to match your actual file paths and project name!
import 'package:cikgoo_math_ai/pages/login_signup.dart';
import 'package:cikgoo_math_ai/pages/home.dart';

import 'admin_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // StreamBuilder constantly listens to the Firebase Auth state
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {

          // 1. While Firebase is checking the user's state, show a loading spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. If the user is actively logged in, show the Home Screen
          if (snapshot.hasData) {
            final user = snapshot.data!;

            if (user?.email == 'tjk02020113@gmail.com') {
              return const AdminDashboard();
            } else {
              return const Home();
            }
          }

          // 3. If they are NOT logged in, show the Login/Signup Screen
          return const LoginSignup();
        },
      ),
    );
  }
}