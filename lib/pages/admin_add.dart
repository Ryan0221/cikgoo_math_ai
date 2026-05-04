import 'package:flutter/material.dart';

class AddContentPanel extends StatefulWidget {
  const AddContentPanel({Key? key}) : super(key: key);

  @override
  State<AddContentPanel> createState() => _AddContentPanelState();
}

class _AddContentPanelState extends State<AddContentPanel> {
  // Navigation State
  int _currentIndex = 1;
  int _totalQuestions = 1;

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
  final List<String> _subjects = ['Mathematics SPM Form 4', 'Mathematics SPM Form 5'];
  List<String> _chapters = ['Chapter 1', 'Chapter 2']; // Made mutable so we can add to it
  final List<String> _subtopicTypes = ['Quiz', 'Revision'];
  final List<String> _questionTypes = ['Multiple Choice Question', 'True/False Question'];
  final List<String> _questionDifficulties = ['1', '2', '3', '4', '5'];
  final List<String> _mcqAnswers = ['Option A', 'Option B', 'Option C', 'Option D'];
  final List<String> _tfqAnswers = ['True', 'False'];

  // State for Reorderable List
  List<String> _subtopicOrderList = ['Subtopic A', 'Subtopic B', 'Subtopic C'];
  int _prefilledOrderNumber = 1; // E.g., defaulting to order 1

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
            // Ensure the value exists in the list to prevent Flutter assertion errors
            value: (selectedValue != null && dropdownItems.contains(selectedValue)) ? selectedValue : null,
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
                child: Text(
                  value,
                  style: TextStyle(
                    color: value == addOptionLabel ? Colors.blue : Colors.black,
                    fontWeight: value == addOptionLabel ? FontWeight.bold : FontWeight.normal,
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
    List<String> tempList = List.from(list); // Local copy for dragging

    showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder( // StatefulBuilder allows setState inside the dialog
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
                            title: Text(tempList[i]),
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
                          _subtopicOrderList = tempList; // Save the new order
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
              // TODO: Implement actual file picker logic here (e.g., using file_picker package)
              // For now, we simulate a file being selected:
              setState(() {
                _attachedFileName = "my_chapter_notes.pdf";
              });
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
  Widget _buildImageTextField(String label, Color fillColor, {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.image, color: Colors.grey),
                onPressed: () {
                  // TODO: Add image picker logic here
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for Standard TextFields
  Widget _buildStandardTextField(String label, Color fillColor, {int maxLines = 1}) {
    return Container(
      // 1. Add your margin here!
      // You can use EdgeInsets.all(), EdgeInsets.symmetric(), or EdgeInsets.only()
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
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
                    onChanged: (val) => setState(() => _selectedSubject = val),
                    allowAdd: false,
                  ),

                  // ADD-ENABLED DROPDOWN: Shows "+ Add New"
                  _buildCustomDropdown(
                      label: "Chapter Name",
                      fillColor: Colors.grey[350]!,
                      items: _chapters,
                      selectedValue: _selectedChapter,
                      allowAdd: true, // Turns on the pop-up feature
                      onChanged: (val) => setState(() => _selectedChapter = val),
                      onAddNew: (id, name) {
                        setState(() {
                          // Logic to handle the new ID and Name goes here
                          _chapters.add(name);
                          _selectedChapter = name; // Auto-select the newly created item
                        });
                      }
                  ),

                  _buildStandardTextField("Subtopic Name", Colors.grey[350]!),

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

                  // NEW REORDERABLE PREFILLED FIELD
                  _buildReorderableField(
                      "Subtopic Order",
                      Colors.grey[350]!,
                      _subtopicOrderList,
                      _prefilledOrderNumber
                  ),
                  //_buildDropdown("Subject Level", Colors.grey[350]!, _subjects, _selectedSubject, (val) => setState(() => _selectedSubject = val)),
                  //_buildDropdown("Chapter Name", Colors.grey[350]!, _subjects, _selectedSubject, (val) => setState(() => _selectedSubject = val)),
                  //_buildStandardTextField("Subtopic Name", Colors.grey[350]!),
                  //_buildDropdown("Type", Colors.grey[350]!, _subtopicTypes, _selectedSubtopicType, (val) => setState(() => _selectedSubtopicType = val)),
                  //_buildDropdown("Subtopic Order", Colors.grey[350]!, _subtopicTypes, _selectedSubtopicType, (val) => setState(() => _selectedSubtopicType = val)),

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
                              child: IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () => setState(() => _currentIndex--),
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
                              child: IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () => setState(() => _currentIndex++),
                              ),
                            ),
                          ],
                        ),
                        /*_buildDropdown("Question Order", Colors.grey[200]!, _answers, _selectedAnswer, (val) {
                        setState(() => _selectedAnswer = val);
                        }),
                        _buildDropdown("Type", Colors.grey[350]!, _questionTypes, _selectedQuestionType, (val) => setState(() => _selectedQuestionType = val)),
                        _buildDropdown("Question Difficulty", Colors.grey[350]!, _questionDifficulties, _selectedQuestionDifficulty, (val) => setState(() => _selectedQuestionDifficulty = val)),
                        */
                        _buildCustomDropdown(
                            label: "Question Order",
                            fillColor: Colors.grey[200]!,
                            items: _questionDifficulties,
                            selectedValue: _selectedQuestionOrder,
                            onChanged: (val) => setState(() => _selectedQuestionOrder = val)
                        ),
                        _buildCustomDropdown(
                            label: "Type",
                            fillColor: Colors.grey[200]!,
                            items: _questionTypes,
                            selectedValue: _selectedQuestionType,
                            onChanged: (val) => setState(() => _selectedQuestionType = val)
                        ),
                        _buildCustomDropdown(
                            label: "Question Difficulty",
                            fillColor: Colors.grey[200]!,
                            items: _questionDifficulties,
                            selectedValue: _selectedQuestionDifficulty,
                            onChanged: (val) => setState(() => _selectedQuestionDifficulty = val)
                        ),
                        _buildImageTextField("Question", Colors.grey[200]!, maxLines: 1),

                        _buildStandardTextField("Hint", Colors.grey[200]!, maxLines: 1),
                        _buildImageTextField("Option A", Colors.grey[200]!,),
                        _buildImageTextField("Option B", Colors.grey[200]!,),
                        _buildImageTextField("Option C", Colors.grey[200]!,),
                        _buildImageTextField("Option D", Colors.grey[200]!,),
                        /*_buildDropdown("Answer", Colors.grey[200]!, _answers, _selectedAnswer, (val) {
                          setState(() => _selectedAnswer = val);
                        }),*/
                        _buildCustomDropdown(
                            label: "Answer",
                            fillColor: Colors.grey[200]!,
                            items: _selectedQuestionType == "Multiple Choice Question" ? _mcqAnswers : _tfqAnswers,
                            selectedValue: _selectedAnswer,
                            onChanged: (val) => setState(() => _selectedAnswer = val)
                        ),
                        _buildStandardTextField("Explanation", Colors.grey[200]!, maxLines: 1),
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
              // 1. LEFT SIDE: Complete Button
              // Wrap with Padding to act as a margin
              Padding(
                padding: const EdgeInsets.only(top: 16.0), // Your margin here!
                child: SizedBox(
                  width: 200,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff3dcf00),
                    ),
                    onPressed: () {},
                    child: const Text("Complete", style: TextStyle(color: Colors.white)),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      setState(() {
                        _totalQuestions += 1;
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