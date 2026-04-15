import 'package:flutter/material.dart';

// --- 1. DUMMY DATA MODELS (Simulating Firebase) ---
class QuestionData {
  final String questionText;
  final String option1;
  final String option2;
  final String option3;
  final String option4;

  QuestionData({
    required this.questionText,
    required this.option1,
    required this.option2,
    required this.option3,
    required this.option4,
  });
}

class Chapter {
  final String name;
  final String type;
  final int totalQuestions;
  final List<QuestionData> questions; // Added list of questions

  Chapter({
    required this.name,
    required this.type,
    required this.totalQuestions,
    required this.questions,
  });
}

class ViewContentPanel extends StatefulWidget {
  const ViewContentPanel({Key? key}) : super(key: key);

  @override
  State<ViewContentPanel> createState() => _ViewContentPanelState();
}

class _ViewContentPanelState extends State<ViewContentPanel> {
  // --- 2. DUMMY DATABASE WITH QUESTIONS ---
  final Map<String, List<Chapter>> _firebaseData = {
    'Form 4 Mathematics': [
      Chapter(
        name: 'Chapter 1: Functions',
        type: 'Objective & Subjective',
        totalQuestions: 2, // Mocked to 2 for display
        questions: [
          QuestionData(
            questionText: "What is the inverse of f(x) = 2x + 3?",
            option1: "(x - 3) / 2",
            option2: "2x - 3",
            option3: "(x + 3) / 2",
            option4: "1 / (2x + 3)",
          ),
          QuestionData(
            questionText: "Given g(x) = x^2, find g(3).",
            option1: "6",
            option2: "9",
            option3: "12",
            option4: "3",
          ),
        ],
      ),
      Chapter(
        name: 'Chapter 2: Quadratic Equations',
        type: 'Subjective',
        totalQuestions: 0,
        questions: [],
      ),
    ],
    'Form 5 Physics': [
      Chapter(
        name: 'Chapter 1: Force and Motion II',
        type: 'Objective',
        totalQuestions: 1,
        questions: [
          QuestionData(
            questionText: "What is the formula for Force?",
            option1: "F = ma",
            option2: "F = mv",
            option3: "F = m/a",
            option4: "F = a/m",
          )
        ],
      ),
    ],
  };

  String? _selectedSubjectLevel;
  List<Chapter> _displayedChapters = [];

  @override
  void initState() {
    super.initState();
    _selectedSubjectLevel = _firebaseData.keys.first;
    _displayedChapters = _firebaseData[_selectedSubjectLevel]!;
  }

  void _onSubjectChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedSubjectLevel = newValue;
        _displayedChapters = _firebaseData[newValue] ?? [];
      });
    }
  }

  // --- 3. THE POP-UP DIALOG METHOD ---
  void _showChapterDetails(Chapter chapter) {
    showDialog(
      context: context,
      // barrierDismissible is true by default, meaning clicking outside closes it
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.grey[200], // Matches dashboard theme
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8, // 80% screen width
            height: MediaQuery.of(context).size.height * 0.8, // 80% screen height
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header of the Pop-up
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        chapter.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Scrollable list of questions
                Expanded(
                  child: chapter.questions.isEmpty
                      ? const Center(child: Text("No questions found in this chapter."))
                      : ListView.builder(
                    itemCount: chapter.questions.length,
                    itemBuilder: (context, index) {
                      final questionData = chapter.questions[index];

                      // QUESTION CONTAINER
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        // 2-COLUMN LAYOUT FOR THE QUESTION
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Column 1: The Number
                            Text(
                              "${index + 1}.",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Column 2: Question & Options
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    questionData.questionText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text("• Option 1: ${questionData.option1}"),
                                  const SizedBox(height: 4),
                                  Text("• Option 2: ${questionData.option2}"),
                                  const SizedBox(height: 4),
                                  Text("• Option 3: ${questionData.option3}"),
                                  const SizedBox(height: 4),
                                  Text("• Option 4: ${questionData.option4}"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Subject Level",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSubjectLevel,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _firebaseData.keys.map((String subject) {
                return DropdownMenuItem<String>(
                  value: subject,
                  child: Text(subject, style: const TextStyle(fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: _onSubjectChanged,
            ),
          ),
          const SizedBox(height: 24),

          // --- 4. SCROLLABLE CHAPTER LIST ---
          Expanded(
            child: _displayedChapters.isEmpty
                ? const Center(child: Text("No chapters found."))
                : ListView.builder(
              itemCount: _displayedChapters.length,
              itemBuilder: (context, index) {
                final chapter = _displayedChapters[index];

                // CLICKABLE CHAPTER CARD
                return Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      // THIS TRIGGERS THE POPUP!
                      onTap: () => _showChapterDetails(chapter),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("Type: ${chapter.type}", style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("Total No. of Question: ${chapter.totalQuestions}", style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                            const SizedBox(height: 12),
                            Text(
                                "Tap to expand this chapter",
                                style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}