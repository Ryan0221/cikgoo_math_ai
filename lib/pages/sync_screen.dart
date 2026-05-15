import 'package:flutter/material.dart';
import 'package:cikgoo_math_ai/services/content_manager.dart'; // Update this path!

class SyncScreen extends StatefulWidget {
  const SyncScreen({Key? key}) : super(key: key);

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  String _statusMessage = "Connecting to servers...";

  // NEW: State variables to track the download
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _runStartupSync();
  }

  Future<void> _runStartupSync() async {
    try {
      setState(() {
        _statusMessage = "Checking for syllabus updates...";
      });

      // TODO: Here you would normally check your app_config document to see if
      // the version numbers changed. For this example, we assume an update is needed.
      bool needsUpdate = true;

      if (needsUpdate) {
        setState(() {
          _isDownloading = true; // Turn on the progress bar UI
          _statusMessage = "Downloading new syllabus data...";
        });

        // 2. Call our new download function and listen to the progress!
        await ContentManager.downloadFileWithProgress(
          fileName: 'subjects-chapters-subtopics.json',
          onProgress: (progress) {
            setState(() {
              _downloadProgress = progress; // Update the UI in real-time
            });
          },
        );
      }

      setState(() {
        _isDownloading = false; // Hide the progress bar
        _statusMessage = "Updates complete! Preparing app...";
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        // Navigate to the actual Home Screen
        Navigator.pushReplacementNamed(context, '/home');
      }

    } catch (e) {
      print("Sync failed, proceeding offline: $e");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch the progress bar
          children: [
            const Icon(Icons.school, size: 80, color: Color(0xFF223257)),
            const SizedBox(height: 40),

            // 3. DYNAMIC UI: Show spinner OR progress bar
            if (_isDownloading) ...[
              // The animated bar filling up
              LinearProgressIndicator(
                value: _downloadProgress, // Links directly to the stream!
                backgroundColor: Colors.grey[300],
                color: const Color(0xFF223257),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 12),
              // The text showing "45%"
              Text(
                "${(_downloadProgress * 100).toStringAsFixed(0)}%",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ] else ...[
              // Just a standard spinner while checking the database
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF223257)),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}