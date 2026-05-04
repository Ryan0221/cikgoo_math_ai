import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminContentService {

  /// Uploads modified JSON data to Cloud Storage and triggers an OTA update for all users.
  /// [fileName] e.g., 'f4c1.json'
  /// [updatedData] The complete, modified Dart Map containing all chapter data.
  static Future<void> pushContentUpdate(String fileName, Map<String, dynamic> updatedData) async {
    try {
      // 1. Convert the Dart Map back to a JSON string.
      // Using withIndent('  ') makes it readable if you ever open it on your computer.
      String jsonString = const JsonEncoder.withIndent('  ').convert(updatedData);

      // 2. Upload directly to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('syllabus_json/$fileName');

      await storageRef.putString(
        jsonString,
        format: PutStringFormat.raw,
        metadata: SettableMetadata(contentType: 'application/json'),
      );
      print("Upload to Storage complete.");

      // 3. Trigger the OTA Update by incrementing the version in Firestore
      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('content_updates')
          .update({
        // FieldValue.increment(1) mathematically adds 1 to whatever the current number is
        fileName: FieldValue.increment(1)
      });
      print("Firestore version bumped.");

      // 4. Update the Admin's local version tracking so they don't immediately download their own upload
      await _updateAdminLocalVersion(fileName);

    } catch (e) {
      print("Error pushing content update: $e");
      // Show an error snackbar to the admin here
    }
  }

  // Helper method to keep the admin's local device in sync
  static Future<void> _updateAdminLocalVersion(String fileName) async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch the newly incremented version from Firestore
    DocumentSnapshot config = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('content_updates')
        .get();

    int newCloudVersion = config.get(fileName);

    // Update local SharedPreferences map
    String localVersionsString = prefs.getString('local_file_versions') ?? '{}';
    Map<String, dynamic> localVersions = json.decode(localVersionsString);

    localVersions[fileName] = newCloudVersion;
    await prefs.setString('local_file_versions', json.encode(localVersions));
  }
}