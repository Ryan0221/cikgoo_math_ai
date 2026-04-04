import 'dart:ui'; // Required for BackdropFilter
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
    // Generate a random X offset (-0.6 to 0.6) for each node once
    final random = Random();
    randomOffsets = List.generate(nodes.length,
            (index) => (random.nextDouble() * 1.2) - 0.6
    );
  }

  void _showMenuPopup() {
    showDialog(
      context: context,
      barrierDismissible: true, // This allows tapping anywhere blank to close
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Shrinks pop-up to fit content
              children: [
                const Text(
                  "Menu",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                // Dummy Menu Items
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text("Profile"),
                  onTap: () => Navigator.pop(context), // Closes pop-up on tap
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text("Settings"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text("Help & Support"),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Required so the scrollable content shows behind the floating bar
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
                  height: nodes.length * nodeHeight + 120, // Added padding for the floating bar
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PathPainter(nodes: nodes, nodeHeight: nodeHeight, offsets: randomOffsets),
                        ),
                      ),
                      ...List.generate(nodes.length, (index) {
                        final node = nodes[index];
                        // Calculate X position using our randomOffsets list instead of node.alignX
                        double xPos = (randomOffsets[index] + 1) / 2 * MediaQuery.of(context).size.width - 35;

                        return Positioned(
                          top: index * nodeHeight + (nodeHeight / 2) - 35,
                          left: xPos,
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10), // Adjusted for button alignment
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
          const SizedBox(width: 0),
          // LEFT COLUMN: Menu Icon
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87, size: 50),
            onPressed: _showMenuPopup,
          ),
          const SizedBox(width: 0),
          // RIGHT COLUMN: Original Items
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Mathematics SPM Form 4",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 0),
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

  Widget _buildPathNode(CourseNode node) {
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


// Copy the PathPainter and dummy screens as well to ensure it compiles
class PathPainter extends CustomPainter {
  final List<CourseNode> nodes;
  final double nodeHeight;
  final List<double> offsets;

  PathPainter({required this.nodes, required this.nodeHeight, required this.offsets});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length - 1; i++) {
    double x1 = (offsets[i] + 1) / 2 * size.width;
    double y1 = i * nodeHeight + (nodeHeight / 2);

    double x2 = (offsets[i + 1] + 1) / 2 * size.width;
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