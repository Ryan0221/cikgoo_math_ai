import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFeedbackPanel extends StatelessWidget {
  const UserFeedbackPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "• Swipe left or right to delete resolved feedback",
            style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
                fontSize: 13
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Listens to the 'feedback' collection in real-time!
            stream: FirebaseFirestore.instance
                .collection('feedback')
                .orderBy('timestamp', descending: true) // Newest first
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong loading feedback.'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              // Empty State
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No feedback submitted yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                );
              }

              // The Feedback List
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String docId = docs[index].id;

                  // Fallbacks in case a field is missing
                  String title = data['title'] ?? 'User Report';
                  String chapterName = data['chapter_name'] ?? 'Unknown Chapter';
                  String questionName = data['question_text'] ?? 'Unknown Question';
                  String description = data['description'] ?? 'No description provided.';

                  return Dismissible(
                    key: Key(docId),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.green, // Swipe to resolve/delete
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
                    ),
                    onDismissed: (direction) async {
                      // Delete the feedback document from Firebase once resolved
                      await FirebaseFirestore.instance.collection('feedback').doc(docId).delete();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Feedback marked as resolved and removed.'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[300], // Matches the mockup's light grey
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("• Chapter Name: $chapterName", style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                              "• Question Name: $questionName",
                              style: TextStyle(color: Colors.grey[800], fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis
                          ),
                          const SizedBox(height: 4),
                          Text("• Description: $description", style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}