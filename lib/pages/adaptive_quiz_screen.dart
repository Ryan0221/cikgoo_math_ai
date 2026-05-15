import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  late final GenerativeModel _generativeModel;
  ChatSession? _chatSession;

  @override
  void initState() {
    super.initState();
    _organizeQuestions();
    _startLevel(2); // Always start with level 2

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    // Initialize the Gemini Model
    _generativeModel = GenerativeModel(
        model: 'gemini-2.5-flash', // Recommended for fast text chat
        apiKey: apiKey, // DO NOT hardcode this in production, use flutter_dotenv!

        // 1. SET THE TEMPLATE (System Instruction)
        systemInstruction: Content.system(
            'You are the Cikgoo Math AI, an encouraging and brilliant math tutor. '
                'Your goal is to help students understand mathematical concepts. '
                'Do not just give the direct answer. Instead, ask guiding questions to help '
                'the student figure it out themselves. Keep your answers concise, friendly, '
                'and formatted clearly.'
        ),

        // 2. SET THE LIMITS (Generation Config)
      generationConfig: GenerationConfig(
        maxOutputTokens: 150,
        temperature: 0.4,
      ),
    );
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

  // --- AI DISCUSSION POPUP (NEW) ---
  void _showAIDiscussionPopup(dynamic currentQ) {
    final TextEditingController chatController = TextEditingController();
    bool isTyping = false; // To show a loading indicator

    // 3. INITIALIZE THE CHAT HISTORY
    // We start the chat session here so it knows WHICH question we are discussing
    String initialGreeting = "Hi there! I see you are looking at the question:\n\n\"${currentQ['text']}\"\n\nWhat would you like to discuss or need help understanding?";

    _chatSession = _generativeModel.startChat(history: [
      // Give the AI the hidden context of what the user is looking at
      Content.text('The user is currently looking at this math question: ${currentQ['text']}. The correct answer is ${currentQ['ans']}.'),
      Content.model([TextPart(initialGreeting)])
    ]);

    List<Map<String, String>> messages = [
      {"sender": "AI", "text": initialGreeting}
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {

            // 4. THE FUNCTION TO TALK TO GEMINI
            Future<void> sendMessage() async {
              if (chatController.text.trim().isEmpty) return;

              String userText = chatController.text.trim();
              chatController.clear();

              setModalState(() {
                messages.add({"sender": "User", "text": userText});
                isTyping = true; // Start loading
              });

              try {
                // 1. Add an empty AI message to the list immediately
                int aiMessageIndex = messages.length;
                setModalState(() {
                  messages.add({"sender": "AI", "text": ""});
                  isTyping = false; // Turn off the circular loader, text is about to stream!
                });

                // 2. Call the STREAMING method instead of the standard sendMessage
                final stream = _chatSession!.sendMessageStream(Content.text(userText));

                // 3. Listen to the stream and update the UI chunk-by-chunk
                await for (final chunk in stream) {
                  if (context.mounted) {
                    setModalState(() {
                      messages[aiMessageIndex]["text"] =
                          (messages[aiMessageIndex]["text"] ?? "") + (chunk.text ?? "");
                    });
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  setModalState(() {
                    // If an error happens, append it or replace the empty text
                    messages.add({"sender": "AI", "text": "Error connecting to Gemini AI chatbot. Please check your connection."});
                    isTyping = false;
                  });
                }
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  // --- Header ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Color(0xFF223257)),
                            SizedBox(width: 10),
                            Text("Discuss with AI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),

                  // --- Chat Messages Area ---
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: messages.length + (isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show a loading indicator if AI is typing
                        if (index == messages.length && isTyping) {
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        bool isUser = messages[index]["sender"] == "User";
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF223257) : Colors.blue[50],
                              borderRadius: BorderRadius.circular(15).copyWith(
                                bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(15),
                                bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(15),
                              ),
                            ),
                            child: Text(
                              messages[index]["text"]!,
                              style: TextStyle(
                                fontSize: 15,
                                color: isUser ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // --- Input Area ---
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 15,
                      left: 15,
                      right: 15,
                      top: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: chatController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => sendMessage(),
                            decoration: InputDecoration(
                              hintText: "Ask something...",
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFF223257),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: isTyping ? null : sendMessage,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
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
                    if (_hasSubmitted) ...[
                      if (currentQ['explanation'] != null) ...[
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
                      const SizedBox(height: 15),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAIDiscussionPopup(currentQ),
                          icon: const Icon(Icons.auto_awesome, color: Color(0xFF223257)),
                          label: const Text(
                            "Discuss further with AI",
                            style: TextStyle(color: Color(0xFF223257), fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF223257)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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