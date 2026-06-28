import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class ContentManager {

  static Future<void> checkForUpdates() async {
    try { // <-- NEW: The ultimate safety net
      final prefs = await SharedPreferences.getInstance();

      // 1. Get the local versions map from the phone
      String localVersionsString = prefs.getString('local_file_versions') ?? '{}';
      Map<String, dynamic> localVersions = json.decode(localVersionsString);

      // 2. Get the cloud versions map from Firestore
      DocumentSnapshot config = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('content_updates')
          .get();

      // NEW: Safely exit if the document doesn't exist yet!
      if (!config.exists || config.data() == null) {
        debugPrint("No OTA updates found in Firebase.");
        return;
      }

      Map<String, dynamic> cloudVersions = config.data() as Map<String, dynamic>;
      bool changesMade = false;

      // 3. Compare them file by file
      for (String fileName in cloudVersions.keys) {

        // NEW: Safely parse the numbers so it never crashes on weird data types
        int cloudVer = cloudVersions[fileName] is int
            ? cloudVersions[fileName]
            : int.tryParse(cloudVersions[fileName].toString()) ?? 0;

        int localVer = localVersions[fileName] ?? 0;

        // If the cloud has a higher number, download JUST this file!
        if (cloudVer > localVer) {
          await _downloadSingleFile(fileName);
          localVersions[fileName] = cloudVer;
          changesMade = true;
        }
      }

      // 4. Save the new map back to SharedPreferences
      if (changesMade) {
        await prefs.setString('local_file_versions', json.encode(localVersions));
      }

    } catch (e) {
      // NEW: If anything fails (no internet, firebase error), it catches it here
      // and allows the app to continue booting up offline!
      debugPrint("OTA Update Check Bypassed (Offline or Error): $e");
    }
  }

  // Helper method to download a specific file
  static Future<void> _downloadSingleFile(String fileName) async {
    try {
      // 1. UPDATED: Path changed to data_json
      final storageRef = FirebaseStorage.instance.ref().child('data_json/$fileName');
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$fileName');

      await storageRef.writeToFile(localFile);
      print("Successfully downloaded update for: $fileName");
    } catch (e) {
      print("Error downloading $fileName: $e");
    }
  }

// --- STRICT CLOUD MODE: Reads ONLY from downloaded device storage ---
  static Future<String> readLocalJson(String fullOrPartialPath) async {
    // 1. Clean the filename
    String safeFileName = fullOrPartialPath.split('/').last;

    // 2. Look in the secure app sandbox
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File localFile = File('${appDocDir.path}/$safeFileName');

    // 3. Strict Check: Does it exist?
    if (await localFile.exists()) {
      debugPrint("SUCCESS: Reading $safeFileName from downloaded device storage.");
      return await localFile.readAsString();
    } else {
      // 4. THE WALL: Instead of reading assets, we force a crash/error!
      debugPrint("ERROR: $safeFileName is missing from local storage.");
      throw Exception("STRICT MODE: File $safeFileName has not been downloaded from Firebase yet.");
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

  // --- NEW: UPLOAD ENGINE ---
  static Future<void> uploadFileToCloud(File file, String cloudPath) async {
    try {
      // Points to the specific folder and file name in Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(cloudPath);

      // Upload the file!
      await storageRef.putFile(file);

      debugPrint("SUCCESS: Uploaded to $cloudPath");
    } catch (e) {
      debugPrint("Upload error: $e");
      throw Exception("Failed to upload file to cloud: $e");
    }
  }
}

class ContentDownloadService {
  /// Downloads a specific JSON file from Firebase and saves it to local app storage
  static Future<File> downloadFileFromCloud(String fileName) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$fileName');

      // 2. UPDATED: Path changed to data_json
      Reference storageRef = FirebaseStorage.instance.ref().child('data_json/$fileName');

      await storageRef.writeToFile(localFile);

      print("SUCCESS: Downloaded $fileName from Firebase on-demand.");
      return localFile;
    } catch (e) {
      print("CRITICAL: Failed to download $fileName from Firebase: $e");
      throw Exception("Cloud connection failed. Cannot fetch mandatory file: $fileName");
    }
  }
}