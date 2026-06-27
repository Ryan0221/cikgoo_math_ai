import 'package:flutter/material.dart';
import '../services/theme_manager.dart';


class Bookmark extends StatelessWidget {
  const Bookmark({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data to match your mockup's repeated "Lorem ipsum" blocks.
    // TODO: Later, replace this with a real list fetched from Firestore or SharedPreferences!
    final List<String> dummyBookmarks = List.generate(
        7,
            (index) => "Lorem ipsum dolor sit amet consectetur. Egestas sem maecenas est elementum sit fames quam sollicitudin dis. Dictumst lectus non a enim amet morbi quis fames."
    );

    return ValueListenableBuilder<String>(
        valueListenable: appThemeNotifier,
        builder: (context, themeStr, child) {
          bool isDark = themeStr.startsWith('dark');

          // Adaptive colors so it looks great on both Light and Dark modes
          Color headerColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey[400]!;
          Color cardColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[400]!;
          Color textColor = isDark ? Colors.white : Colors.black87;

          return Scaffold(
            // MUST be transparent so the FirstPage stars/gradient show through!
            backgroundColor: Colors.transparent,

            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // --- 1. TOP HEADER ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: headerColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        "BOOKMARK",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 2. BOOKMARK LIST ---
                    Expanded(
                      child: ListView.builder(
                        // BouncingScrollPhysics gives it that smooth iOS-style scroll feel
                        physics: const BouncingScrollPhysics(),
                        itemCount: dummyBookmarks.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              dummyBookmarks[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                height: 1.3,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Add bottom padding to account for the floating navigation bar
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}