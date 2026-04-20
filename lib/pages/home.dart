import 'dart:convert';
import 'dart:ui';
import 'package:cikgoo_math_ai/pages/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'adaptive_quiz_screen.dart';
import 'quiz_screen.dart';

// --- 1. DATA MODELS FOR JSON ---
class SubjectModel {
  final String subjectId;
  final String subjectName;
  final List<ChapterModel> sequences;

  SubjectModel({required this.subjectId, required this.subjectName, required this.sequences});

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      subjectId: json['subject_id'],
      subjectName: json['subject_name'],
      sequences: (json['sequences'] as List)
          .map((seq) => ChapterModel.fromJson(seq))
          .toList(),
    );
  }
}

class ChapterModel {
  final int chapterNum;
  final String chId;
  final String chName;
  final String chFileLocation; // Add this line
  final List<SubtopicModel> subtopics;

  ChapterModel({required this.chapterNum, required this.chId, required this.chName, required this.chFileLocation, required this.subtopics});

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      chapterNum: json['chapter_num'],
      chId: json['ch_id'],
      // Fallback to empty string if ch_name is missing (like in your Form 5 example)
      chName: json['ch_name'] ?? '',
      chFileLocation: json['ch_file_location'] ?? '',
      subtopics: (json['subtopics'] as List)
          .map((sub) => SubtopicModel.fromJson(sub))
          .toList(),
    );
  }
}

class SubtopicModel {
  final String subId;
  final String subName;
  final String type; // "quiz" or "revision"
  final int order;

  SubtopicModel({required this.subId, required this.subName, required this.type, required this.order});

  factory SubtopicModel.fromJson(Map<String, dynamic> json) {
    return SubtopicModel(
      subId: json['sub_id'],
      subName: json['sub_name'],
      type: json['type'],
      order: json['order'],
    );
  }
}

// A helper class to flatten the nodes for easy UI rendering
class FlattenedNode {
  final SubtopicModel subtopic;
  final ChapterModel chapter;
  FlattenedNode(this.subtopic, this.chapter);
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final double nodeHeight = 120.0;

  List<SubjectModel> _allSubjects = [];
  SubjectModel? _selectedSubject;
  List<FlattenedNode> _currentNodes = [];
  List<double> _randomOffsets = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjectData();
  }

  // Reads the JSON file and prepares the initial state
  Future<void> _loadSubjectData() async {
    try {
      // Ensure you have "assets/json/subject-topic.json" declared in pubspec.yaml
      String jsonString = await rootBundle.loadString('assets/json/subject-topic.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      List<SubjectModel> loadedSubjects = (jsonData['subjects'] as List)
          .map((sub) => SubjectModel.fromJson(sub))
          .toList();

      if (loadedSubjects.isNotEmpty) {
        setState(() {
          _allSubjects = loadedSubjects;
          _isLoading = false;
        });
        // Select the first subject by default
        _selectSubject(loadedSubjects.first);
      }
    } catch (e) {
      debugPrint("Error loading JSON: $e");
      setState(() => _isLoading = false);
    }
  }

  // Updates the UI when a new subject is picked
  void _selectSubject(SubjectModel subject) {
    setState(() {
      _selectedSubject = subject;
      _currentNodes.clear();

      // Flatten the chapters and subtopics into a single list
      for (var chapter in subject.sequences) {
        for (var subtopic in chapter.subtopics) {
          _currentNodes.add(FlattenedNode(subtopic, chapter));
        }
      }

      // Generate new random offsets for the new path
      final random = Random();
      _randomOffsets = List.generate(_currentNodes.length,
              (index) => (random.nextDouble() * 1.2) - 0.6
      );
    });
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
                  "Select Subject",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                // Dynamically build the list based on the JSON
                ..._allSubjects.map((subject) {
                  return ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: Text(subject.subjectName),
                    onTap: () {
                      _selectSubject(subject);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_selectedSubject == null || _currentNodes.isEmpty) {
      return const Scaffold(body: Center(child: Text("Coming Soon")));
    }

    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    List<Widget> positionedWidgets = [];
    List<Offset> nodePositions = [];

    double currentY = 20.0;
    String? currentChapterId;

    for (int i = 0; i < _currentNodes.length; i++) {
      final flattenedNode = _currentNodes[i];
      final chapter = flattenedNode.chapter;
      final subtopic = flattenedNode.subtopic;

      // 1. ADD CHAPTER DIVIDER (If it's a new chapter)
      if (chapter.chId != currentChapterId) {
        currentY += 40;
        // Format: Chapter 1: Fungsi dan Persamaan...
        String chapterTitle = "Chapter ${chapter.chapterNum}";
        if (chapter.chName.isNotEmpty) {
          chapterTitle += ": ${chapter.chName}";
        }

        positionedWidgets.add(
            Positioned(
              top: currentY,
              left: 0,
              right: 0,
              child: _buildChapterDivider(chapterTitle),
            )
        );
        currentY += 60;
        currentChapterId = chapter.chId;
      } else {
        currentY += nodeHeight;
      }

      // 2. CALCULATE EXACT NODE POSITION
      double xPos = (_randomOffsets[i] + 1) / 2 * screenWidth;
      // Clamp to prevent the node from touching the absolute screen edges
      xPos = xPos.clamp(70.0, screenWidth - 70.0);

      // Store the exact center point for the PathPainter
      nodePositions.add(Offset(xPos, currentY));

      // 3. BUILD NODE WITH TEXT LABEL
      bool isRightSide = xPos > screenWidth / 2;

      // Calculate the absolute maximum width the text can take without hitting the edge of the screen
      // 35 is half the node width. 24 is padding (12 for icon gap + 12 for screen edge).
      double maxTextWidth = isRightSide
          ? (xPos - 35 - 24)
          : (screenWidth - xPos - 35 - 24);

      positionedWidgets.add(
        Positioned(
          top: currentY - 35,
          left: isRightSide ? null : xPos - 35,
          right: isRightSide ? (screenWidth - xPos - 35) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            // Aligns multiline text with the icon center
            children: [
              if (isRightSide) ...[
                // Wrap text in SizedBox to force wrapping
                SizedBox(
                    width: maxTextWidth,
                    child: Text(
                      subtopic.subName,
                      textAlign: TextAlign.right, // Align text towards the node
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white),
                      softWrap: true,
                    )
                ),
                const SizedBox(width: 12),
              ],

              _buildPathNodeIcon(subtopic, chapter),

              if (!isRightSide) ...[
                const SizedBox(width: 12),
                // Wrap text in SizedBox to force wrapping
                SizedBox(
                    width: maxTextWidth,
                    child: Text(
                      subtopic.subName,
                      textAlign: TextAlign.left, // Align text towards the node
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white),
                      softWrap: true,
                    )
                ),
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
                    height: currentY + 150,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: PathPainter(points: nodePositions),
                          ),
                        ),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                // Display the selected subject name dynamically
                Text(
                  _selectedSubject?.subjectName ?? "Loading...",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildChapterDivider(String chapterName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Expanded(child: DashedDivider()),

          // Wrap the text in a Flexible widget to prevent overflow and allow multi-line!
          Flexible(
            flex: 2, // Gives the text slightly more priority/space than the dashes
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                chapterName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color is white
                ),
                textAlign: TextAlign.center,
                softWrap: true, // Allows it to drop to the next line
              ),
            ),
          ),

          const Expanded(child: DashedDivider()),
        ],
      ),
    );
  }

  Widget _buildPathNodeIcon(SubtopicModel subtopic, ChapterModel chapter) {
    bool isRevision = subtopic.type == 'revision';

    return GestureDetector(
      onTap: () async {
        try {
          // 1. Load the specific chapter file dynamically (e.g., assets/json/f4c1.json)
          String jsonStr = await rootBundle.loadString(chapter.chFileLocation);
          Map<String, dynamic> data = json.decode(jsonStr);

          // 2. Find the specific subtopic data
          var subList = data['subtopics'] as List;
          var subData = subList.firstWhere((s) => s['sub_id'] == subtopic.subId, orElse: () => null);

          if (subData != null) {
            // THIS is the variable that extracts the "q" list from your JSON!
            List<dynamic> qList = subData['q'] ?? [];

            if (isRevision) {
              // Directly launch the Adaptive Quiz
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AdaptiveQuizScreen(questions: qList)
              ));
            } else {
              // Launch the PDF Viewer
              String notesLoc = subData['notes_location'] ?? '';
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    pdfPath: notesLoc,
                    title: subtopic.subName,
                    questions: qList, // We pass the qList variable here!
                  )
              ));
            }
          } else {
            debugPrint("Subtopic not found in file");
          }
        } catch (e) {
          debugPrint("Error loading chapter file: $e");
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
          isRevision ? Icons.menu_book_outlined : Icons.assignment,
          color: Colors.white,
          size: 35,
        ),
      ),
    );
  }
}

// --- DASHED DIVIDER & PAINTER CLASSES ---
class PathPainter extends CustomPainter {
  final List<Offset> points;

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

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashHeight = 3.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();

        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white70),
              ),
            );
          }),
        );
      },
    );
  }
}

/*class PdfViewerScreen extends StatelessWidget {
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
*/
