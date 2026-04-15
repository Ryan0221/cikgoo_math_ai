import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cikgoo_math_ai/models/course_node.dart';
import 'package:cikgoo_math_ai/data/course_data.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'quiz_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<CourseNode> nodes = CourseData.levelOnePath;
  final double nodeHeight = 120.0;

  late List<double> randomOffsets;

  @override
  void initState() {
    super.initState();
    final random = Random();
    randomOffsets = List.generate(nodes.length,
            (index) => (random.nextDouble() * 1.2) - 0.6
    );
  }

  void _showMenuPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Menu",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text("Mathematics SPM Form 4"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text("Mathematics SPM Form 5"),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    List<Widget> positionedWidgets = [];
    List<Offset> nodePositions = [];

    double currentY = 20.0; // Starting padding from top
    String? currentChapter;

    // Dynamically calculate positions so we can inject Chapter Dividers
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      // TODO: Replace this simulated logic with your actual Chapter property!
      // (e.g., chapterName = node.chapterName;)
      // Simulating a new chapter every 3 nodes for demonstration:
      String chapterName = "Chapter ${(i ~/ 3) + 1}: Core Concepts";

      // 1. ADD CHAPTER DIVIDER (If it's a new chapter)
      if (chapterName != currentChapter) {
        currentY += 40; // Add breathing room before the line
        positionedWidgets.add(
            Positioned(
              top: currentY,
              left: 0,
              right: 0,
              child: _buildChapterDivider(chapterName),
            )
        );
        currentY += 60; // Add space between the line and the first node
        currentChapter = chapterName;
      } else {
        currentY += nodeHeight; // Normal spacing between nodes
      }

      // 2. CALCULATE EXACT NODE POSITION
      double xPos = (randomOffsets[i] + 1) / 2 * screenWidth;
      // Clamp to prevent the node from touching the absolute screen edges
      xPos = xPos.clamp(70.0, screenWidth - 70.0);

      // Store the exact center point for the PathPainter
      nodePositions.add(Offset(xPos, currentY));

      // 3. BUILD NODE WITH TEXT LABEL
      // If node is on the right side of the screen, place text on the left (and vice versa) to prevent overflow
      bool isRightSide = xPos > screenWidth / 2;

      positionedWidgets.add(
        Positioned(
          top: currentY - 35, // -35 to perfectly center the 70px height node
          left: isRightSide ? null : xPos - 35,
          right: isRightSide ? (screenWidth - xPos - 35) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRightSide) ...[
                // Replace `node.id` with `node.name` if that's what your model uses
                Text(node.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 12),
              ],

              _buildPathNodeIcon(node),

              if (!isRightSide) ...[
                const SizedBox(width: 12),
                Text(node.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildStickyHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  // Dynamic height based on how far down the last element reached
                  height: currentY + 150,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        // PathPainter now accepts explicit X/Y coordinate pairs
                        child: CustomPaint(
                          painter: PathPainter(points: nodePositions),
                        ),
                      ),
                      // Drop in all our calculated nodes and dividers
                      ...positionedWidgets,
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDCDCDC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87, size: 50),
            onPressed: _showMenuPopup,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Mathematics SPM Form 4",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
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
          ),
        ],
      ),
    );
  }

  // Extracted the Chapter Divider UI
  Widget _buildChapterDivider(String chapterName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Expanded(child: DashedDivider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              chapterName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Expanded(child: DashedDivider()),
        ],
      ),
    );
  }

  // Refactored from `_buildPathNode`
  Widget _buildPathNodeIcon(CourseNode node) {
    return GestureDetector(
      onTap: () {
        if (node.isRevision) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const QuizScreen()));
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PdfViewerScreen(
                pdfPath: 'assets/notes/note1.1.pdf',
                title: 'Course Notes',
              ),
            ),
          );
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
          node.isRevision ? Icons.menu_book_outlined : Icons.assignment,
          color: Colors.white,
          size: 35,
        ),
      ),
    );
  }
}

// --- UPDATED PATH PAINTER ---
class PathPainter extends CustomPainter {
  final List<Offset> points; // Now strictly accepts coordinate points

  PathPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      _drawDashedLine(canvas, points[i], points[i + 1], paint);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- NEW DASHED HORIZONTAL DIVIDER ---
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashHeight = 1.5;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();

        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }
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
      body: SfPdfViewer.asset(pdfPath),
    );
  }
}