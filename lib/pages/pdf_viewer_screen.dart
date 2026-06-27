import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'adaptive_quiz_screen.dart'; // Import your new quiz screen

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String title;
  final List<dynamic> questions; // Added to pass to the quiz

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    required this.title,
    required this.questions,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  // Controls the visibility of our swipe instruction overlay
  bool _showHintOverlay = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          // The PDF takes up the majority of the screen
          Expanded(
            child: Stack(
              children: [
                // 1. THE PDF VIEWER
                SfPdfViewer.asset(
                  widget.pdfPath,
                  // THIS is the magic line that changes it from vertical scrolling to horizontal swiping!
                  pageLayoutMode: PdfPageLayoutMode.single,
                ),

                // 2. THE INSTRUCTION OVERLAY
                if (_showHintOverlay)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showHintOverlay = false;
                        });
                      },
                      child: Container(
                        color: Colors.black.withOpacity(0.7),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                  Icons.swipe,
                                  color: Colors.white,
                                  size: 80
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Swipe left and right\nto change pages",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 40),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30)
                                    )
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showHintOverlay = false;
                                  });
                                },
                                child: const Text(
                                    "Got it!",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Proceed to Quiz Button docked at the bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -3))
                ]
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: () {
                // Use pushReplacement so when they finish the quiz, it goes back to the map, not the PDF
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => AdaptiveQuizScreen(questions: widget.questions)),
                );
              },
              child: const Text(
                "Proceed to Quiz",
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}