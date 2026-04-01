import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cikgoo_math_ai/models/course_node.dart';
import 'package:cikgoo_math_ai/data/course_data.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  // Define your path here. Adjust alignX to stagger them left/right.
  final List<CourseNode> nodes = CourseData.levelOnePath;

  final double nodeHeight = 120.0; // Vertical space between each node

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCDCDC), // Light grey background
      body: SafeArea(
        child: Column(
          children: [
            // --- STICKY HEADER ---
            _buildStickyHeader(),

            // --- SCROLLABLE PATH ---
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  // Total height = number of nodes * height per node
                  height: nodes.length * nodeHeight + 50,
                  child: Stack(
                    children: [
                      // 1. Background layer: Draws the dashed lines
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PathPainter(nodes: nodes, nodeHeight: nodeHeight),
                        ),
                      ),

                      // 2. Foreground layer: Places the clickable icons
                      ...List.generate(nodes.length, (index) {
                        final node = nodes[index];
                        return Positioned(
                          top: index * nodeHeight + (nodeHeight / 2) - 35, // 35 is half the icon height
                          // Math to convert alignX (-1 to 1) to screen coordinates
                          left: (node.alignX + 1) / 2 * MediaQuery.of(context).size.width - 35,
                          child: _buildPathNode(node),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[600],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Test'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Bookmark'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildStickyHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCDCDC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Current Progress: From 4",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 1.0, // 100%
                    minHeight: 10,
                    backgroundColor: Colors.grey[400],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text("100%", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPathNode(CourseNode node) {
    return GestureDetector(
      onTap: () {
        if (node.isRevision) {
          // It's a Paper Icon -> Go straight to Quiz
          Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()));
        } else {
          // It's a Book Icon -> Go to PDF Viewer
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfViewerScreen()));
        }
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black87, width: 1.5),
        ),
        child: Icon(
          node.isRevision ? Icons.description_outlined : Icons.menu_book_outlined,
          color: Colors.white,
          size: 35,
        ),
      ),
    );
  }
}

// --- 2. CUSTOM PAINTER FOR DASHED LINES ---
class PathPainter extends CustomPainter {
  final List<CourseNode> nodes;
  final double nodeHeight;

  PathPainter({required this.nodes, required this.nodeHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length - 1; i++) {
      // Calculate center points of current node and next node
      double x1 = (nodes[i].alignX + 1) / 2 * size.width;
      double y1 = i * nodeHeight + (nodeHeight / 2);

      double x2 = (nodes[i + 1].alignX + 1) / 2 * size.width;
      double y2 = (i + 1) * nodeHeight + (nodeHeight / 2);

      _drawDashedLine(canvas, Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const int dashWidth = 8;
    const int dashSpace = 6;
    double startX = p1.dx;
    double startY = p1.dy;

    // Calculate distance and direction
    double distance = (p2 - p1).distance;
    double dx = (p2.dx - p1.dx) / distance;
    double dy = (p2.dy - p1.dy) / distance;

    double i = 0;
    while (i < distance) {
      double endX = startX + dx * min(dashWidth.toDouble(), distance - i);
      double endY = startY + dy * min(dashWidth.toDouble(), distance - i);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

      startX += dx * (dashWidth + dashSpace);
      startY += dy * (dashWidth + dashSpace);
      i += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- 3. DUMMY SCREENS FOR NAVIGATION ---

class PdfViewerScreen extends StatelessWidget {
  const PdfViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Note Viewer")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            const Text("Imagine a beautiful PDF here!"),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Navigate to Quiz from the PDF screen
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizScreen())
                );
              },
              child: const Text("Next: Take Quiz"),
            )
          ],
        ),
      ),
    );
  }
}

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Time")),
      body: const Center(
        child: Text(
          "Ready for the Quiz?",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}