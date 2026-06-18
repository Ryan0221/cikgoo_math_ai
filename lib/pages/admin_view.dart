import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class ViewContentPanel extends StatefulWidget {
  const ViewContentPanel({Key? key}) : super(key: key);

  @override
  State<ViewContentPanel> createState() => _ViewContentPanelState();
}

class _ViewContentPanelState extends State<ViewContentPanel> {
  bool _isLoadingMap = true;
  List<dynamic> _subjectsList = [];
  String? _selectedSubjectName;
  List<dynamic> _displayedChapters = [];

  @override
  void initState() {
    super.initState();
    _loadMasterSyllabus();
  }

  // 1. Load the main syllabus map
  Future<void> _loadMasterSyllabus() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/subjects-chapters-subtopics.json');

      String jsonString;
      if (await localFile.exists()) {
        jsonString = await localFile.readAsString();
      } else {
        jsonString = await rootBundle.loadString('assets/json/subjects-chapters-subtopics.json');
      }

      Map<String, dynamic> data = json.decode(jsonString);

      setState(() {
        _subjectsList = data['subjects'] ?? [];
        if (_subjectsList.isNotEmpty) {
          _selectedSubjectName = _subjectsList.first['subject_name'];
          _updateChaptersList(_selectedSubjectName!);
        }
        _isLoadingMap = false;
      });
    } catch (e) {
      debugPrint("Error loading syllabus: $e");
      setState(() => _isLoadingMap = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load syllabus data: $e')),
        );
      }
    }
  }

  // 2. Update the chapter list when the dropdown changes
  void _updateChaptersList(String subjectName) {
    var subjectData = _subjectsList.firstWhere(
          (s) => s['subject_name'] == subjectName,
      orElse: () => null,
    );

    if (subjectData != null) {
      setState(() {
        // Handle both variations of the key name safely
        _displayedChapters = subjectData['sequences'] ?? subjectData['chapters'] ?? [];
      });
    }
  }

  // 3. NEW: Fetches the specific chapter file and extracts ONLY the clicked subtopic's questions!
  Future<void> _fetchAndShowSubtopicDetails(Map<String, dynamic> chapter, Map<String, dynamic> targetSubtopic) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String safeFileName = (chapter['ch_file_location'] ?? '').toString().split('/').last;

      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$safeFileName');

      String jsonString;
      if (await localFile.exists()) {
        jsonString = await localFile.readAsString();
      } else {
        jsonString = await rootBundle.loadString('assets/json/$safeFileName');
      }

      Map<String, dynamic> chapterData = json.decode(jsonString);

      // Find the specific subtopic inside the loaded chapter file
      List<dynamic> fileSubtopics = chapterData['subtopics'] as List? ?? [];
      var matchingSubtopic = fileSubtopics.firstWhere(
            (s) => s['sub_id'] == targetSubtopic['sub_id'] || s['sub_name'] == targetSubtopic['sub_name'],
        orElse: () => null,
      );

      List<dynamic> questions = [];
      if (matchingSubtopic != null) {
        questions = matchingSubtopic['q'] as List? ?? [];
      }

      // Close loading spinner
      if (mounted) Navigator.pop(context);

      // Open the actual details dialog with the populated questions
      _showQuestionsDialog(chapter['ch_name'] ?? 'Chapter Details', questions);

    } catch (e) {
      if (mounted) Navigator.pop(context); // Close spinner
      debugPrint("Error loading chapter details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chapter data: $e')),
        );
      }
    }
  }

  // 4. The actual Pop-Up UI for the questions
  void _showQuestionsDialog(String chapterName, List<dynamic> questions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.grey[200],
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        chapterName,
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

                Expanded(
                  child: questions.isEmpty
                      ? const Center(child: Text("No questions found in this chapter."))
                      : ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      final options = q['options'] as List? ?? [];
                      final answer = q['ans'] ?? '';

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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${index + 1}.",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q['text'] ?? 'No text provided',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Dynamically generate the options list
                                  ...options.map((opt) {
                                    bool isCorrect = opt['id'] == answer;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        "• ${opt['id']}: ${opt['text']}",
                                        style: TextStyle(
                                          // Highlight the correct answer in green!
                                          color: isCorrect ? Colors.green : Colors.black87,
                                          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  }).toList(),
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
    if (_isLoadingMap) {
      return const Center(child: CircularProgressIndicator());
    }

    List<String> subjectNames = _subjectsList.map((s) => s['subject_name'].toString()).toList();

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
              value: _selectedSubjectName,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: subjectNames.map((String subject) {
                return DropdownMenuItem<String>(
                  value: subject,
                  child: Text(subject, style: const TextStyle(fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSubjectName = newValue;
                    _updateChaptersList(newValue);
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 20),

          // --- SCROLLABLE CHAPTER & SUBTOPIC LIST ---
          Expanded(
            child: _displayedChapters.isEmpty
                ? const Center(child: Text("No chapters found."))
                : ListView.builder(
              itemCount: _displayedChapters.length,
              itemBuilder: (context, index) {
                final chapter = _displayedChapters[index];
                final subtopicsList = chapter['subtopics'] as List? ?? [];

                // 1. OUTER GREY CONTAINER (THE CHAPTER)
                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Matches the mockup's grey wrapper
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter['ch_name'] ?? 'Unknown Chapter',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. INNER WHITE CONTAINERS (THE SUBTOPICS)
                      ...subtopicsList.map((sub) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white, // Matches the mockup's white cards
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub['sub_name'] ?? 'Unknown Subtopic',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Total Questions logic (Uses the master list if available, or falls back to a string)
                              Text(
                                "• Total No. of Question: ${sub['total_q'] ?? 'N/A'}",
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                              const SizedBox(height: 4),

                              // CLICKABLE TEXT TO LOAD DIALOG
                              InkWell(
                                onTap: () => _fetchAndShowSubtopicDetails(chapter, sub),
                                child: const Text(
                                  "• Click to view the questions",
                                  style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
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