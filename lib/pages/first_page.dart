import 'dart:math'; // Added for random math logic
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Required for ScrollDirection
import 'package:cikgoo_math_ai/pages/notes.dart';
import 'package:cikgoo_math_ai/pages/profile.dart';
import 'package:cikgoo_math_ai/pages/bookmark.dart';

import '../services/theme_manager.dart';
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
    // Listen to theme changes to rebuild the scaffold and nav bar
    return ValueListenableBuilder<String>(
        valueListenable: appThemeNotifier,
        builder: (context, themeStr, child) {
          bool isLight = themeStr == 'light';

          return Scaffold(
            backgroundColor: Colors.transparent,
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
        // Wrap the active page in the Dynamic Background
        child: DynamicBackground(
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
                    _buildNavItem(Icons.home_outlined, 'Home', 0, isLight),
                    _buildNavItem(Icons.bookmark_border, 'Bookmark', 1, isLight),
                    _buildNavItem(Icons.menu_book_rounded, 'Notes', 2, isLight),
                    _buildNavItem(Icons.person_outline, 'Profile', 3, isLight),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
          );
        }
    );
  }

  // Custom widget to match the Apple "dark pill" style from the generated image
  Widget _buildNavItem(IconData icon, String label, int index, bool isLight) {
    bool isSelected = _selectedIndex == index;

    // Theme-based colors for the pill
    Color activeBgColor = isLight ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.6);
    Color inactiveBgColor = isLight ? Colors.transparent : Colors.black.withValues(alpha: 0.3);
    Color activeIconColor = isLight ? Colors.blue[800]! : Colors.white;
    Color inactiveIconColor = isLight ? Colors.grey[600]! : Colors.white.withValues(alpha: 0.5);

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

// --- DYNAMIC BACKGROUND CLASSES ---

class Star {
  double x, y, maxOpacity, currentOpacity = 0.0;
  int state = 0;
  Star({required this.x, required this.y, required this.maxOpacity});
}

class WeatherParticle {
  double x, y, speed, size, drift;
  Color color;
  WeatherParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.drift,
    required this.color,
  });
}

class DynamicBackground extends StatefulWidget {
  final Widget child;
  const DynamicBackground({super.key, required this.child});

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Star> _stars = [];
  final List<WeatherParticle> _particles = [];

  final int _starCount = 100;
  final int _particleCount = 60; // Max particles for weather
  final Random _random = Random();

  String _currentTheme = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() => _updateAnimation())
      ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stars.isEmpty && _particles.isEmpty) {
      _initializeParticles();
    }
  }

  void _initializeParticles() {
    final size = MediaQuery.of(context).size;

    // Init Stars
    for (int i = 0; i < _starCount; i++) {
      _stars.add(Star(
        x: _random.nextDouble() * size.width,
        y: _random.nextDouble() * size.height,
        maxOpacity: 0.3 + _random.nextDouble() * 0.7,
      ));
    }

    // Init Weather Particles (re-used for Rain, Snow, Leaves)
    List<Color> leafColors = [
      Colors.orange.withValues(alpha: 0.8),
      Colors.redAccent.withValues(alpha: 0.8),
      Colors.brown.withValues(alpha: 0.7),
      Colors.yellow.shade700.withValues(alpha: 0.8)
    ];

    for (int i = 0; i < _particleCount; i++) {
      _particles.add(WeatherParticle(
        x: _random.nextDouble() * size.width,
        y: _random.nextDouble() * size.height,
        speed: 1.0 + _random.nextDouble() * 2.0,
        size: 2.0 + _random.nextDouble() * 4.0,
        drift: _random.nextDouble() * 2 * pi, // Random starting phase for sway
        color: leafColors[_random.nextInt(leafColors.length)], // Only used for leaves
      ));
    }
  }

  void _updateAnimation() {
    final theme = appThemeNotifier.value;
    if (theme == 'dark_none' || theme == 'light') return; // Nothing to animate

    bool needsRepaint = false;
    final size = MediaQuery.of(context).size;

    if (theme == 'dark_starry') {
      for (var star in _stars) {
        if (star.state == 0) {
          if (_random.nextDouble() < 0.01) { star.state = 1; needsRepaint = true; }
        } else if (star.state == 1) {
          star.currentOpacity += 0.015;
          if (star.currentOpacity >= star.maxOpacity) star.state = 2;
          needsRepaint = true;
        } else if (star.state == 2) {
          star.currentOpacity -= 0.010;
          if (star.currentOpacity <= 0) { star.currentOpacity = 0; star.state = 0; }
          needsRepaint = true;
        }
      }
    } else {
      // It's Rain, Snow, or Leaves
      for (var p in _particles) {
        if (theme == 'dark_rain') {
          p.y += p.speed * 6; // Fast fall
          p.x += p.speed * 0.5; // Slight slant
        } else if (theme == 'dark_snow') {
          p.y += p.speed * 1.2; // Slow fall
          p.x += sin(p.y * 0.015 + p.drift) * 1.5; // Gentle sway
        } else if (theme == 'dark_leaves') {
          p.y += p.speed * 1; // Medium fall
          p.x += sin(p.y * 0.02 + p.drift) * 3.0; // Wide sway
        }

        // Reset to top if they fall off screen
        if (p.y > size.height) {
          p.y = -20;
          p.x = _random.nextDouble() * size.width;
        }
        // Wrap around horizontally
        if (p.x > size.width) p.x = 0;
        if (p.x < 0) p.x = size.width;

        needsRepaint = true;
      }
    }

    if (needsRepaint) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
        valueListenable: appThemeNotifier,
        builder: (context, themeStr, child) {
          bool isLight = themeStr == 'light';

          return Stack(
            children: [
              // 1. Base Background
              Container(
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF0F4F8) : null,
                  gradient: isLight ? null : const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF000000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // 2. Stars
              if (themeStr == 'dark_starry')
                CustomPaint(size: Size.infinite, painter: StarPainter(_stars)),

              // 3. Weather Particles (Rain, Snow, Leaves)
              if (themeStr == 'dark_rain' || themeStr == 'dark_snow' || themeStr == 'dark_leaves')
                CustomPaint(
                  size: Size.infinite,
                  painter: WeatherPainter(_particles, themeStr),
                ),

              // 4. Page Content
              widget.child,
            ],
          );
        }
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
        canvas.drawCircle(Offset(star.x, star.y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WeatherPainter extends CustomPainter {
  final List<WeatherParticle> particles;
  final String theme;
  WeatherPainter(this.particles, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var p in particles) {
      if (theme == 'dark_rain') {
        // Draw slanted lines for rain
        paint.color = Colors.white.withValues(alpha: 0.5);
        paint.strokeWidth = 1.5;
        canvas.drawLine(Offset(p.x, p.y), Offset(p.x - p.speed * 0.5, p.y - p.speed * 4), paint);
      }
      else if (theme == 'dark_snow') {
        // Draw soft white circles for snow
        paint.color = Colors.white.withValues(alpha: 0.8);
        canvas.drawCircle(Offset(p.x, p.y), p.size * 0.6, paint);
      }
      else if (theme == 'dark_leaves') {
        // Draw little rotating ovals for leaves
        paint.color = p.color;
        canvas.save();
        canvas.translate(p.x, p.y);
        canvas.rotate(p.y * 0.05 + p.drift); // Rotate based on fall distance
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: p.size * 1.5, height: p.size * 2.5), paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}