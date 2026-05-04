import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContentManager {

  static Future<void> checkForUpdates() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get the local versions map from the phone (saved as a JSON string)
    String localVersionsString = prefs.getString('local_file_versions') ?? '{}';
    Map<String, dynamic> localVersions = json.decode(localVersionsString);

    // 2. Get the cloud versions map from Firestore
    DocumentSnapshot config = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('content_updates')
        .get();

    Map<String, dynamic> cloudVersions = config.data() as Map<String, dynamic>;
    bool changesMade = false;

    // 3. Compare them file by file
    for (String fileName in cloudVersions.keys) {
      int cloudVer = cloudVersions[fileName];
      int localVer = localVersions[fileName] ?? 0; // 0 means we don't have it yet

      // If the cloud has a higher number, download JUST this file!
      if (cloudVer > localVer) {
        await _downloadSingleFile(fileName);

        // Update our local tracking map
        localVersions[fileName] = cloudVer;
        changesMade = true;
      }
    }

    // 4. If we downloaded anything, save the new map back to SharedPreferences
    if (changesMade) {
      await prefs.setString('local_file_versions', json.encode(localVersions));
    }
  }

  // Helper method to download a specific file
  static Future<void> _downloadSingleFile(String fileName) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('syllabus_json/$fileName');
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$fileName');

      await storageRef.writeToFile(localFile);
      print("Successfully downloaded update for: $fileName");
    } catch (e) {
      print("Error downloading $fileName: $e");
    }
  }

// 3. Read the JSON from the hard drive (Use this instead of rootBundle.loadString)
  static Future<String> readLocalJson(String fileName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File localFile = File('${appDocDir.path}/$fileName');

    if (await localFile.exists()) {
      return await localFile.readAsString();
    } else {
      // Fallback: If it's not downloaded yet, load the default one from assets
      // return await rootBundle.loadString('assets/json/$fileName');
      throw Exception('File not found');
    }
  }
}