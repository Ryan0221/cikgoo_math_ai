import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cikgoo_math_ai/models/course_node.dart';
import 'package:cikgoo_math_ai/data/course_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<CourseNode> nodes = CourseData.levelOnePath;
  final double nodeHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Required so the scrollable content shows behind the floating bar
      extendBody: true,
      body: SafeArea(
        // We remove bottom padding from SafeArea so content goes behind the bar
        bottom: false,
        child: Column(
          children: [
            _buildStickyHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: nodes.length * nodeHeight + 120, // Added padding for the floating bar
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PathPainter(nodes: nodes, nodeHeight: nodeHeight),
                        ),
                      ),
                      ...List.generate(nodes.length, (index) {
                        final node = nodes[index];
                        return Positioned(
                          top: index * nodeHeight + (nodeHeight / 2) - 35,
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
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 10, 20), // Adjusted for button alignment
      decoration: BoxDecoration(
        color: const Color(0xFFDCDCDC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row to align title and Sign Out button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Current Progress: From 4",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black87),
                tooltip: 'Sign Out',
                onPressed: () async {
                  // Show confirmation dialog
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Sign Out"),
                      content: const Text("Are you sure you want to log out?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Logout", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await FirebaseAuth.instance.signOut();
                    // The AuthGate in your project will automatically redirect to Login
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 1.0,
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()));
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PdfViewerScreen(
                  // Change this to the exact name of a PDF in your folder!
                  pdfPath: 'assets/notes/note1.1.pdf',
                  title: 'Course Notes', // You can change this to node.name later
                ),
              ),
            );
          }
        },
    );
  }
}

// Copy the PathPainter and dummy screens as well to ensure it compiles
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

class PdfViewerScreen extends StatelessWidget {
  final String pdfPath;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      // This is the magic widget that renders the file!
      body: SfPdfViewer.asset(pdfPath),
    );
  }
}

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text("Quiz Time")));
}
