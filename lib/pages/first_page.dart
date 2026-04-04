import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cikgoo_math_ai/pages/notes.dart';
import 'package:cikgoo_math_ai/pages/profile.dart';
import 'package:cikgoo_math_ai/pages/bookmark.dart';

import 'home.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  // keep track of current page
  int _selectedIndex = 0;

  // method to updates the new selected index
  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // pages
  final List _pages = [
    Home(),
    Bookmark(),
    Notes(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // extendBody allows the background to flow under the nav bar to show the blur effect
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF000000)], // Soft pastel gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // The frosted glass blur
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4), // Translucent white base
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), // Soft highlight edge
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_outlined, 'Home', 0),
                  _buildNavItem(Icons.bookmark_border, 'Bookmark', 1),
                  _buildNavItem(Icons.menu_book_rounded, 'Notes', 2),
                  _buildNavItem(Icons.person_outline, 'Profile', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  // Custom widget to match the Apple "dark pill" style from the generated image
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _navigateBottomBar(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 55,
        decoration: BoxDecoration(
          // Darker background for active, slightly transparent dark for inactive
          color: isSelected ? Colors.black.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(25), // Pill shape for individual items
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5)
              : null,
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4), // Outer glow effect
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
