import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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
      int localVer = localVersions[fileName] ??
          0; // 0 means we don't have it yet

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
      final storageRef = FirebaseStorage.instance.ref().child(
          'syllabus_json/$fileName');
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
      // 1. Read from the downloaded OTA updates if available
      return await localFile.readAsString();
    } else {
      // 2. FALLBACK: Read the default file bundled with the app!
      try {
        return await rootBundle.loadString('assets/json/$fileName');
      } catch (e) {
        // If it's completely missing from both places, throw a helpful error
        throw Exception(
            'Critical Error: $fileName not found in Storage or Assets.');
      }
    }
  }

  // 4. Download a file and report the progress back to the UI!
  static Future<void> downloadFileWithProgress({
    required String fileName,
    required Function(double) onProgress,
  }) async {
    // Note: Ensure this matches your actual Firebase Storage path!
    final storageRef = FirebaseStorage.instance.ref().child(fileName);

    Directory appDocDir = await getApplicationDocumentsDirectory();
    File localFile = File('${appDocDir.path}/$fileName');

    // Start the download task
    final downloadTask = storageRef.writeToFile(localFile);

    // Listen to the stream to calculate the percentage
    downloadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (snapshot.totalBytes > 0) {
        // Calculate the percentage (e.g., 0.50 for 50%)
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;

        // Send that number back to the screen!
        onProgress(progress);
      }
    });

    // Wait for the entire download to finish before moving on
    await downloadTask;
  }
}
