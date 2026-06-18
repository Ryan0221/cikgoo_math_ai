import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart'; // REQUIRED for rootBundle
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'admin_preview_screen.dart';

class AddContentPanel extends StatefulWidget {
  const AddContentPanel({Key? key}) : super(key: key);

  @override
  State<AddContentPanel> createState() => _AddContentPanelState();
}

class _AddContentPanelState extends State<AddContentPanel> {
  // Navigation State
  int _currentIndex = 1;

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
  //final TextEditingController _optionAController = TextEditingController();
  //final TextEditingController _optionBController = TextEditingController();
  //final TextEditingController _optionCController = TextEditingController();
  //final TextEditingController _optionDController = TextEditingController();

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
    //_optionAController.dispose();
    //_optionBController.dispose();
    //_optionCController.dispose();
    //_optionDController.dispose();
    super.dispose();
  }

  // Reads the local file and populates the initial Subject list
  Future<void> _loadMasterSyllabus() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/subjects-chapters-subtopics.json');

      String jsonString;

      // 1. Check if we downloaded an update from the cloud
      if (await localFile.exists()) {
        jsonString = await localFile.readAsString();
      } else {
        // 2. FALLBACK: Read the default file bundled with the app!
        jsonString = await rootBundle.loadString('assets/json/subjects-chapters-subtopics.json');
      }

      // 3. Parse the data
      Map<String, dynamic> data = json.decode(jsonString);

      setState(() {
        _masterSyllabusMap = data;

        // Extract just the subject names for the first dropdown
        _subjects = (data['subjects'] as List)
            .map((s) => s['subject_name'].toString())
            .toList();

        _isLoadingMap = false; // Stop the spinner!
      });

    } catch (e) {
      print("Error loading syllabus: $e");

      // 4. FAILSAFE: Stop the spinner even if the JSON is broken
      setState(() {
        _isLoadingMap = false;
      });

      // Optional: Show an error message to the admin
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load syllabus data: $e')),
        );
      }
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

  Widget _buildCustomDropdown({
    required String label,
    required Color fillColor,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    bool allowAdd = false, // Set to true to show the "+ Add New" option
    Function(String id, String name)? onAddNew, // Callback when new item is saved
  }) {
    // Create a local copy of items so we can safely inject the Add button
    List<String> dropdownItems = List.from(items);
    const String addOptionLabel = "+ Add New";

    if (allowAdd && !dropdownItems.contains(addOptionLabel)) {
      dropdownItems.add(addOptionLabel);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
              isExpanded: true,
            // Ensure the value exists in the list to prevent Flutter assertion errors
            initialValue: (selectedValue != null && dropdownItems.contains(selectedValue)) ? selectedValue : null,
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
                child: SingleChildScrollView( // 2. Adds horizontal scrolling for long text!
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
                // Open Pop-up and DO NOT update the dropdown value to "+ Add New"
                _showAddDialog(label, onAddNew);
              } else {
                onChanged(val);
              }
            },
          ),
        ],
      ),
    );
  }

  // Pop-up Dialog for the "Add New" Dropdown functionality
  void _showAddDialog(String categoryLabel, Function(String, String)? onSave) {
    TextEditingController idController = TextEditingController();
    TextEditingController nameController = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text("Add New $categoryLabel"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: idController,
                    decoration: const InputDecoration(labelText: "Unique ID")
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name")
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
                  if (onSave != null && idController.text.isNotEmpty && nameController.text.isNotEmpty) {
                    onSave(idController.text, nameController.text);
                  }
                  Navigator.pop(ctx);
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
          const Text(
            "- Add a new set of quiz/revision here",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const Text(
            "- Proceed to edit panel to edit/delete the existing question",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 24),

          // SINGLE COLUMN LAYOUT
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STANDARD DROPDOWN: Only extracts the list
                  _buildCustomDropdown(
                    label: "Subject Level",
                    fillColor: Colors.grey[350]!,
                    items: _subjects,
                    selectedValue: _selectedSubject,
                    onChanged: (val) {
                      setState(() => _selectedSubject = val);
                      _updateChaptersList(val!); // TRIGGER CASCADE TO CHAPTERS
                    },
                    allowAdd: true,
                  ),

                  // ADD-ENABLED DROPDOWN: Shows "+ Add New"
                  _buildCustomDropdown(
                      label: "Chapter Name",
                      fillColor: Colors.grey[350]!,
                      items: _chapters,
                      selectedValue: _selectedChapter,
                      allowAdd: true, // Turns on the pop-up feature
                      onChanged: (val) {
                        setState(() => _selectedChapter = val);
                        _updateSubtopicOrder(val!); // TRIGGER CASCADE TO SUBTOPIC ORDER
                      },
                      onAddNew: (id, name) {
                        setState(() {
                          _chapters.add(name);
                          _selectedChapter = name;

                          // If it's a brand new chapter, the first subtopic order is 1
                          _subtopicOrderList = [];
                          _prefilledOrderNumber = 1;
                        });
                      }
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

          // BOTTOM ROW: Navigation & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. LEFT SIDE: Demonstrate Button
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Tooltip(
                  message: "Demonstrate the question before upload",
                  textStyle: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    width: 200,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, // Changed to Blue for "Preview" vibe
                      ),
                      onPressed: () async {
                        // 1. Create a temporary list to hold the formatted preview questions
                        List<Map<String, dynamic>> previewQuestions = [];

                        // 2. Loop through your drafted questions and format them like your JSON!
                        for (int i = 0; i < _questions.length; i++) {
                          var q = _questions[i];

                          // Determine the correct answer ID ('Option A' -> 'A', 'True' -> 'True')
                          String correctAnsId = 'A'; // Fallback
                          if (q.answer != null) {
                            if (q.answer!.startsWith('Option ')) {
                              correctAnsId = q.answer!.split(' ')[1];
                            } else {
                              correctAnsId = q.answer!;
                            }
                          }

                          // Build the options list based on question type
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

                          // Add the compiled question to our preview list
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

                        // 3. Launch the Quiz Screen with the drafted questions!
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminPreviewScreen(questions: previewQuestions),
                          ),
                        );
                        // Launch the preview screen AND wait for a response back
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminPreviewScreen(questions: previewQuestions),
                          ),
                        );

                        // Handle the actions requested by the Preview Screen!
                        if (result != null && result is Map) {
                          if (result['action'] == 'edit') {
                            // The admin clicked the Edit button. Jump to that exact question!
                            setState(() {
                              // We add 1 because _currentIndex is 1-based, but lists are 0-based
                              _currentIndex = (result['index'] as int) + 1;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Jumped to Question $_currentIndex for editing.')),
                            );

                          } else if (result['action'] == 'upload') {
                            // The admin clicked "Complete & Upload" on the final checkmark!

                            // TODO: Call your Firebase Upload Function here!
                            // Example: await FirestoreService().uploadSubtopic(...);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Uploading to database...'),
                                backgroundColor: Colors.green,
                              ),
                            );
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