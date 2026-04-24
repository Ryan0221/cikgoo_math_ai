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
  String? _selectedType;
  String? _selectedAnswer;

  // Sample Options for Dropdowns
  final List<String> _subjects = ['Mathematics SPM Form 4', 'Mathematics SPM Form 5'];
  final List<String> _types = ['Quiz', 'Revision'];
  final List<String> _answers = ['Option 1', 'Option 2', 'Option 3', 'Option 4'];

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

  // Helper method for Dropdowns
  Widget _buildDropdown(String label, Color fillColor, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
          const SizedBox(height: 16),
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
                  _buildDropdown("Subject_Level", Colors.grey[350]!, _subjects, _selectedSubject, (val) => setState(() => _selectedSubject = val)),
                  _buildStandardTextField("Chapter Name", Colors.grey[350]!),
                  _buildDropdown("Type", Colors.grey[350]!, _types, _selectedType, (val) => setState(() => _selectedType = val)),

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
                        _buildImageTextField("Question", Colors.grey[200]!, maxLines: 1),
                        _buildStandardTextField("Hint", Colors.grey[200]!, maxLines: 1),
                        _buildImageTextField("Option 1", Colors.grey[200]!,),
                        _buildImageTextField("Option 2", Colors.grey[200]!,),
                        _buildImageTextField("Option 3", Colors.grey[200]!,),
                        _buildImageTextField("Option 4", Colors.grey[200]!,),
                        _buildDropdown("Answer", Colors.grey[200]!, _answers, _selectedAnswer, (val) {
                          setState(() => _selectedAnswer = val);
                        }),
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