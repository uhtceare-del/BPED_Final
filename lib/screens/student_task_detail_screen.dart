import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/task_model.dart';
import '../models/submission_model.dart';
import '../providers/submission_provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';
import '../providers/cloudinary_provider.dart'; // UNCOMMENTED

class StudentTaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;
  const StudentTaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<StudentTaskDetailScreen> createState() =>
      _StudentTaskDetailScreenState();
}

class _StudentTaskDetailScreenState
    extends ConsumerState<StudentTaskDetailScreen> {
  bool _isUploading = false;

  Future<void> _submitPerformance() async {
    // 1. Pick Video/File safely for Web and Mobile
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: kIsWeb, // REQUIRED for Chrome
    );

    if (result != null) {
      final file = result.files.single;
      setState(() => _isUploading = true);

      try {
        // 2. Upload to Cloudinary using Web or Mobile logic
        String? uploadedUrl;
        if (kIsWeb && file.bytes != null) {
          uploadedUrl = await ref
              .read(cloudinaryProvider)
              .uploadFileBytes(file.bytes!, file.name);
        } else if (file.path != null) {
          uploadedUrl = await ref
              .read(cloudinaryProvider)
              .uploadFile(file.path!);
        }

        if (uploadedUrl == null) throw Exception("Upload failed");

        // 3. Save Submission to Firestore with the Master Key
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser == null) throw Exception("User not authenticated");

        final submission = SubmissionModel(
          id: '',
          taskId: widget.task.id,
          studentId: currentUser.uid,
          studentEmail: currentUser.email ?? 'No Email',
          submittedAt: DateTime.now(),
          grade: null,
          fileUrl: uploadedUrl, // Stores the performance link
          instructorId: widget.task.instructorId, // THE MASTER KEY
        );

        await ref
            .read(submissionRepositoryProvider)
            .createSubmission(submission);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Task submitted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Task Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kNavy,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Max Score: ${widget.task.maxScore} pts",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 32),
            const Text(
              "Instructions:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              widget.task.description,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isUploading ? null : _submitPerformance,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(
                  _isUploading
                      ? "Uploading Performance..."
                      : "Upload Performance Video",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
