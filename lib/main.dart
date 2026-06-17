import 'package:cikgoo_math_ai/pages/admin_dashboard.dart';
import 'package:cikgoo_math_ai/pages/sync_screen.dart';
import 'package:flutter/material.dart';
import 'package:cikgoo_math_ai/pages/first_page.dart';
import 'package:cikgoo_math_ai/pages/login_signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cikgoo_math_ai/pages/auth_gate.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future <void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FORCE OFFLINE MODE ON
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Load the .env file
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: {
        '/home': (context) => const FirstPage(),
        '/login': (context) => const LoginSignup(),
        '/first_page': (context) => const FirstPage(),
        '/sync_screen': (context) => const SyncScreen(),
        '/admin_dashboard': (context) => const AdminDashboard()
      },
    );
  }
}
