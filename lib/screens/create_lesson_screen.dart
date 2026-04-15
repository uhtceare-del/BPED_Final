import 'dart:typed_data'; // ADDED: For handling raw bytes on Web
import 'package:flutter/foundation.dart'
    show kIsWeb; // ADDED: To check if running on Web
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/class_model.dart';
import '../models/lesson_model.dart';
import '../providers/class_provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/cloudinary_provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/dashboard_module.dart';

class CreateLessonScreen extends ConsumerStatefulWidget {
  const CreateLessonScreen({super.key});

  @override
  ConsumerState<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends ConsumerState<CreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedClassId;

  // --- NEW: SAFE FILE HANDLING VARIABLES ---
  String? _localFilePath; // Used for Mobile
  Uint8List? _fileBytes; // Used for Web
  String? _fileName; // Used for both to check extensions

  bool _isUploading = false;

  Future<void> _pickFile() async {
    // FIXED: Added withData: true which is REQUIRED for Web to grab bytes!
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4'],
      withData: kIsWeb,
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        if (kIsWeb) {
          // WEB: Grab the raw bytes safely
          _fileBytes = result.files.single.bytes;
        } else {
          // MOBILE: Grab the physical path safely
          _localFilePath = result.files.single.path;
        }
      });
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate() || _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select a class"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final classes = ref.read(allClassesProvider).value ?? const <ClassModel>[];
    ClassModel? selectedClass;
    for (final cls in classes) {
      if (cls.id == _selectedClassId) {
        selectedClass = cls;
        break;
      }
    }
    if (selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selected class was not found."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? remoteUrl;

      // --- SAFE UPLOAD LOGIC FOR WEB & MOBILE ---
      if (kIsWeb && _fileBytes != null) {
        // IMPORTANT: Your cloudinaryProvider needs an 'uploadFileBytes' function to accept web bytes!
        // We will pass the bytes and the filename to it.
        remoteUrl = await ref
            .read(cloudinaryProvider)
            .uploadFileBytes(_fileBytes!, _fileName!);
      } else if (!kIsWeb && _localFilePath != null) {
        remoteUrl = await ref
            .read(cloudinaryProvider)
            .uploadFile(_localFilePath!);
      }

      // FIXED: Check the extension using the _fileName instead of path
      final isVideo =
          _fileName != null && _fileName!.toLowerCase().endsWith('.mp4');
      final isPdf =
          _fileName != null && _fileName!.toLowerCase().endsWith('.pdf');

      final newLesson = LessonModel(
        id: '',
        courseId: _selectedClassId!,
        classId: _selectedClassId!,
        subject: selectedClass.subject,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: selectedClass.subject,
        videoUrl: isVideo ? remoteUrl : null,
        pdfUrl: isPdf ? remoteUrl : null,
        instructorId: user.uid,
      );

      await ref.read(lessonRepositoryProvider).addLesson(newLesson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lesson published successfully!"),
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final classesAsync = ref.watch(allClassesProvider);
    final instructorClasses = (classesAsync.value ?? const <ClassModel>[])
        .where((cls) => cls.instructorId == user?.uid)
        .toList();
    ClassModel? selectedClass;
    for (final cls in instructorClasses) {
      if (cls.id == _selectedClassId) {
        selectedClass = cls;
        break;
      }
    }

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: DashboardModulePage(
              title: 'Create New Lesson',
              subtitle:
                  'Publish curriculum to a specific class so the subject and audience stay aligned.',
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  DashboardSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Curriculum Details',
                          style: TextStyle(
                            color: kNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose the class first. The subject will follow the class record automatically.',
                          style: TextStyle(
                            color: kNavy.withValues(alpha: 0.62),
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (classesAsync.isLoading)
                          const Center(
                            child: CircularProgressIndicator(color: kNavy),
                          )
                        else if (instructorClasses.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Text(
                              "Create a class first before uploading curriculum.",
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Assign to Class",
                            ),
                            initialValue: _selectedClassId,
                            items: instructorClasses.map((cls) {
                              return DropdownMenuItem(
                                value: cls.id,
                                child: Text(
                                  '${cls.className} • ${cls.subject}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: kNavy,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedClassId = val),
                          ),
                        const SizedBox(height: 20),
                        if (selectedClass != null) ...[
                          DashboardTag(
                            label: 'Subject: ${selectedClass.subject}',
                            color: kNavy,
                            icon: Icons.auto_stories_outlined,
                          ),
                          const SizedBox(height: 20),
                        ],
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Lesson Title',
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Please enter a title'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: kNavyTint,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kNavyBorder),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: kNavy.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.attach_file,
                                color: kNavy,
                              ),
                            ),
                            title: Text(
                              _fileName == null
                                  ? "Attach Video or PDF (Optional)"
                                  : "File Selected",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              _fileName ?? "No file chosen",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: kNavy,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.cloud_upload, size: 18),
                              label: const Text("BROWSE"),
                              onPressed: _pickFile,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    onPressed: _isUploading ? null : _saveLesson,
                    child: _isUploading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'PUBLISH LESSON',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.6,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
