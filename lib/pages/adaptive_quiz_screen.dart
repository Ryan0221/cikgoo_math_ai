import 'package:flutter/material.dart';

class AdaptiveQuizScreen extends StatefulWidget {
  final List<dynamic> questions;

  const AdaptiveQuizScreen({Key? key, required this.questions}) : super(key: key);

  @override
  State<AdaptiveQuizScreen> createState() => _AdaptiveQuizScreenState();
}

class _AdaptiveQuizScreenState extends State<AdaptiveQuizScreen> {
  // --- ADAPTIVE LOGIC STATE ---
  Map<int, List<dynamic>> questionsByLevel = {1: [], 2: [], 3: [], 4: [], 5: []};
  Set<String> completedQuestionIds = {};

  List<dynamic> currentBlock = [];
  int currentLevel = 2;
  int currentQuestionIndex = 0;
  int correctInCurrentBlock = 0;

  Map<String, dynamic> wrongQuestionsMap = {};
  bool isReviewingWrong = false;

  // --- UI STATE ---
  String? _selectedOptionId;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _organizeQuestions();
    _startLevel(2); // Always start with level 2
  }

  void _organizeQuestions() {
    for (var q in widget.questions) {
      int diff = q['question_difficulty'] ?? 1;
      questionsByLevel[diff]?.add(q);
    }
  }

  void _startLevel(int level) {
    setState(() {
      currentLevel = level;

      // Filter out completed questions using the robust ID
      currentBlock = (questionsByLevel[level] ?? []).where((q) {
        String qId = q['q_id'] ?? q['text'] ?? "unknown_id";
        return !completedQuestionIds.contains(qId);
      }).toList();

      currentQuestionIndex = 0;
      correctInCurrentBlock = 0;
      _selectedOptionId = null;
      _hasSubmitted = false;

      // Failsafe for empty levels
      if (currentBlock.isEmpty && !isReviewingWrong) {
        if (level >= 5) {
          _startReviewPhase();
        } else {
          _handleLevelEnd(true);
        }
      }
    });
  }

  // --- INTERACTION LOGIC ---

  void _submitAnswer(dynamic currentQ) {
    if (_selectedOptionId == null) return;

    String correctId = currentQ['ans'];
    String qId = currentQ['q_id'] ?? currentQ['text'] ?? "unknown_id_$currentQuestionIndex";

    if (_selectedOptionId == correctId) {
      correctInCurrentBlock++;
      wrongQuestionsMap.remove(qId);

      if (!isReviewingWrong) {
        completedQuestionIds.add(qId);
      }
    } else {
      wrongQuestionsMap[qId] = currentQ;
    }

    setState(() {
      _hasSubmitted = true;
    });
  }

  void _nextQuestion() {
    setState(() {
      // 1. EARLY EXIT CHECK: If they already met the threshold, jump to the next level immediately!
      if (!isReviewingWrong && correctInCurrentBlock > (currentBlock.length / 2)) {
        _handleLevelEnd(true);
        return; // Stop running the rest of this method
      }
      // 2. Otherwise, prepare the next question
      currentQuestionIndex++;
      _selectedOptionId = null;
      _hasSubmitted = false;
      // 3. EXHAUSTION CHECK: Check if they ran out of questions in the current block
      if (currentQuestionIndex >= currentBlock.length) {
        if (isReviewingWrong) {
          _handleReviewEnd();
        } else {
          // They finished the level but failed to meet the early exit threshold
          _handleLevelEnd(false);
        }
      }
    });
  }

  void _handleLevelEnd(bool passed) {
    if (currentLevel == 2) {
      if (passed) _startLevel(3);
      else _startLevel(1); // ONLY Level 2 drops down on failure
    }
    else if (currentLevel == 1) {
      _startLevel(2); // Always proceed to 2 after finishing 1
    }
    else if (currentLevel == 3) {
      _startLevel(4); // Always proceed to 4 after finishing 3
    }
    else if (currentLevel == 4) {
      _startLevel(5); // Always proceed to 5 after finishing 4
    }
    else if (currentLevel == 5) {
      _startReviewPhase();
    }
  }

  void _startReviewPhase() {
    if (wrongQuestionsMap.isEmpty) {
      _finishQuiz();
      return;
    }
    setState(() {
      isReviewingWrong = true;
      currentBlock = wrongQuestionsMap.values.toList();
      currentQuestionIndex = 0;
      _selectedOptionId = null;
      _hasSubmitted = false;
    });
  }

  void _handleReviewEnd() {
    if (wrongQuestionsMap.isEmpty) {
      _finishQuiz();
    } else {
      _startReviewPhase();
    }
  }

  void _finishQuiz() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
            title: const Text("Course Node Finished!", style: TextStyle(color: Colors.green)),
            content: const Text("Congratulations! You have completed all requirements and mastered the material."),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text("Return to Map")
              )
            ]
        )
    );
  }

  // --- UI HELPERS ---

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showReportDialog() {
    final TextEditingController reportController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
              hintText: "What is wrong with this question? (e.g. Typo, wrong answer, bad image)",
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showSnackBar("Report submitted to Admin. Thank you!");
              },
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

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

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    if (currentBlock.isEmpty || currentQuestionIndex >= currentBlock.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQ = currentBlock[currentQuestionIndex];
    bool hasPictureOptions = currentQ['options_has_picture'] == true;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(isReviewingWrong
            ? "Reviewing Mistake ${currentQuestionIndex + 1}/${currentBlock.length}"
            : "Level $currentLevel  •  Q ${currentQuestionIndex + 1}/${currentBlock.length}"),
        backgroundColor: isReviewingWrong ? Colors.orange[700] : Colors.white,
        foregroundColor: isReviewingWrong ? Colors.white : Colors.black,
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
                        Expanded(
                          child: Text(
                            currentQ['text'] ?? "",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionIcon(
                              Icons.lightbulb_outline,
                                  () => _showSnackBar("Hint: ${currentQ['hint'] ?? 'No hint available.'}"),
                            ),
                            _buildActionIcon(
                              Icons.bookmark_border,
                                  () => _showSnackBar("Question saved to bookmarks."),
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

                    if (currentQ['question_pic'] != null && currentQ['question_pic'].toString().isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(currentQ['question_pic']),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // --- 2. DYNAMIC OPTIONS SECTION ---
                    hasPictureOptions
                        ? _buildGridLayout(currentQ)
                        : _buildListLayout(currentQ),

                    // --- 3. EXPLANATION ---
                    if (_hasSubmitted && currentQ['explanation'] != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          "💡 Explanation: ${currentQ['explanation']}",
                          style: TextStyle(color: Colors.blue[800], fontSize: 15),
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
                    color: Colors.black.withValues(alpha: .05),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _selectedOptionId == null
                      ? null
                      : (_hasSubmitted ? _nextQuestion : () => _submitAnswer(currentQ)),
                  child: Text(
                    _hasSubmitted ? "Next Question" : "Submit Answer",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _selectedOptionId == null ? Colors.grey[600] : Colors.white,
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
                        : (isSelected && !_hasSubmitted
                        ? const Color(0xFF223257)
                        : Colors.grey[200]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      option['id'],
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
                    option['text'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                        : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${option['id']}: ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          option['text'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_hasSubmitted && isCorrect)
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
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