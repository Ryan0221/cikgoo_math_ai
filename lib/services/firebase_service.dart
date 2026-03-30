import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // 1. Point to a specific "folder" (collection) in your database
  // We will call it 'learning_path'
  final CollectionReference pathCollection = FirebaseFirestore.instance.collection('learning_path');

  // 2. Create a function to add a new course node
  Future<void> addPathNode(String id, bool isRevision, double alignX) async {
    try {
      // Use the 'id' as the document name so it's easy to find later
      await pathCollection.doc(id).set({
        'id': id,
        'isRevision': isRevision,
        'alignX': alignX,
        'createdAt': Timestamp.now(), // Always good to track when it was made
      });
      print("Node Added to Database!");
    } catch (e) {
      print("Error adding node: $e");
    }
  }
}