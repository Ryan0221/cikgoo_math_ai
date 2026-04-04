import 'package:flutter/material.dart';

// ==========================================
// 1. DATA MODELS (Replace with Firebase later)
// ==========================================
class QuizOption {
  final String id; // e.g., "A", "B", "C", "D"
  final String text;
  final String? optionPicUrl;

  QuizOption({required this.id, required this.text, this.optionPicUrl});
}

class QuizQuestion {
  final String questionText;
  final String? questionPicUrl;
  final List<QuizOption> options;
  final String correctAnswerId;
  final String? explanation;

  QuizQuestion({
    required this.questionText,
    this.questionPicUrl,
    required this.options,
    required this.correctAnswerId,
    this.explanation,
  });

  // THE MAGIC CHECKER: Returns true if ANY option has a picture
  bool get hasPictureOptions {
    return options.any(
      (opt) => opt.optionPicUrl != null && opt.optionPicUrl!.isNotEmpty,
    );
  }
}

// ==========================================
// 2. THE MAIN QUIZ SCREEN
// ==========================================
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // --- Dummy Data (Simulating your Firestore Database) ---
  final List<QuizQuestion> _questions = [
    // Question 1: TEXT ONLY (Will use List Layout)
    QuizQuestion(
      questionText: "Solve for x in the equation: 2x = 4",
      correctAnswerId: "B",
      options: [
        QuizOption(id: "A", text: "x = 1"),
        QuizOption(id: "B", text: "x = 2"),
        QuizOption(id: "C", text: "x = 3"),
        QuizOption(id: "D", text: "x = 4"),
      ],
      explanation: "Divide both sides by 2 to get x = 2.",
    ),
    // Question 2: PICTURE OPTIONS (Will use Grid Layout)
    QuizQuestion(
      questionText: "Which of the following graphs represents y = x?",
      correctAnswerId: "A",
      options: [
        // Using sample placeholder image URLs for demonstration
        QuizOption(
          id: "A",
          text: "Graph A",
          optionPicUrl:
              "https://via.placeholder.com/150/00FF00/000000?text=Graph+A",
        ),
        QuizOption(
          id: "B",
          text: "Graph B",
          optionPicUrl:
              "https://via.placeholder.com/150/FF0000/FFFFFF?text=Graph+B",
        ),
        QuizOption(
          id: "C",
          text: "Graph C",
          optionPicUrl:
              "https://via.placeholder.com/150/0000FF/FFFFFF?text=Graph+C",
        ),
        QuizOption(
          id: "D",
          text: "Graph D",
          optionPicUrl:
              "https://via.placeholder.com/150/FFFF00/000000?text=Graph+D",
        ),
      ],
    ),
    QuizQuestion(
      questionText: "What is the name of the angle shown in this image?",
      // 👇 THIS LINE ADDS THE PICTURE TO THE QUESTION! 👇
      questionPicUrl:
          "https://via.placeholder.com/400x200/223257/FFFFFF?text=Pretend+this+is+a+90+degree+angle",
      correctAnswerId: "C",
      options: [
        QuizOption(id: "A", text: "Acute Angle"),
        QuizOption(id: "B", text: "Obtuse Angle"),
        QuizOption(id: "C", text: "Right Angle"),
        QuizOption(id: "D", text: "Straight Angle"),
      ],
      explanation:
          "An angle that measures exactly 90 degrees is a Right Angle.",
    ),
  ];

  int _currentIndex = 0;
  String? _selectedOptionId;
  bool _hasSubmitted = false;

  void _submitAnswer() {
    if (_selectedOptionId == null) return;
    setState(() {
      _hasSubmitted = true;
      // TODO: Save result to 'quiz_attempts' database here
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionId = null;
        _hasSubmitted = false;
      });
    } else {
      // Quiz Finished!
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Quiz Completed!")));
      Navigator.pop(context); // Go back to home screen
    }
  }

  // Displays the temporary message at the bottom of the screen
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2), // Disappears quickly
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Opens the Report Pop-up Window
  void _showReportDialog() {
    final TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.report_problem_outlined, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Report Question"),
            ],
          ),
          content: TextField(
            controller: reportController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  "What is wrong with this question? (e.g. Typo, wrong answer, bad image)",
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF223257),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // TODO: Save 'reportController.text' to Firestore admin database
                Navigator.pop(context); // Close the dialog
                _showSnackBar(
                  "Report submitted to Admin. Thank you!",
                ); // Show success message
              },
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Small helper to build the icons neatly
  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, color: Colors.grey[600], size: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Question ${_currentIndex + 1} of ${_questions.length}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. QUESTION SECTION ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The Question Text takes up available space
                        Expanded(
                          child: Text(
                            currentQ.questionText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // The 4 Icons pushed to the right
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionIcon(
                              Icons.lightbulb_outline,
                              () => _showSnackBar(
                                "Hint: Try dividing both sides first!",
                              ),
                            ),
                            _buildActionIcon(
                              Icons.bookmark_border,
                              () =>
                                  _showSnackBar("Question saved to bookmarks."),
                            ),
                            _buildActionIcon(
                              Icons.language,
                              () => _showSnackBar("Translated to Malay."),
                            ),
                            _buildActionIcon(
                              Icons.report_problem_outlined,
                              _showReportDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Optional Question Picture
                    if (currentQ.questionPicUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(currentQ.questionPicUrl!),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // --- 2. DYNAMIC OPTIONS SECTION ---
                    // This is where the magic layout switch happens!
                    currentQ.hasPictureOptions
                        ? _buildGridLayout(currentQ)
                        : _buildListLayout(currentQ),

                    // --- 3. EXPLANATION (Only shows after submission) ---
                    if (_hasSubmitted && currentQ.explanation != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          "💡 Explanation: ${currentQ.explanation}",
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // --- 4. BOTTOM BUTTON ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedOptionId == null
                        ? Colors.grey[300]
                        : const Color(0xFF223257),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _selectedOptionId == null
                      ? null
                      : (_hasSubmitted ? _nextQuestion : _submitAnswer),
                  child: Text(
                    _hasSubmitted ? "Next Question" : "Submit Answer",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _selectedOptionId == null
                          ? Colors.grey[600]
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LAYOUT A: TEXT ONLY (List View)
  // ==========================================
  Widget _buildListLayout(QuizQuestion question) {
    return Column(
      children: question.options.map((option) {
        bool isSelected = _selectedOptionId == option.id;
        bool isCorrect = option.id == question.correctAnswerId;

        // Define colors based on submission state
        Color borderColor = Colors.grey[300]!;
        Color bgColor = Colors.white;

        if (_hasSubmitted) {
          if (isCorrect) {
            borderColor = Colors.green;
            bgColor = Colors.green.withOpacity(0.1);
          } else if (isSelected && !isCorrect) {
            borderColor = Colors.red;
            bgColor = Colors.red.withOpacity(0.1);
          }
        } else if (isSelected) {
          borderColor = const Color(0xFF223257);
          bgColor = const Color(0xFF223257).withOpacity(0.05);
        }

        return GestureDetector(
          onTap: _hasSubmitted
              ? null
              : () {
                  setState(() => _selectedOptionId = option.id);
                },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _hasSubmitted && isCorrect
                        ? Colors.green
                        : (isSelected && !_hasSubmitted
                              ? const Color(0xFF223257)
                              : Colors.grey[200]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      option.id,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (isSelected || (_hasSubmitted && isCorrect))
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    option.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_hasSubmitted && isCorrect)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (_hasSubmitted && isSelected && !isCorrect)
                  const Icon(Icons.cancel, color: Colors.red),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // LAYOUT B: PICTURE OPTIONS (Grid View)
  // ==========================================
  Widget _buildGridLayout(QuizQuestion question) {
    return GridView.builder(
      shrinkWrap:
          true, // Required when putting GridView inside a ScrollView/Column
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85, // Adjust this to make cards taller or shorter
      ),
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        bool isSelected = _selectedOptionId == option.id;
        bool isCorrect = option.id == question.correctAnswerId;

        // Define colors based on submission state
        Color borderColor = Colors.grey[300]!;
        Color bgColor = Colors.white;

        if (_hasSubmitted) {
          if (isCorrect) {
            borderColor = Colors.green;
            bgColor = Colors.green.withOpacity(0.1);
          } else if (isSelected && !isCorrect) {
            borderColor = Colors.red;
            bgColor = Colors.red.withOpacity(0.1);
          }
        } else if (isSelected) {
          borderColor = const Color(0xFF223257);
          bgColor = const Color(0xFF223257).withOpacity(0.05);
        }

        return GestureDetector(
          onTap: _hasSubmitted
              ? null
              : () {
                  setState(() => _selectedOptionId = option.id);
                },
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Display the Image
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                    child: option.optionPicUrl != null
                        ? Image.network(option.optionPicUrl!, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          ),
                  ),
                ),
                // Display the Text Label underneath the image
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${option.id}: ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          option.text,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_hasSubmitted && isCorrect)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                      if (_hasSubmitted && isSelected && !isCorrect)
                        const Icon(Icons.cancel, color: Colors.red, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
