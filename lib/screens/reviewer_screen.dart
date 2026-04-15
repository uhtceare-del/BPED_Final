import '../constants/app_colors.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/reviewer_provider.dart';
import '../providers/class_provider.dart';
import '../providers/cloudinary_provider.dart';
import '../providers/auth_provider.dart';
import '../models/reviewer_model.dart';
import '../services/soft_delete_service.dart';
import '../widgets/pdf_viewer_widget.dart';
import '../widgets/dashboard_module.dart';

class ReviewerScreen extends ConsumerStatefulWidget {
  const ReviewerScreen({super.key});

  @override
  ConsumerState<ReviewerScreen> createState() => _ReviewerScreenState();
}

class _ReviewerScreenState extends ConsumerState<ReviewerScreen> {
  final Map<String, bool> _downloadingMap = {};
  final Map<String, double> _progressMap = {};

  void _viewReviewer(ReviewerModel reviewer) {
    if (reviewer.fileUrl.isEmpty) {
      _snack('No file URL found for this reviewer.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerWidget(
          title: reviewer.title,
          urlOrPath: reviewer.fileUrl,
          isOffline: false,
        ),
      ),
    );
  }

  Future<void> _downloadAndOpen(ReviewerModel reviewer) async {
    if (reviewer.fileUrl.isEmpty) {
      _snack('No file URL found.');
      return;
    }
    if (_downloadingMap[reviewer.id] == true) return;

    setState(() {
      _downloadingMap[reviewer.id] = true;
      _progressMap[reviewer.id] = 0.0;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final safeFileName = reviewer.title.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-]'),
        '_',
      );
      final savePath = '${directory.path}/${safeFileName}_${reviewer.id}.pdf';
      final file = File(savePath);

      if (!await file.exists()) {
        final dio = Dio();
        await dio.download(
          reviewer.fileUrl,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1 && mounted) {
              setState(() => _progressMap[reviewer.id] = received / total);
            }
          },
        );
      }

      if (mounted) _snack('Download complete. Opening…');
      final result = await OpenFile.open(savePath);
      if (result.type != ResultType.done && mounted) {
        _snack('Could not open file: ${result.message}');
      }
    } catch (e) {
      if (mounted) _snack('Download failed: $e');
    } finally {
      if (mounted) setState(() => _downloadingMap[reviewer.id] = false);
    }
  }

  Future<void> _deleteReviewer(
    BuildContext context,
    ReviewerModel reviewer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Reviewer',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          "Move '${reviewer.title}' to trash? You can restore it within 30 days.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SoftDeleteService().softDelete('reviewers', reviewer.id);
      if (mounted) _snack('Reviewer moved to trash.');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final reviewersAsync = ref.watch(allReviewersProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isInstructor = currentUser?.role.toLowerCase() == 'instructor';

    return DashboardModulePage(
      title: 'Reviewers',
      subtitle: isInstructor
          ? 'Publish reviewer PDFs by class and subject so students can access the right materials.'
          : 'Browse reviewer PDFs assigned to your classes and open them directly from the portal.',
      floatingActionButton: isInstructor
          ? FloatingActionButton.extended(
              backgroundColor: kNavy,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => const _UploadReviewerSheet(),
              ),
              label: const Text(
                'Upload Reviewer',
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.upload_file, color: Colors.white),
            )
          : null,
      child: reviewersAsync.when(
        data: (reviewers) {
          if (reviewers.isEmpty) return _buildEmptyState(isInstructor);

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: reviewers.length,
            itemBuilder: (context, index) {
              final reviewer = reviewers[index];
              final isDownloading = _downloadingMap[reviewer.id] ?? false;
              final progress = _progressMap[reviewer.id] ?? 0.0;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reviewer.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: kNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                DashboardTag(
                                  label: reviewer.subject.isNotEmpty
                                      ? reviewer.subject
                                      : reviewer.category,
                                  color: kNavy,
                                ),
                                if (reviewer.classId.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  _ClassBadge(classId: reviewer.classId),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Instructor actions
                      if (isInstructor)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                color: Colors.blueAccent,
                              ),
                              tooltip: 'Preview',
                              onPressed: () => _viewReviewer(reviewer),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Delete',
                              onPressed: () =>
                                  _deleteReviewer(context, reviewer),
                            ),
                          ],
                        )
                      // Student actions
                      else if (isDownloading)
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            value: progress > 0 ? progress : null,
                            strokeWidth: 3,
                            color: kNavy,
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                color: Colors.blueAccent,
                              ),
                              tooltip: 'View PDF',
                              onPressed: () => _viewReviewer(reviewer),
                            ),
                            if (!kIsWeb)
                              IconButton(
                                icon: const Icon(
                                  Icons.download_outlined,
                                  color: Colors.blueGrey,
                                ),
                                tooltip: 'Download & Open',
                                onPressed: () => _downloadAndOpen(reviewer),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kNavy)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState(bool isInstructor) {
    return DashboardEmptyState(
      icon: Icons.picture_as_pdf_rounded,
      tone: Colors.red.shade700,
      title: 'No reviewers available',
      message: isInstructor
          ? 'Upload your first reviewer PDF to give students downloadable study material.'
          : 'Your instructors have not uploaded any reviewer PDFs for your classes yet.',
    );
  }
}

// ── Class badge (shows class name from ID) ────────────────────────────────────

class _ClassBadge extends ConsumerWidget {
  final String classId;
  const _ClassBadge({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(allClassesProvider);
    final classes = classesAsync.value ?? [];
    final cls = classes.where((c) => c.id == classId).firstOrNull;
    if (cls == null) return const SizedBox.shrink();
    return DashboardTag(label: cls.className, color: Colors.green.shade700);
  }
}

// ── Upload sheet ──────────────────────────────────────────────────────────────

class _UploadReviewerSheet extends ConsumerStatefulWidget {
  const _UploadReviewerSheet();

  @override
  ConsumerState<_UploadReviewerSheet> createState() =>
      _UploadReviewerSheetState();
}

class _UploadReviewerSheetState extends ConsumerState<_UploadReviewerSheet> {
  final _titleController = TextEditingController();
  String? _selectedSubject;
  String? _selectedClassId;

  String? _filePath;
  Uint8List? _fileBytes;
  String? _fileName;

  bool _isUploading = false;

  bool get _hasFile => kIsWeb ? _fileBytes != null : _filePath != null;

  final List<String> _subjects = [
    'Anatomy & Physiology',
    'Kinesiology',
    'Sports Psychology',
    'Pedagogy in PE',
    'Sports Technique',
    'Sports Management',
    'Team Sports',
    'Individual Sports',
    'Aquatics',
    'Dance & Rhythmic Activities',
    'Physical Fitness',
    'General',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FocusScope.of(context).unfocus();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() {
      _fileName = file.name;
      if (kIsWeb) {
        _fileBytes = file.bytes;
        _filePath = null;
      } else {
        _filePath = file.path;
        _fileBytes = null;
      }
    });
  }

  Future<void> _upload() async {
    if (_titleController.text.trim().isEmpty) {
      _snack('Please enter a title.');
      return;
    }
    if (_selectedSubject == null) {
      _snack('Please select a subject.');
      return;
    }
    if (_selectedClassId == null) {
      _snack(
        'Please select a class section — students will only see reviewers assigned to their class.',
      );
      return;
    }
    if (!_hasFile) {
      _snack('Please pick a PDF file first.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final cloudinary = ref.read(cloudinaryProvider);
      final instructorId =
          ref.read(authControllerProvider).currentUser?.uid ?? '';

      String? url;
      if (kIsWeb) {
        url = await cloudinary.uploadFileBytes(
          _fileBytes!,
          _fileName ?? 'reviewer.pdf',
        );
      } else {
        url = await cloudinary.uploadFile(_filePath!);
      }

      if (url == null || url.isEmpty) {
        throw Exception(
          'Cloudinary returned no URL. Check your upload preset allows raw files.',
        );
      }

      final reviewer = ReviewerModel(
        id: '',
        title: _titleController.text.trim(),
        fileUrl: url,
        category: _selectedSubject ?? 'General',
        subject: _selectedSubject!,
        classId: _selectedClassId!,
        uploadedAt: DateTime.now(),
        instructorId: instructorId,
      );

      await ref.read(reviewerRepositoryProvider).uploadReviewer(reviewer);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reviewer uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _snack('Upload failed: $e');
      }
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(allClassesProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 28,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Reviewer PDF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: kNavy,
              ),
            ),
            const SizedBox(height: 6),

            // Important note
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select the class section — only students in that class will see this reviewer.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              enabled: !_isUploading,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 14),

            // Subject dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedSubject,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: _subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: _isUploading
                  ? null
                  : (v) => setState(() => _selectedSubject = v),
            ),
            const SizedBox(height: 14),

            // Class picker — REQUIRED
            classesAsync.when(
              data: (classes) {
                if (classes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Text(
                      'No class sections found. Create a class first in the Classes tab.',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  );
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Class Section *',
                    prefixIcon: Icon(Icons.groups_outlined),
                    helperText:
                        'Required — determines which students can see this',
                  ),
                  hint: const Text('Select Class Section'),
                  items: classes
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.className} — ${c.subject}'),
                        ),
                      )
                      .toList(),
                  onChanged: _isUploading
                      ? null
                      : (v) => setState(() => _selectedClassId = v),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) =>
                  const Text('Could not load classes'),
            ),
            const SizedBox(height: 14),

            // File picker
            InkWell(
              onTap: _isUploading ? null : _pickFile,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _hasFile ? Colors.red.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _hasFile
                        ? Colors.red.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasFile ? Icons.picture_as_pdf : Icons.attach_file,
                      color: _hasFile ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fileName ?? 'Tap to pick a PDF file',
                        style: TextStyle(
                          color: _hasFile ? kGrey87 : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_hasFile)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.red,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upload button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isUploading ? null : _upload,
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Uploading…',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : const Text(
                        'UPLOAD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
