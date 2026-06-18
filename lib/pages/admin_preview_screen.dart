import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class AdminPreviewScreen extends StatefulWidget {
  final List<dynamic> questions;

  const AdminPreviewScreen({Key? key, required this.questions}) : super(key: key);

  @override
  State<AdminPreviewScreen> createState() => _AdminPreviewScreenState();
}

class _AdminPreviewScreenState extends State<AdminPreviewScreen> {
  int _currentIndex = 0;

  // UI State
  String? _selectedOptionId;
  bool _hasSubmitted = false;

  // NEW: Global toggle for showing answers
  bool _isGlobalShowAnswer = false;

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _resetState();

        // If global show answer is ON, immediately show the answer for the new question
        if (_isGlobalShowAnswer) {
          String newCorrectAns = widget.questions[_currentIndex]['ans'] ?? '';
          _showAnswer(newCorrectAns);
        }
      });
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _resetState();

        // If global show answer is ON, immediately show the answer for the new question
        if (_isGlobalShowAnswer) {
          String newCorrectAns = widget.questions[_currentIndex]['ans'] ?? '';
          _showAnswer(newCorrectAns);
        }
      });
    } else {
      _showSnackBar("This is the first question.");
    }
  }

  void _resetState() {
    _selectedOptionId = null;
    _hasSubmitted = false;
  }

  void _showAnswer(String correctAns) {
    setState(() {
      _selectedOptionId = correctAns; // Forces the UI to select the right answer
      _hasSubmitted = true;           // Forces the UI to show the green highlights and explanation
    });
  }

  // NEW: The Toggle Function
  void _toggleGlobalAnswer(String correctAns) {
    setState(() {
      _isGlobalShowAnswer = !_isGlobalShowAnswer;
      if (_isGlobalShowAnswer) {
        _showAnswer(correctAns);
      } else {
        _resetState();
      }
    });
  }

  void _submitAnswer() {
    if (_selectedOptionId == null) return;
    setState(() {
      _hasSubmitted = true;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // NEW: The Completion Dialog
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Preview Complete", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "You have successfully reviewed all questions in this subtopic.\n\n"
              "Would you like to upload this content now?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Just closes the dialog
            child: const Text("Cancel", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff3dcf00), // Exact Green
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              // Pop the entire preview screen and return 'upload' to admin_add!
              Navigator.pop(context, {'action': 'upload'});
            },
            child: const Text("Complete & Upload", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildMathText(String text) {
    if (!text.contains(r'$')) {
      return Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      );
    }

    List<String> parts = text.split(r'$');
    List<InlineSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      if (i % 2 == 0) {
        spans.add(TextSpan(
          text: parts[i],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ));
      } else {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(
            parts[i],
            mathStyle: MathStyle.text,
            textStyle: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text("Preview Mode")), body: const Center(child: Text("No questions to preview.")));
    }

    final currentQ = widget.questions[_currentIndex];
    bool hasPictureOptions = currentQ['options_has_picture'] == true;
    String correctAnswer = currentQ['ans'] ?? '';
    bool isLastQuestion = _currentIndex == widget.questions.length - 1;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Admin Preview  •  Q ${_currentIndex + 1}/${widget.questions.length}"),
        backgroundColor: const Color(0xFF223257),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildMathText(currentQ['text'] ?? "")),
                        IconButton(icon: const Icon(Icons.lightbulb_outline, color: Colors.grey), onPressed: () => _showSnackBar("Hint: ${currentQ['hint'] ?? 'No hint.'}")),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (currentQ['question_pic'] != null && currentQ['question_pic'].toString().isNotEmpty) ...[
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(currentQ['question_pic'])),
                      const SizedBox(height: 20),
                    ],

                    hasPictureOptions ? _buildGridLayout(currentQ) : _buildListLayout(currentQ),

                    if (_hasSubmitted && currentQ['explanation'] != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue[200]!)),
                        child: Text("💡 Explanation: ${currentQ['explanation']}", style: TextStyle(color: Colors.blue[800], fontSize: 15)),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // --- ADMIN NAVIGATION PANEL ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedOptionId == null ? Colors.grey[300] : const Color(0xFF223257),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _selectedOptionId == null || _hasSubmitted ? null : _submitAnswer,
                      child: Text(
                        "Submit Answer",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedOptionId == null ? Colors.grey[600] : Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // PREVIOUS BUTTON
                      InkWell(
                        onTap: _prevQuestion,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                          child: const Icon(Icons.chevron_left, size: 30, color: Colors.black87),
                        ),
                      ),

                      // EDIT AND SHOW ANSWER BUTTONS
                      Row(
                        children: [
                          // NEW: Edit Button
                          InkWell(
                            onTap: () {
                              // Return to admin_add and tell it exactly which question to jump to
                              Navigator.pop(context, {'action': 'edit', 'index': _currentIndex});
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.orange[100], shape: BoxShape.circle),
                              child: Icon(Icons.edit, size: 24, color: Colors.orange[800]),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // TOGGLE ANSWER BUTTON
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isGlobalShowAnswer ? Colors.grey[600] : Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () => _toggleGlobalAnswer(correctAnswer),
                            icon: Icon(_isGlobalShowAnswer ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                            label: Text(
                                _isGlobalShowAnswer ? "Hide Answer" : "Show Answer",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ],
                      ),

                      // NEXT / COMPLETE BUTTON
                      InkWell(
                        onTap: isLastQuestion ? _showCompletionDialog : _nextQuestion,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          // Turns green on the last question!
                          decoration: BoxDecoration(color: isLastQuestion ? const Color(0xff3dcf00) : Colors.grey[200], shape: BoxShape.circle),
                          child: Icon(
                              isLastQuestion ? Icons.check : Icons.chevron_right,
                              size: 30,
                              color: isLastQuestion ? Colors.white : Colors.black87
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LAYOUT A: TEXT ONLY
  // ==========================================
  Widget _buildListLayout(dynamic question) {
    List<dynamic> options = question['options'] ?? [];
    return Column(
      children: options.map((option) {
        bool isSelected = _selectedOptionId == option['id'];
        bool isCorrect = option['id'] == question['ans'];

        Color borderColor = Colors.grey[300]!;
        Color bgColor = Colors.white;

        if (_hasSubmitted) {
          if (isCorrect) {
            borderColor = Colors.green;
            bgColor = Colors.green.withValues(alpha: 0.1);
          } else if (isSelected && !isCorrect) {
            borderColor = Colors.red;
            bgColor = Colors.red.withValues(alpha: 0.1);
          }
        } else if (isSelected) {
          borderColor = const Color(0xFF223257);
          bgColor = const Color(0xFF223257).withValues(alpha: 0.05);
        }

        return GestureDetector(
          onTap: _hasSubmitted ? null : () {
            setState(() => _selectedOptionId = option['id']);
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
                        : (isSelected && !_hasSubmitted ? const Color(0xFF223257) : Colors.grey[200]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      option['id'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (isSelected || (_hasSubmitted && isCorrect)) ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(option['text'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                if (_hasSubmitted && isCorrect) const Icon(Icons.check_circle, color: Colors.green),
                if (_hasSubmitted && isSelected && !isCorrect) const Icon(Icons.cancel, color: Colors.red),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // LAYOUT B: PICTURE OPTIONS
  // ==========================================
  Widget _buildGridLayout(dynamic question) {
    List<dynamic> options = question['options'] ?? [];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        bool isSelected = _selectedOptionId == option['id'];
        bool isCorrect = option['id'] == question['ans'];

        Color borderColor = Colors.grey[300]!;
        Color bgColor = Colors.white;

        if (_hasSubmitted) {
          if (isCorrect) {
            borderColor = Colors.green;
            bgColor = Colors.green.withValues(alpha: 0.1);
          } else if (isSelected && !isCorrect) {
            borderColor = Colors.red;
            bgColor = Colors.red.withValues(alpha: 0.1);
          }
        } else if (isSelected) {
          borderColor = const Color(0xFF223257);
          bgColor = const Color(0xFF223257).withValues(alpha: 0.05);
        }

        return GestureDetector(
          onTap: _hasSubmitted ? null : () {
            setState(() => _selectedOptionId = option['id']);
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
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    child: option['option_pic'] != null && option['option_pic'].toString().isNotEmpty
                        ? Image.network(option['option_pic'], fit: BoxFit.cover)
                        : Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${option['id']}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(option['text'], overflow: TextOverflow.ellipsis)),
                      if (_hasSubmitted && isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      if (_hasSubmitted && isSelected && !isCorrect) const Icon(Icons.cancel, color: Colors.red, size: 18),
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