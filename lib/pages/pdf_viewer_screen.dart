import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'adaptive_quiz_screen.dart'; // Import your new quiz screen

class PdfViewerScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          // The PDF takes up the majority of the screen
          Expanded(
            child: SfPdfViewer.asset(pdfPath),
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
                  MaterialPageRoute(builder: (_) => AdaptiveQuizScreen(questions: questions)),
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