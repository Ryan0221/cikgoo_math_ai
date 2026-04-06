import 'package:flutter/material.dart';

class ViewContentPanel extends StatefulWidget {
  const ViewContentPanel({Key? key}) : super(key: key);

  @override
  State<ViewContentPanel> createState() => _ViewContentPanelState();
}

class _ViewContentPanelState extends State<ViewContentPanel> {
  // Pagination State
  int _currentPage = 1;
  final int _totalPages = 10;

  // Helper method to build the summary cards (Total Question / Total Answered)
  Widget _buildSummaryCard(String title, String value, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Title
          const Text(
            "Question Summary",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 2. Summary Cards Row
          Row(
            children: [
              _buildSummaryCard("Total Question", "100", Colors.black),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 32),

          // 3. Table Header
          const Text(
            "Questions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 4. Data Table Section
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // The scrollable table
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          dataRowMaxHeight: 60,
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Subject')),
                            DataColumn(label: Text('Level')),
                          ],
                          rows: const [
                            DataRow(cells: [
                              DataCell(Text('1')),
                              DataCell(Text('MCQ')),
                              DataCell(Text('Biology')),
                              DataCell(Text('F4')),
                            ]),
                            DataRow(cells: [
                              DataCell(Text('2')),
                              DataCell(Text('TF')),
                              DataCell(Text('Math')),
                              DataCell(Text('F5')),
                            ]),
                            DataRow(cells: [
                              DataCell(Text('3')),
                              DataCell(Text('Subjective')),
                              DataCell(Text('English')),
                              DataCell(Text('F1')),
                            ]),
                            DataRow(cells: [
                              DataCell(Text('4')),
                              DataCell(Text('MCQ')),
                              DataCell(Text('History')),
                              DataCell(Text('F3')),
                            ]),
                            DataRow(cells: [
                              DataCell(Text('5')),
                              DataCell(Text('TF')),
                              DataCell(Text('Science')),
                              DataCell(Text('F2')),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 5. Pagination Controls (Bottom)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Visibility(
                          visible: _currentPage > 1,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => setState(() => _currentPage--),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "$_currentPage / $_totalPages",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                          ),
                        ),
                        const SizedBox(width: 16),
                        Visibility(
                          visible: _currentPage < _totalPages,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => setState(() => _currentPage++),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}