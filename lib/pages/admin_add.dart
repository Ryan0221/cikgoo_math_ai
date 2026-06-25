import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/content_manager.dart';
import 'admin_preview_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- NEW: Required for updating OTA timestamps

class AddContentPanel extends StatefulWidget {
  const AddContentPanel({Key? key}) : super(key: key);

  @override
  State<AddContentPanel> createState() => _AddContentPanelState();
}

class _AddContentPanelState extends State<AddContentPanel> {
  // Navigation State
  int _currentIndex = 1;
  bool _isLaunchingPreview = false;

  // Dropdown States
  String? _selectedSubject;
  String? _selectedChapter;
  String? _selectedSubtopicType;
  String? _selectedQuestionOrder;
  String? _selectedQuestionType;
  String? _selectedQuestionDifficulty;
  String? _selectedAnswer;

  // File Attachment State
  String? _attachedFileName;
  String? _attachedFilePath; // <-- NEW: Used to actually upload the PDF!

  // Sample Options for Dropdowns
  final List<String> _subtopicTypes = ['Quiz', 'Revision'];
  final List<String> _questionTypes = ['Multiple Choice Question', 'True/False Question'];
  final List<String> _questionDifficulties = ['1', '2', '3', '4', '5'];
  final List<String> _mcqAnswers = ['Option A', 'Option B', 'Option C', 'Option D'];
  final List<String> _tfqAnswers = ['True', 'False'];

  // State for Reorderable List
  List<String> _subtopicOrderList = ['Subtopic A', 'Subtopic B', 'Subtopic C'];
  int _prefilledOrderNumber = 1; // E.g., defaulting to order 1

  bool _isLoadingMap = true;
  Map<String, dynamic>? _masterSyllabusMap; // Holds the whole JSON

  // Dynamic Lists (No longer hardcoded!)
  List<String> _subjects = [];
  List<String> _chapters = [];

  final TextEditingController _subtopicNameController = TextEditingController();
  List<QuestionItem> _questions = [QuestionItem()];

  int get _totalQuestions => _questions.length;

  @override
  void initState() {
    super.initState();
    // This tells Flutter to run your JSON loader as soon as the panel opens
    _loadMasterSyllabus();
  }

  @override
  void dispose() {
    _subtopicNameController.dispose();
    // Dispose all question controllers to prevent memory leaks
    for (var q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMasterSyllabus() async {
    try {
      setState(() => _isLoadingMap = true);

      String fileName = 'subjects-chapters-subtopics.json';
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$fileName');

      // 1. Check if the file exists locally
      if (!await localFile.exists()) {
        print("File missing locally. Attempting to fetch from Firebase...");

        // 2. TRIGGER ON-DEMAND DOWNLOAD
        // This pauses execution until the cloud returns the latest JSON file
        localFile = await ContentDownloadService.downloadFileFromCloud(fileName);
      }

      // 3. Read the file (either existing local copy or newly downloaded copy)
      String jsonString = await localFile.readAsString();
      Map<String, dynamic> data = json.decode(jsonString);

      setState(() {
        _masterSyllabusMap = data;
        _subjects = (data['subjects'] as List)
            .map((s) => s['subject_name'].toString())
            .toList();
        _isLoadingMap = false;
      });

    } catch (e) {
      print("Error loading syllabus: $e");
      setState(() => _isLoadingMap = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load data. Check your internet connection.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- NEW: Saves the Master Syllabus JSON locally ---
  Future<void> _saveMasterSyllabus() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/subjects-chapters-subtopics.json');
      await localFile.writeAsString(json.encode(_masterSyllabusMap));
      print("Master syllabus saved locally.");
    } catch (e) {
      print("Error saving master syllabus: $e");
    }
  }

  // --- NEW: Creates the individual Chapter JSON file ---
  Future<void> _createChapterFile(String chId, String chName, int chapterNum) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$chId.json');
      Map<String, dynamic> newChapterJson = {
        "ch_id": chId,
        "ch_name": chName,
        "chapter_num": chapterNum,
        "total_sub": 0,
        "subtopics": []
      };
      await localFile.writeAsString(json.encode(newChapterJson));
      print("Created new chapter file: $chId.json");
    } catch (e) {
      print("Error creating chapter file: $e");
    }
  }

  // Update Chapters list based on the chosen subject
  void _updateChaptersList(String subjectName) {
    if (_masterSyllabusMap == null) return;

    // Find the specific subject in the JSON
    var subjectData = (_masterSyllabusMap!['subjects'] as List).firstWhere(
          (s) => s['subject_name'] == subjectName,
      orElse: () => null,
    );

    if (subjectData != null) {
      // Remember we standardized the array name to 'sequences' or 'chapters'
      var chaptersList = subjectData['sequences'] ?? subjectData['chapters'] ?? [];

      setState(() {
        _chapters = (chaptersList as List)
            .map((c) => c['ch_name'].toString())
            .toList();

        // Reset subsequent selections
        _selectedChapter = null;
        _subtopicOrderList.clear();
      });
    }
  }

  // Update Subtopic Order based on chosen chapter
  void _updateSubtopicOrder(String chapterName) {
    if (_masterSyllabusMap == null || _selectedSubject == null) return;

    var subjectData = (_masterSyllabusMap!['subjects'] as List).firstWhere((s) => s['subject_name'] == _selectedSubject);
    var chaptersList = subjectData['sequences'] ?? subjectData['chapters'] ?? [];

    var chapterData = (chaptersList as List).firstWhere(
          (c) => c['ch_name'] == chapterName,
      orElse: () => null,
    );

    if (chapterData != null) {
      var subtopics = chapterData['subtopics'] as List? ?? [];

      setState(() {
        // Extract existing subtopics for the reorderable list
        _subtopicOrderList = subtopics.map((st) => st['sub_name'].toString()).toList();

        // The prefilled order number is simply the length of the list + 1
        _prefilledOrderNumber = _subtopicOrderList.length + 1;
      });
    }
  }

// --- UPDATED: Modified signature to take onAddTap ---
  Widget _buildCustomDropdown({
    required String label,
    required Color fillColor,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    bool allowAdd = false,
    VoidCallback? onAddTap,
  }) {
    List<String> dropdownItems = List.from(items);
    const String addOptionLabel = "+ Add New";

    if (allowAdd && !dropdownItems.contains(addOptionLabel)) {
      dropdownItems.add(addOptionLabel);
    }

    String? safeValue = (selectedValue != null && dropdownItems.contains(selectedValue)) ? selectedValue : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: safeValue,
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            items: dropdownItems.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: value == addOptionLabel ? Colors.blue : Colors.black,
                      fontWeight: value == addOptionLabel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (allowAdd && val == addOptionLabel) {
                // Trigger the passed-in dialog instead of updating the value
                if (onAddTap != null) onAddTap();
              } else {
                onChanged(val);
              }
            },
          ),
        ],
      ),
    );
  }

// --- NEW: Add Subject Dialog ---
  void _showAddSubjectDialog() {
    TextEditingController idController = TextEditingController();
    TextEditingController nameController = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Add New Subject Level"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: idController,
                    decoration: const InputDecoration(labelText: "Subject ID (e.g., spmMathF6)")
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Subject Name")
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel")
              ),
              ElevatedButton(
                onPressed: () {
                  String newId = idController.text.trim();
                  String newName = nameController.text.trim();
                  if (newId.isNotEmpty && newName.isNotEmpty) {
                    setState(() {
                      // 1. Add to the JSON structure
                      _masterSyllabusMap!['subjects'].add({
                        "subject_id": newId,
                        "subject_name": newName,
                        "chapters": []
                      });
                      _subjects.add(newName);
                      _selectedSubject = newName;
                      _chapters.clear();
                      _selectedChapter = null;
                    });

                    // 3. Save to Local File
                    _saveMasterSyllabus();
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        }
    );
  }

  // --- NEW: Add Chapter Dialog ---
  void _showAddChapterDialog() {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Subject Level first.")));
      return;
    }

    TextEditingController numController = TextEditingController();
    TextEditingController nameController = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Add New Chapter"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: numController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Chapter Number (e.g., 5)")
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Chapter Name")
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel")
              ),
              ElevatedButton(
                onPressed: () {
                  int? chNum = int.tryParse(numController.text.trim());
                  String chName = nameController.text.trim();

                  if (chNum != null && chName.isNotEmpty) {
                    // 1. Find subject and generate IDs
                    var subjectData = (_masterSyllabusMap!['subjects'] as List).firstWhere((s) => s['subject_name'] == _selectedSubject);
                    String subjId = subjectData['subject_id'];

                    String newChId = "${subjId}_c$chNum";

                    // NEW: Stop hardcoding 'assets/json/' for new chapters!
                    // Just save the pure filename so it relies purely on the cloud.
                    String newChFileLoc = "$newChId.json";

                    setState(() {
                      // Support both 'chapters' or 'sequences' depending on existing JSON schema
                      if (subjectData['chapters'] == null && subjectData['sequences'] == null) {
                        subjectData['chapters'] = [];
                      }
                      var chaptersList = subjectData['chapters'] ?? subjectData['sequences'];

                      // 2. Add to the Master JSON structure
                      chaptersList.add({
                        "chapter_num": chNum,
                        "ch_id": newChId,
                        "ch_name": chName,
                        "ch_file_location": newChFileLoc,
                        "subtopics": []
                      });

                      // 3. Update UI Dropdowns
                      _chapters.add(chName);
                      _selectedChapter = chName;
                      _subtopicOrderList = [];
                      _prefilledOrderNumber = 1;
                    });

                    // 4. Save Master File AND generate the new subtopic JSON file!
                    _saveMasterSyllabus();
                    _createChapterFile(newChId, chName, chNum);

                    Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid Chapter Number and Name.")));
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        }
    );
  }

  // ---------------------------------------------------------------------------
  // 2. NEW REORDERABLE PREFILLED NUMBER FUNCTION
  // ---------------------------------------------------------------------------
  Widget _buildReorderableField(String label, Color fillColor, List<String> currentList, int selectedNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showReorderDialog(currentList),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(selectedNumber.toString(), style: const TextStyle(fontSize: 16)),
                  const Icon(Icons.reorder, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog that contains the drag-and-drop ReorderableListView
  void _showReorderDialog(List<String> list) {
    // 1. Get the name the user just typed. Give it a default if they left it blank.
    String currentNewName = _subtopicNameController.text.trim();
    if (currentNewName.isEmpty) {
      currentNewName = "(New Subtopic)";
    }

    // 2. Create a local copy for dragging
    List<String> tempList = List.from(list);

    // 3. Insert the new subtopic into the temporary list at its current order number
    int insertIndex = _prefilledOrderNumber - 1;
    if (insertIndex >= 0 && insertIndex <= tempList.length) {
      tempList.insert(insertIndex, currentNewName);
    } else {
      tempList.add(currentNewName);
    }

    showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  title: const Text("Reorder Items"),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: ReorderableListView(
                      onReorder: (oldIndex, newIndex) {
                        setStateDialog(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = tempList.removeAt(oldIndex);
                          tempList.insert(newIndex, item);
                        });
                      },
                      children: [
                        for (int i = 0; i < tempList.length; i++)
                          ListTile(
                            key: ValueKey(tempList[i]),
                            title: Text(
                              tempList[i],
                              // Highlight the new subtopic in blue so the admin can easily spot it!
                              style: TextStyle(
                                fontWeight: tempList[i] == currentNewName ? FontWeight.bold : FontWeight.normal,
                                color: tempList[i] == currentNewName ? Colors.blue : Colors.black,
                              ),
                            ),
                            leading: Text("${i + 1}."),
                            trailing: const Icon(Icons.drag_handle),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancel")
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // 4. Find where the admin dragged the new item, and update the Order Number!
                          _prefilledOrderNumber = tempList.indexOf(currentNewName) + 1;

                          // 5. Remove the new item from the background tracking list
                          // (It will be permanently added later when they click "Complete")
                          tempList.remove(currentNewName);
                          _subtopicOrderList = tempList;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text("Save Order"),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  // 1. The UI Box for the Question Order
  Widget _buildQuestionReorderField(String label, Color fillColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            // Open the dialog when tapped!
            onTap: () => _showQuestionReorderDialog(),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Show the current index as the text
                  Text(_currentIndex.toString(), style: const TextStyle(fontSize: 16)),
                  const Icon(Icons.reorder, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. The Pop-Up Dialog to drag and drop questions
  void _showQuestionReorderDialog() {
    // Make a temporary copy of the questions list for dragging
    List<QuestionItem> tempList = List.from(_questions);

    showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  title: const Text("Reorder Questions"),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: ReorderableListView(
                      onReorder: (oldIndex, newIndex) {
                        setStateDialog(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = tempList.removeAt(oldIndex);
                          tempList.insert(newIndex, item);
                        });
                      },
                      children: [
                        for (int i = 0; i < tempList.length; i++)
                          ListTile(
                            key: ValueKey(tempList[i]), // Use the actual object as the key
                            title: Text(
                              // Show the question text, or a placeholder if it's blank
                              tempList[i].questionCtrl.text.trim().isNotEmpty
                                  ? tempList[i].questionCtrl.text
                                  : "(Blank Question)",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              // Highlight the question they were just working on!
                              style: TextStyle(
                                fontWeight: tempList[i] == _questions[_currentIndex - 1]
                                    ? FontWeight.bold : FontWeight.normal,
                                color: tempList[i] == _questions[_currentIndex - 1]
                                    ? Colors.blue : Colors.black,
                              ),
                            ),
                            leading: Text("${i + 1}."),
                            trailing: const Icon(Icons.drag_handle),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancel")
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // SAVE THE NEW ORDER
                        setState(() {
                          // Find out where the question we were just looking at ended up
                          QuestionItem activeQuestion = _questions[_currentIndex - 1];

                          _questions = tempList;

                          // Update the index so the screen stays on the question they were editing
                          _currentIndex = _questions.indexOf(activeQuestion) + 1;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text("Save Order"),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  Widget _buildFileAttachField(String label, Color fillColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              // OPEN THE NATIVE FILE PICKER (Limited to PDF)
              FilePickerResult? result = await FilePicker.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );

              if (result != null) {
                setState(() {
                  // Save the name of the picked file
                  _attachedFileName = result.files.single.name;
                  _attachedFilePath = result.files.single.path;
                });
              }
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _attachedFileName ?? "Tap to attach a file...",
                      style: TextStyle(
                        color: _attachedFileName == null ? Colors.black54 : Colors.black,
                        fontStyle: _attachedFileName == null ? FontStyle.italic : FontStyle.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.attach_file, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for Image-enabled TextFields (Question & Options)
  Widget _buildImageTextField(String label, Color fillColor, {
    int maxLines = 1,
    TextEditingController? controller,
    bool readOnly = false
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly, // Locks the field if true
            maxLines: maxLines,
            style: TextStyle(color: readOnly ? Colors.grey[700] : Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.image, color: Colors.grey),
                onPressed: () async {
                  // OPEN THE NATIVE PHOTO ALBUM
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                  if (image != null) {
                    print("Admin selected image: ${image.path}");
                    // TODO: Later, you will upload this image.path to Firebase Storage!
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Image selected: ${image.name}')),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for Standard TextFields
  Widget _buildStandardTextField(String label, Color fillColor, {int maxLines = 1, TextEditingController? controller}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller, // <-- Attach the controller here!
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoadingMap) {
      return const Center(child: CircularProgressIndicator());
    }

    // Grab the current question object before we start drawing the UI
    QuestionItem currentQ = _questions[_currentIndex - 1];

    return Padding(
      // Removed the white container decoration, leaving just padding
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          // SINGLE COLUMN LAYOUT
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "- Add a new set of quiz/revision here",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const Text(
                    "- Proceed to edit panel to edit/delete the existing question",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  // --- TRIGGER UPDATED TO USE onAddTap ---
                  _buildCustomDropdown(
                    label: "Subject Level",
                    fillColor: Colors.grey[350]!,
                    items: _subjects,
                    selectedValue: _selectedSubject,
                    allowAdd: true,
                    onAddTap: _showAddSubjectDialog, // Fires our specific new dialog
                    onChanged: (val) {
                      setState(() => _selectedSubject = val);
                      _updateChaptersList(val!);
                    },
                  ),

                  // --- TRIGGER UPDATED TO USE onAddTap ---
                  _buildCustomDropdown(
                    label: "Chapter Name",
                    fillColor: Colors.grey[350]!,
                    items: _chapters,
                    selectedValue: _selectedChapter,
                    allowAdd: true,
                    onAddTap: _showAddChapterDialog, // Fires our specific new dialog
                    onChanged: (val) {
                      setState(() => _selectedChapter = val);
                      _updateSubtopicOrder(val!);
                    },
                  ),

                  _buildStandardTextField("Subtopic Name", Colors.grey[350]!, controller: _subtopicNameController),

                  // NEW REORDERABLE PREFILLED FIELD
                  _buildReorderableField(
                      "Subtopic Order",
                      Colors.grey[350]!,
                      _subtopicOrderList,
                      _prefilledOrderNumber
                  ),

                  _buildCustomDropdown(
                    label: "Type",
                    fillColor: Colors.grey[350]!,
                    items: _subtopicTypes,
                    selectedValue: _selectedSubtopicType,
                    onChanged: (val) {
                      setState(() {
                        _selectedSubtopicType = val;
                        // Optional: clear attached file if user switches away from Quiz
                        if (val != 'Quiz') _attachedFileName = null;
                      });
                    },
                  ),

                  // CONDITIONAL VISIBILITY: Show Notes attachment ONLY if 'Quiz' is selected
                  if (_selectedSubtopicType == 'Quiz')
                    _buildFileAttachField("Notes (only PDF file)", Colors.grey[350]!),

                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[350], // Gives it a distinct background from the grey dashboard
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05), // Soft shadow for depth
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Visibility(
                              visible: _currentIndex > 1,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child:
                              // The Left Arrow (<)
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () {
                                  if (_currentIndex > 1) {
                                    setState(() => _currentIndex--);
                                  }
                                },
                              ),
                            ),
                            Text(
                              "Question $_currentIndex/$_totalQuestions",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                            ),
                            Visibility(
                              visible: _currentIndex < _totalQuestions,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child:
                              // The Right Arrow (>)
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {
                                  if (_currentIndex < _totalQuestions) {
                                    setState(() => _currentIndex++);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        _buildQuestionReorderField("Question Order", Colors.grey[200]!),

                        _buildCustomDropdown(
                            label: "Type",
                            fillColor: Colors.grey[200]!,
                            items: _questionTypes,
                            selectedValue: currentQ.questionType,
                            onChanged: (val) {
                              setState(() {
                                currentQ.questionType = val;

                                // True/False Auto-Fill logic applied to CURRENT question
                                if (val == 'True/False Question') {
                                  currentQ.optACtrl.text = "True";
                                  currentQ.optBCtrl.text = "False";
                                  currentQ.optCCtrl.clear();
                                  currentQ.optDCtrl.clear();
                                } else {
                                  currentQ.optACtrl.clear();
                                  currentQ.optBCtrl.clear();
                                }
                              });
                            }
                        ),
                        _buildCustomDropdown(
                            label: "Question Difficulty",
                            fillColor: Colors.grey[200]!,
                            items: _questionDifficulties,
                            selectedValue: currentQ.questionDifficulty,
                            onChanged: (val) => setState(() => currentQ.questionDifficulty = val)
                        ),

                        _buildImageTextField("Question", Colors.grey[200]!, controller: currentQ.questionCtrl),
                        _buildStandardTextField("Hint", Colors.grey[200]!, controller: currentQ.hintCtrl),

                        _buildImageTextField("Option A", Colors.grey[200]!, controller: currentQ.optACtrl, readOnly: currentQ.questionType == 'True/False Question'),
                        _buildImageTextField("Option B", Colors.grey[200]!, controller: currentQ.optBCtrl, readOnly: currentQ.questionType == 'True/False Question'),

                        Visibility(
                          visible: currentQ.questionType != 'True/False Question',
                          child: Column(
                            children: [
                              _buildImageTextField("Option C", Colors.grey[200]!, controller: currentQ.optCCtrl),
                              _buildImageTextField("Option D", Colors.grey[200]!, controller: currentQ.optDCtrl),
                            ],
                          ),
                        ),
                        /*_buildDropdown("Answer", Colors.grey[200]!, _answers, _selectedAnswer, (val) {
                          setState(() => _selectedAnswer = val);
                        }),*/
                        _buildCustomDropdown(
                            label: "Answer",
                            fillColor: Colors.grey[200]!,
                            items: currentQ.questionType == "Multiple Choice Question" ? _mcqAnswers : _tfqAnswers,
                            selectedValue: currentQ.answer,
                            onChanged: (val) => setState(() => currentQ.answer = val)
                        ),
                        _buildStandardTextField("Explanation", Colors.grey[200]!, controller: currentQ.expCtrl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BOTTOM ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Tooltip(
                  message: "Demonstrate the question before upload",
                  textStyle: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                  child: SizedBox(
                    width: 200, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      onPressed: _isLaunchingPreview ? null : () async {

                        // Safety Checks
                        if (_selectedSubject == null || _selectedChapter == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Subject and Chapter first.')));
                          return;
                        }

                        setState(() => _isLaunchingPreview = true);

                        List<Map<String, dynamic>> previewQuestions = [];
                        for (int i = 0; i < _questions.length; i++) {
                          var q = _questions[i];
                          String correctAnsId = 'A';
                          if (q.answer != null) {
                            if (q.answer!.startsWith('Option ')) {
                              correctAnsId = q.answer!.split(' ')[1];
                            } else {
                              correctAnsId = q.answer!;
                            }
                          }

                          List<Map<String, dynamic>> optionsList = [];
                          if (q.questionType == 'True/False Question') {
                            optionsList = [
                              {"id": "True", "text": q.optACtrl.text.isNotEmpty ? q.optACtrl.text : "True", "option_pic": null},
                              {"id": "False", "text": q.optBCtrl.text.isNotEmpty ? q.optBCtrl.text : "False", "option_pic": null},
                            ];
                          } else {
                            optionsList = [
                              {"id": "A", "text": q.optACtrl.text.isNotEmpty ? q.optACtrl.text : "Empty Option A", "option_pic": null},
                              {"id": "B", "text": q.optBCtrl.text.isNotEmpty ? q.optBCtrl.text : "Empty Option B", "option_pic": null},
                              {"id": "C", "text": q.optCCtrl.text.isNotEmpty ? q.optCCtrl.text : "Empty Option C", "option_pic": null},
                              {"id": "D", "text": q.optDCtrl.text.isNotEmpty ? q.optDCtrl.text : "Empty Option D", "option_pic": null},
                            ];
                          }

                          previewQuestions.add({
                            "q_id": "preview_q_${i + 1}",
                            "q_order": i + 1,
                            "type": q.questionType == 'True/False Question' ? "tfq" : "mcq",
                            "text": q.questionCtrl.text.isNotEmpty ? q.questionCtrl.text : "(Blank Question ${i + 1})",
                            "question_difficulty": int.tryParse(q.questionDifficulty ?? '1') ?? 1,
                            "question_pic": null,
                            "options_has_picture": false,
                            "options": optionsList,
                            "ans": correctAnsId,
                            "hint": q.hintCtrl.text.isNotEmpty ? q.hintCtrl.text : "No hint provided.",
                            "explanation": q.expCtrl.text.isNotEmpty ? q.expCtrl.text : "No explanation provided."
                          });
                        }

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AdminPreviewScreen(questions: previewQuestions)),
                        );

                        if (!mounted) return;
                        setState(() => _isLaunchingPreview = false);

                        if (result != null && result is Map) {
                          if (result['action'] == 'edit') {
                            setState(() => _currentIndex = (result['index'] as int) + 1);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jumped to Question $_currentIndex for editing.')));
                          } else if (result['action'] == 'upload') {

                            // =========================================================
                            // THE MASTER UPLOAD SEQUENCE
                            // =========================================================
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );

                            try {
                              // 1. Get IDs
                              var subjectData = (_masterSyllabusMap!['subjects'] as List).firstWhere((s) => s['subject_name'] == _selectedSubject);
                              var chaptersList = subjectData['chapters'] ?? subjectData['sequences'];
                              var chapterData = (chaptersList as List).firstWhere((c) => c['ch_name'] == _selectedChapter);

                              String chId = chapterData['ch_id'];
                              String subId = "$chId.$_prefilledOrderNumber";

                              // 2. Add to Master Syllabus (NO TIMESTAMP)
                              Map<String, dynamic> masterSubtopicEntry = {
                                "sub_id": subId,
                                "sub_name": _subtopicNameController.text.trim().isEmpty ? "New Subtopic" : _subtopicNameController.text.trim(),
                                "type": _selectedSubtopicType?.toLowerCase() ?? 'quiz',
                                "order": _prefilledOrderNumber
                              };

                              List<dynamic> masterSubList = chapterData['subtopics'] ?? [];
                              masterSubList.removeWhere((s) => s['sub_id'] == subId);
                              masterSubList.add(masterSubtopicEntry);
                              masterSubList.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
                              chapterData['subtopics'] = masterSubList;

                              await _saveMasterSyllabus(); // Save to local sandbox

                              // 3. Read specific Chapter JSON
                              Directory appDocDir = await getApplicationDocumentsDirectory();
                              File chapterFile = File('${appDocDir.path}/$chId.json');
                              Map<String, dynamic> chapterJson;

                              if (await chapterFile.exists()) {
                                chapterJson = json.decode(await chapterFile.readAsString());
                              } else {
                                chapterJson = {
                                  "ch_id": chId,
                                  "ch_name": _selectedChapter,
                                  "chapter_num": chapterData['chapter_num'],
                                  "total_sub": 0,
                                  "subtopics": []
                                };
                              }

                              // 4. Inject Full Data into Chapter JSON (NO TIMESTAMP)
                              Map<String, dynamic> fullSubtopicEntry = {
                                "sub_id": subId,
                                "sub_name": masterSubtopicEntry['sub_name'],
                                "type": masterSubtopicEntry['type'],
                                "order": masterSubtopicEntry['order'],
                                "notes_location": _attachedFileName != null ? "data_pdf/$_attachedFileName" : null,
                                "author_id": FirebaseAuth.instance.currentUser?.uid ?? "admin",
                                "is_published": true,
                                "created_at": DateTime.now().toIso8601String(), // Optional: Keeps track of original creation
                                "total_q": previewQuestions.length,
                                "q": previewQuestions
                              };

                              List<dynamic> chapterSubList = chapterJson['subtopics'] ?? [];
                              chapterSubList.removeWhere((s) => s['sub_id'] == subId);
                              chapterSubList.add(fullSubtopicEntry);
                              chapterSubList.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

                              chapterJson['subtopics'] = chapterSubList;
                              chapterJson['total_sub'] = chapterSubList.length;

                              await chapterFile.writeAsString(json.encode(chapterJson)); // Save locally

                              // 5. FIREBASE STORAGE UPLOADS (Automatically replaces existing files)
                              File masterFile = File('${appDocDir.path}/subjects-chapters-subtopics.json');
                              // UPDATED PATHS: data_json and data_pdf
                              await ContentManager.uploadFileToCloud(masterFile, 'data_json/subjects-chapters-subtopics.json');
                              await ContentManager.uploadFileToCloud(chapterFile, 'data_json/$chId.json');

                              if (_attachedFilePath != null && _attachedFileName != null) {
                                File pdfFile = File(_attachedFilePath!);
                                await ContentManager.uploadFileToCloud(pdfFile, 'data_pdf/$_attachedFileName');
                              }

                              // 6. NEW: UPDATE FIRESTORE OTA TIMESTAMPS
                              // By using millisecondsSinceEpoch, it acts as an incrementing version number!
                              int updateTimestamp = DateTime.now().millisecondsSinceEpoch;

                              await FirebaseFirestore.instance.collection('app_config').doc('content_updates').set({
                                'subjects-chapters-subtopics.json': updateTimestamp,
                                '$chId.json': updateTimestamp,
                              }, SetOptions(merge: true)); // merge: true ensures we don't delete other file trackers

                              if (mounted) Navigator.pop(context); // Close spinner

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Upload Complete! All users will receive this update.'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                            } catch (e) {
                              if (mounted) Navigator.pop(context);
                              print("Upload sequence error: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white),
                          SizedBox(width: 8),
                          Text("Demonstrate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. RIGHT SIDE: Add More Question Button
              // Wrap with Padding to act as a margin
              Padding(
                padding: const EdgeInsets.only(top: 16.0), // Your margin here!
                child: SizedBox(
                  width: 200,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      setState(() {
                        // Add a fresh, blank question to the list
                        _questions.add(QuestionItem());

                        // Automatically jump the view to the newly created question
                        _currentIndex = _questions.length;
                      });
                    },
                    child: const Text("Add More Question", style: TextStyle(color: Colors.white)),
                  ),
              ),
    ),
            ],
          )
        ],
      ),
    );
  }
}

// Blueprint for a single question's data
class QuestionItem {
  String? questionOrder;
  String? questionType;
  String? questionDifficulty;
  String? answer;

  final TextEditingController questionCtrl = TextEditingController();
  final TextEditingController hintCtrl = TextEditingController();
  final TextEditingController optACtrl = TextEditingController();
  final TextEditingController optBCtrl = TextEditingController();
  final TextEditingController optCCtrl = TextEditingController();
  final TextEditingController optDCtrl = TextEditingController();
  final TextEditingController expCtrl = TextEditingController();

  // We must clean up controllers to prevent memory leaks when a question is deleted
  void dispose() {
    questionCtrl.dispose();
    hintCtrl.dispose();
    optACtrl.dispose();
    optBCtrl.dispose();
    optCCtrl.dispose();
    optDCtrl.dispose();
    expCtrl.dispose();
  }
}