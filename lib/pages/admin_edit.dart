import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/content_manager.dart';

// ============================================================================
// 1. MAIN EDIT PANEL (Displays Subjects, Chapters, and Subtopics)
// ============================================================================
class EditContentPanel extends StatefulWidget {
  const EditContentPanel({Key? key}) : super(key: key);

  @override
  State<EditContentPanel> createState() => _EditContentPanelState();
}

class _EditContentPanelState extends State<EditContentPanel> {
  bool _isLoadingMap = true;
  Map<String, dynamic>? _masterSyllabusMap;

  List<String> _subjects = [];
  String? _selectedSubject;

  List<dynamic> _chapters = [];
  Map<String, dynamic>? _selectedChapter;

  List<dynamic> _subtopics = [];

  @override
  void initState() {
    super.initState();
    _loadMasterSyllabus();
  }

  Future<void> _loadMasterSyllabus() async {
    try {
      setState(() => _isLoadingMap = true);

      String fileName = 'subjects-chapters-subtopics.json';
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$fileName');

      if (!await localFile.exists()) {
        localFile = await ContentDownloadService.downloadFileFromCloud(fileName);
      }

      String jsonString = await localFile.readAsString();
      Map<String, dynamic> data = json.decode(jsonString);

      setState(() {
        _masterSyllabusMap = data;
        _subjects = (data['subjects'] as List).map((s) => s['subject_name'].toString()).toList();

        if (_subjects.isNotEmpty) {
          _selectedSubject = _subjects.first;
          _updateChaptersList(_selectedSubject!);
        }

        _isLoadingMap = false;
      });
    } catch (e) {
      debugPrint("Error loading syllabus: $e");
      setState(() => _isLoadingMap = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _updateChaptersList(String subjectName) {
    if (_masterSyllabusMap == null) return;

    var subjectData = (_masterSyllabusMap!['subjects'] as List).firstWhere(
          (s) => s['subject_name'] == subjectName,
      orElse: () => null,
    );

    if (subjectData != null) {
      setState(() {
        _chapters = subjectData['sequences'] ?? subjectData['chapters'] ?? [];
        if (_chapters.isNotEmpty) {
          _selectedChapter = _chapters.first;
          _updateSubtopicsList(_selectedChapter!);
        } else {
          _selectedChapter = null;
          _subtopics = [];
        }
      });
    }
  }

  void _updateSubtopicsList(Map<String, dynamic> chapter) {
    setState(() {
      _subtopics = List.from(chapter['subtopics'] ?? []);
      // Sort by order just to be safe
      _subtopics.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
    });
  }

  // Saves Subtopic order/deletions back to the Master file and Firebase
  Future<void> _saveMasterChanges() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Reassign 'order' numbers based on the new list positions
      for (int i = 0; i < _subtopics.length; i++) {
        _subtopics[i]['order'] = i + 1;
      }

      // 2. Update the master map
      var subjectData = (_masterSyllabusMap!['subjects'] as List).firstWhere((s) => s['subject_name'] == _selectedSubject);
      var chaptersList = subjectData['sequences'] ?? subjectData['chapters'];
      var chapterData = (chaptersList as List).firstWhere((c) => c['ch_id'] == _selectedChapter!['ch_id']);

      chapterData['subtopics'] = _subtopics;

      // 3. Save Locally
      String fileName = 'subjects-chapters-subtopics.json';
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$fileName');
      await localFile.writeAsString(json.encode(_masterSyllabusMap));

      // 4. Upload to Cloud
      await ContentManager.uploadFileToCloud(localFile, 'data_json/$fileName');

      // 5. Update OTA Timestamp
      int updateTimestamp = DateTime.now().millisecondsSinceEpoch;
      await FirebaseFirestore.instance.collection('app_config').doc('content_updates').set({
        fileName: updateTimestamp,
      }, SetOptions(merge: true));

      if (mounted) Navigator.pop(context); // Close spinner

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subtopic structure saved successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMap) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // INSTRUCTIONS
          const Text("• Press & Drag the menu button to reorder the subtopics\n• Slide to delete the subtopic\n• Click the subtopic to edit its questions",
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 13, height: 1.5)
          ),
          const SizedBox(height: 16),

          // DROPDOWNS
          Row(
            children: [
              const Text("Subject Level:  ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedSubject,
                      items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setState(() => _selectedSubject = val);
                        _updateChaptersList(val!);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_chapters.isNotEmpty)
            Row(
              children: [
                const Text("Chapter:  ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        isExpanded: true,
                        value: _selectedChapter,
                        items: _chapters.map((c) => DropdownMenuItem<Map<String, dynamic>>(
                            value: c,
                            child: Text(c['ch_name'], maxLines: 1, overflow: TextOverflow.ellipsis)
                        )).toList(),
                        onChanged: (val) {
                          setState(() => _selectedChapter = val);
                          _updateSubtopicsList(val!);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // REORDERABLE SUBTOPICS LIST
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(12),
              child: _subtopics.isEmpty
                  ? const Center(child: Text("No subtopics found."))
                  : ReorderableListView.builder(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _subtopics.removeAt(oldIndex);
                    _subtopics.insert(newIndex, item);
                  });
                },
                itemCount: _subtopics.length,
                itemBuilder: (context, index) {
                  final sub = _subtopics[index];
                  final uniqueId = sub['sub_id'] ?? 'sub_$index';

                  return Dismissible(
                    key: ValueKey(uniqueId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.delete, color: Colors.white, size: 30),
                    ),
                    onDismissed: (direction) {
                      setState(() {
                        _subtopics.removeAt(index);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () {
                          // OPEN THE SUBPAGE
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => EditQuestionsSubpage(
                                      chapterData: _selectedChapter!,
                                      subtopicData: sub
                                  )
                              )
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.menu, color: Colors.black87, size: 30), // Drag handle
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      sub['sub_name'] ?? 'Unknown Subtopic',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                  ),
                                  const SizedBox(height: 6),
                                  Text("• Type: ${sub['type'] ?? 'N/A'}", style: TextStyle(color: Colors.grey[700])),
                                  const SizedBox(height: 2),
                                  const Text("• Click to edit questions", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // SAVE BUTTON
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3dcf00), // Green
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: _saveMasterChanges,
              child: const Text("Save Layout Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

// ============================================================================
// 2. SUBPAGE (Displays Questions for Editing/Reordering)
// ============================================================================
class EditQuestionsSubpage extends StatefulWidget {
  final Map<String, dynamic> chapterData;
  final Map<String, dynamic> subtopicData;

  const EditQuestionsSubpage({
    Key? key,
    required this.chapterData,
    required this.subtopicData
  }) : super(key: key);

  @override
  State<EditQuestionsSubpage> createState() => _EditQuestionsSubpageState();
}

class _EditQuestionsSubpageState extends State<EditQuestionsSubpage> {
  bool _isLoading = true;
  Map<String, dynamic>? _chapterJsonFile;
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      String chId = widget.chapterData['ch_id'];
      String fileName = "$chId.json";

      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$fileName');

      if (!await localFile.exists()) {
        localFile = await ContentDownloadService.downloadFileFromCloud(fileName);
      }

      String jsonString = await localFile.readAsString();
      Map<String, dynamic> data = json.decode(jsonString);

      // Find the specific subtopic
      List<dynamic> subs = data['subtopics'] ?? [];
      var matchingSub = subs.firstWhere((s) => s['sub_id'] == widget.subtopicData['sub_id'], orElse: () => null);

      setState(() {
        _chapterJsonFile = data;
        if (matchingSub != null) {
          _questions = List.from(matchingSub['q'] ?? []);
          // Sort questions by their order field just in case
          _questions.sort((a, b) => (a['q_order'] as int? ?? 0).compareTo(b['q_order'] as int? ?? 0));
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading questions: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndComplete() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Reassign 'q_order' numbers based on new positions
      for (int i = 0; i < _questions.length; i++) {
        _questions[i]['q_order'] = i + 1;
      }

      // 2. Update the chapter map
      List<dynamic> subs = _chapterJsonFile!['subtopics'] ?? [];
      var matchingSub = subs.firstWhere((s) => s['sub_id'] == widget.subtopicData['sub_id']);

      matchingSub['q'] = _questions;
      matchingSub['total_q'] = _questions.length;

      // 3. Save locally
      String chId = widget.chapterData['ch_id'];
      String fileName = "$chId.json";
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$fileName');

      await localFile.writeAsString(json.encode(_chapterJsonFile));

      // 4. Upload to Cloud
      await ContentManager.uploadFileToCloud(localFile, 'data_json/$fileName');

      // 5. Update OTA Timestamp
      int updateTimestamp = DateTime.now().millisecondsSinceEpoch;
      await FirebaseFirestore.instance.collection('app_config').doc('content_updates').set({
        fileName: updateTimestamp,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context); // Close spinner
        Navigator.pop(context); // Close Subpage
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questions updated and synced!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Edit Subpage", style: TextStyle(color: Colors.grey)),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // INSTRUCTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.subtopicData['sub_name'] ?? 'Questions', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("• Press & Drag the number to reorder of the question\n• Slide to delete the question\n• Click edit button to edit the question",
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 13, height: 1.5)
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // QUESTIONS LIST
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _questions.isEmpty
                  ? const Center(child: Text("No questions found."))
                  : ReorderableListView.builder(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _questions.removeAt(oldIndex);
                    _questions.insert(newIndex, item);
                  });
                },
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  final uniqueId = q['q_id'] ?? 'q_$index';
                  final options = q['options'] as List? ?? [];
                  final answer = q['ans'] ?? '';

                  return Dismissible(
                    key: ValueKey(uniqueId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.delete, color: Colors.white, size: 30),
                    ),
                    onDismissed: (direction) {
                      setState(() {
                        _questions.removeAt(index);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HUGE NUMBER FOR DRAGGING
                          Text(
                              "${index + 1}",
                              style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.grey[400])
                          ),
                          const SizedBox(width: 16),

                          // QUESTION DETAILS
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q['text'] ?? '(Blank Question)',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                ...options.map((opt) {
                                  bool isCorrect = opt['id'] == answer;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      "• Option ${opt['id']}: ${opt['text']}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isCorrect ? const Color(0xff3dcf00) : Colors.redAccent,
                                        fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),

                          // EDIT ICON
                          IconButton(
                            icon: const Icon(Icons.edit_square, color: Colors.black87, size: 28),
                            onPressed: () {
                              // TODO: Route to admin_add or open dialog to edit specific text fields
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Route to full editor coming soon!')),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // BOTTOM BUTTONS
          Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff3dcf00), // Green
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: _saveAndComplete,
                    child: const Text("Complete", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}