import 'package:flutter/material.dart';

import 'learning_path_screen.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () {
            // 3. THE ROUTING MAGIC
            // This tells Flutter to slide the LearningPathScreen on top of the Home screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LearningPathScreen()),
            );
          },
          child: const Text(
            "Open Learning Path",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
