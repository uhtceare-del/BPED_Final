import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';

// --- THE FIX: REAL FIREBASE STREAM PROVIDER ---
// This fetches reviewers from Firestore instead of fake local memory
final instructorReviewersProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);

      // Fetch only reviewers uploaded by this specific instructor
      return FirebaseFirestore.instance
          .collection('reviewers')
          .where('instructorId', isEqualTo: user.uid)
          .orderBy('uploadedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );
    });
// ------------------------------------------------

class InstructorReviewerScreen extends ConsumerStatefulWidget {
  const InstructorReviewerScreen({super.key});

  @override
  ConsumerState<InstructorReviewerScreen> createState() =>
      _InstructorReviewerScreenState();
}

class _InstructorReviewerScreenState
    extends ConsumerState<InstructorReviewerScreen> {

  bool _isUploading = false;

  // --- NEW: UPLOAD & LINK TO CLASS ---
  Future<void> _pickAndUploadFile() async {
    // 1. Pick the file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
    );

    if (result == null || result.files.single.path == null) return;

    PlatformFile file = result.files.first;
    File fileToUpload = File(file.path!);
    final user = ref.read(currentUserProvider).value;

    if (user == null) return;

    // 2. Ask the instructor which class this belongs to BEFORE uploading
    String? selectedClassId = await _showSelectClassDialog(user.uid);

    if (selectedClassId == null) {
      // Instructor cancelled the dialog
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 3. Upload the physical file to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
        'reviewers/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
      );

      final uploadTask = await storageRef.putFile(fileToUpload);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 4. Save the link and the CLASS ID to Firestore Database
      await FirebaseFirestore.instance.collection('reviewers').add({
        'name': file.name,
        'size': '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB',
        'fileUrl': downloadUrl,
        'instructorId': user.uid,
        'classId': selectedClassId, // THIS IS THE MAGIC LINK!
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Material uploaded and linked to class!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isUploading = false);
  }

  // --- NEW: DIALOG TO PICK A CLASS ---
  Future<String?> _showSelectClassDialog(String instructorId) async {
    // Fetch the instructor's classes from Firestore
    final classesSnapshot = await FirebaseFirestore.instance
        .collection(
          'classes',
        ) // Check if your collection is 'classes' or 'courses'!
        .get(); // Note: You might want to filter this by instructorId if needed

    final classes = classesSnapshot.docs;

    if (classes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You need to create a class first!"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return null;
    }

    String? chosenClassId;

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Assign to Class",
                style: TextStyle(color: kNavy, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Which class should see this reviewer?"),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Select a Class"),
                    value: chosenClassId,
                    items: classes.map((doc) {
                      final data = doc.data();
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(data['className'] ?? 'Unnamed Class'),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setDialogState(() => chosenClassId = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kNavy),
                  onPressed: chosenClassId == null
                      ? null
                      : () => Navigator.pop(context, chosenClassId),
                  child: const Text(
                    "CONTINUE",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // DELETE ACTUAL FILE FROM STORAGE AND FIRESTORE
  Future<void> _deleteFile(Map<String, dynamic> fileData) async {
    try {
      // 1. Delete from Firestore
      await FirebaseFirestore.instance
          .collection('reviewers')
          .doc(fileData['id'])
          .delete();

      // 2. Delete from Storage
      if (fileData['fileUrl'] != null) {
        await FirebaseStorage.instance.refFromURL(fileData['fileUrl']).delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("File permanently deleted."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // WATCH THE NEW REAL PROVIDER
    final uploadedFilesAsync = ref.watch(instructorReviewersProvider);

    return Scaffold(
      backgroundColor: kAcademicGray,
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        title: const Text(
          "Manage Reviewers & Handouts",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadFile,
        backgroundColor: kNavy,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.upload_file, color: Colors.white),
        label: Text(
          _isUploading ? "Uploading..." : "Upload Material",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: uploadedFilesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kNavy)),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (files) {
          if (files.isEmpty) return _buildEmptyState();
          return _buildFileList(files);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kNavy.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 80,
              color: kNavy.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Materials Uploaded",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "You haven't uploaded any reviewers or handouts for your students yet.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(List<Map<String, dynamic>> uploadedFiles) {
    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: uploadedFiles.length,
      itemBuilder: (context, index) {
        final file = uploadedFiles[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.redAccent,
              ),
            ),
            title: Text(
              file['name'] ?? 'Unknown File',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kNavy,
              ),
            ),
            subtitle: Text(
              "Size: ${file['size']} ",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: "Delete File",
              onPressed: () => _deleteFile(file), // CALLS REAL DELETE FUNCTION
            ),
          ),
        );
      },
    );
  }
}
