import 'dart:math'; // Added for random math logic
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Required for ScrollDirection
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

  bool _isVisible = true;

  // method to updates the new selected index
  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // pages
  final List _pages = [Home(), Bookmark(), Notes(), Profile()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // extendBody allows the background to flow under the nav bar to show the blur effect
      extendBody: true,

      // NotificationListener catches scroll events from the child pages
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is UserScrollNotification) {
            // User scrolls down
            if (notification.direction == ScrollDirection.reverse) {
              if (_isVisible) {
                setState(() => _isVisible = false);
              }
            }
            // User scrolls up
            else if (notification.direction == ScrollDirection.forward) {
              if (!_isVisible) {
                setState(() => _isVisible = true);
              }
            }
          }
          // Failsafe: Always show the bar if we reach the absolute top of the page
          if (notification.metrics.pixels <= 0 && !_isVisible) {
            setState(() => _isVisible = true);
          }

          return false; // Return false so the scroll events continue to function normally
        },
        // Wrap the active page in the StarryBackground
        child: StarryBackground(
          child: _pages[_selectedIndex],
        ),
      ),

      // bottom navigation bar
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 350), // Smooth 0.35s speed
        curve: Curves.easeOutCubic, // Makes it snap into place nicely
        offset: _isVisible ? Offset.zero : const Offset(0, 2.5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
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
          color: isSelected
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(
            25,
          ), // Pill shape for individual items
          border: isSelected
              ? Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 0.5,
          )
              : null,
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.4,
              ), // Outer glow effect
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MOVED STARRY BACKGROUND FEATURE CLASSES ---

class Star {
  double x;
  double y;
  double maxOpacity;
  double currentOpacity = 0.0;
  int state = 0; // 0: completely dark, 1: brightening up, 2: dimming down

  Star({required this.x, required this.y, required this.maxOpacity});
}

class StarryBackground extends StatefulWidget {
  final Widget child;

  const StarryBackground({super.key, required this.child});

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Star> _stars = [];
  final int _starCount = 100; // Number of stars
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Constantly ticking animation controller to update the star brightness
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() {
        _updateStars();
      })
      ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stars.isEmpty) {
      final size = MediaQuery.of(context).size;
      // Initialize stars spread randomly across the screen
      for (int i = 0; i < _starCount; i++) {
        _stars.add(Star(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          maxOpacity: 0.3 + _random.nextDouble() * 0.7, // Random maximum brightness
        ));
      }
    }
  }

  void _updateStars() {
    bool needsRepaint = false;
    for (var star in _stars) {
      if (star.state == 0) {
        // Star is dark: Very low probability it decides to start shining on this frame
        if (_random.nextDouble() < 0.01) {
          star.state = 1;
          needsRepaint = true;
        }
      } else if (star.state == 1) {
        // Brightening up
        star.currentOpacity += 0.015;
        if (star.currentOpacity >= star.maxOpacity) {
          star.state = 2; // Reached peak, start dimming
        }
        needsRepaint = true;
      } else if (star.state == 2) {
        // Dimming down
        star.currentOpacity -= 0.010;
        if (star.currentOpacity <= 0) {
          star.currentOpacity = 0;
          star.state = 0; // Back to dark
        }
        needsRepaint = true;
      }
    }
    // Only rebuild if a star is actively shining
    if (needsRepaint) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark background (Using your beautiful gradient)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F172A),
                Color(0xFF000000),
              ], // Soft pastel gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Draws the animated stars
        CustomPaint(
          size: Size.infinite,
          painter: StarPainter(_stars),
        ),
        // Your main interactive UI overlaid on top
        widget.child,
      ],
    );
  }
}

class StarPainter extends CustomPainter {
  final List<Star> stars;
  StarPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var star in stars) {
      if (star.currentOpacity > 0) {
        paint.color = Colors.white.withValues(alpha: star.currentOpacity);
        // Drawing a small star.
        canvas.drawCircle(Offset(star.x, star.y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}