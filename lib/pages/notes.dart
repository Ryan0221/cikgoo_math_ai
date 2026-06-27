import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/content_manager.dart';
import '../services/theme_manager.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  bool _isLoading = true;
  List<dynamic> _subjectsList = [];
  Map<String, dynamic>? _selectedSubject;
  List<dynamic> _chaptersList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Fetch the master syllabus JSON from the secure local storage
      String jsonString = await ContentManager.readLocalJson('subjects-chapters-subtopics.json');
      Map<String, dynamic> data = json.decode(jsonString);

      setState(() {
        _subjectsList = data['subjects'] ?? [];
        if (_subjectsList.isNotEmpty) {
          // 2. Default to the first subject
          _selectedSubject = _subjectsList.first;
          // Support both 'sequences' or 'chapters' array names
          _chaptersList = _selectedSubject!['sequences'] ?? _selectedSubject!['chapters'] ?? [];
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading notes data: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load notes data.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onSubjectChanged(Map<String, dynamic>? newSubject) {
    if (newSubject != null) {
      setState(() {
        _selectedSubject = newSubject;
        _chaptersList = newSubject['sequences'] ?? newSubject['chapters'] ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
        valueListenable: appThemeNotifier,
        builder: (context, themeStr, child) {
          bool isDark = themeStr.startsWith('dark');

          // Adaptive colors matching the mockup
          Color topBarColor = isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFAAAAAA);
          Color topicBgColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF767676);
          Color topicBorderColor = isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black87;

          return Scaffold(
            // MUST be transparent so the FirstPage stars/gradient show through!
            backgroundColor: Colors.transparent,

            body: SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // --- 1. TOP HEADER / DROPDOWN ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      decoration: BoxDecoration(
                        color: topBarColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1A2A49) : Colors.grey[200],
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                          value: _selectedSubject,
                          items: _subjectsList.map((subject) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: subject,
                              child: Text(
                                (subject['subject_name'] ?? 'Unknown Subject').toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : (subject == _selectedSubject ? Colors.white : Colors.black87),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _onSubjectChanged,
                          selectedItemBuilder: (BuildContext context) {
                            return _subjectsList.map<Widget>((item) {
                              return Align(
                                alignment: Alignment.center,
                                child: Text(
                                  (item['subject_name'] ?? '').toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // Always white in the collapsed state
                                  ),
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 2. TOPICS LIST ---
                    Expanded(
                      child: _chaptersList.isEmpty
                          ? const Center(
                          child: Text(
                            "No topics available for this subject.",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          )
                      )
                          : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _chaptersList.length,
                        itemBuilder: (context, index) {
                          final chapter = _chaptersList[index];
                          final int chapterNum = chapter['chapter_num'] ?? (index + 1);
                          final String chapterName = chapter['ch_name'] ?? 'Unknown Topic';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            decoration: BoxDecoration(
                              color: topicBgColor,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: topicBorderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () {
                                  // TODO: Add navigation logic to open PDF or Subtopics
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Opening notes for Topic $chapterNum...')),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                                  child: Text(
                                    "Topic $chapterNum: $chapterName",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Add bottom padding to account for the floating navigation bar
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}