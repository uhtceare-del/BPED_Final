import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/class_model.dart';
import '../models/lesson_model.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/supabase_storage_provider.dart';
import '../services/bped_curriculum_service.dart';
import '../widgets/dashboard_module.dart';
import 'lesson_detail_screen.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key});

  void _showManageLessonSheet(
    BuildContext context,
    WidgetRef ref, {
    required BpedCurriculumSubject subject,
    required List<ClassModel> classes,
    LessonModel? lesson,
  }) {
    final titleCtrl = TextEditingController(
      text: lesson?.title ?? subject.title,
    );
    final descCtrl = TextEditingController(text: lesson?.description ?? '');
    final matchingClasses = classes
        .where((cls) => _classMatchesSubject(cls, subject))
        .toList(growable: true);
    final existingClass = classes
        .where((cls) => cls.id == lesson?.classId)
        .firstOrNull;
    if (existingClass != null &&
        !matchingClasses.any((cls) => cls.id == existingClass.id)) {
      matchingClasses.insert(0, existingClass);
    }

    String? selectedClassId = lesson?.classId.isNotEmpty == true
        ? lesson!.classId
        : matchingClasses.firstOrNull?.id;
    String? filePath;
    Uint8List? fileBytes;
    String? fileName;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson == null
                      ? 'Add Curriculum Content'
                      : 'Edit Curriculum Content',
                  style: const TextStyle(
                    color: kNavy,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${subject.code} · ${BpedCurriculumService.formatYearLevel(subject.yearLevel)} · ${subject.semesterLabel}',
                  style: TextStyle(
                    color: kNavy.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Prospectus Subject',
                  ),
                  child: Text(
                    subject.label,
                    style: const TextStyle(
                      color: kNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (matchingClasses.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: const Text(
                      'No class section matches this prospectus subject yet. Create a class section first before attaching materials.',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Class',
                    ),
                    items: matchingClasses
                        .map(
                          (cls) => DropdownMenuItem(
                            value: cls.id,
                            child: Text(
                              '${cls.className} · ${cls.classCode}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (value) => setSheet(() => selectedClassId = value),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Content Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  enabled: !saving,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description / Notes',
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'mp4'],
                            withData: kIsWeb,
                          );
                          if (result == null || result.files.isEmpty) {
                            return;
                          }
                          final picked = result.files.single;
                          setSheet(() {
                            fileName = picked.name;
                            filePath = picked.path;
                            fileBytes = picked.bytes;
                          });
                        },
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    fileName == null
                        ? 'Attach PDF or Video'
                        : 'Attached: $fileName',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final trimmedTitle = titleCtrl.text.trim();
                            if (matchingClasses.isEmpty ||
                                selectedClassId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a matching class section first.',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (trimmedTitle.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Content title is required.'),
                                ),
                              );
                              return;
                            }

                            final selectedClass = matchingClasses
                                .where((cls) => cls.id == selectedClassId)
                                .firstOrNull;
                            final appUser =
                                ref.read(bootstrapAppUserProvider) ??
                                ref.read(currentUserProvider).value;
                            if (selectedClass == null || appUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Your session is not ready yet.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setSheet(() => saving = true);
                            try {
                              final storage = ref.read(supabaseStorageProvider);
                              String? uploadedUrl;
                              if (fileName != null) {
                                if (kIsWeb) {
                                  if (fileBytes == null) {
                                    throw Exception(
                                      'No file bytes were available for upload.',
                                    );
                                  }
                                  uploadedUrl = await storage.uploadFileBytes(
                                    fileBytes!,
                                    fileName!,
                                  );
                                } else {
                                  if (filePath == null || filePath!.isEmpty) {
                                    throw Exception(
                                      'No file path was available for upload.',
                                    );
                                  }
                                  uploadedUrl = await storage.uploadFile(
                                    filePath!,
                                  );
                                }
                              }

                              String? nextPdfUrl =
                                  lesson?.pdfUrl?.isNotEmpty == true
                                  ? lesson!.pdfUrl
                                  : null;
                              String? nextVideoUrl =
                                  lesson?.videoUrl?.isNotEmpty == true
                                  ? lesson!.videoUrl
                                  : null;

                              if (uploadedUrl != null) {
                                final mimeType = storage.detectMimeType(
                                  filename: fileName,
                                  bytes: fileBytes,
                                  filePath: filePath,
                                );
                                if (storage.isPdfMimeType(mimeType) ||
                                    fileName!.toLowerCase().endsWith('.pdf')) {
                                  nextPdfUrl = uploadedUrl;
                                } else {
                                  nextVideoUrl = uploadedUrl;
                                }
                              }

                              if (lesson == null) {
                                await ref
                                    .read(lessonRepositoryProvider)
                                    .addLesson(
                                      LessonModel(
                                        id: '',
                                        courseId: selectedClass.id,
                                        classId: selectedClass.id,
                                        subject: subject.label,
                                        title: trimmedTitle,
                                        description: descCtrl.text.trim(),
                                        category: subject.label,
                                        videoUrl: nextVideoUrl,
                                        pdfUrl: nextPdfUrl,
                                        instructorId: appUser.uid,
                                      ),
                                    );
                              } else {
                                await ref
                                    .read(lessonRepositoryProvider)
                                    .updateLesson(lesson.id, {
                                      'courseId': selectedClass.id,
                                      'classId': selectedClass.id,
                                      'subject':
                                          BpedCurriculumService.normalizeStoredSubject(
                                            subject.label,
                                          ),
                                      'category':
                                          BpedCurriculumService.normalizeStoredSubject(
                                            subject.label,
                                          ),
                                      'title': trimmedTitle,
                                      'description': descCtrl.text.trim(),
                                      'pdfUrl': nextPdfUrl,
                                      'videoUrl': nextVideoUrl,
                                    });
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      lesson == null
                                          ? 'Curriculum content added.'
                                          : 'Curriculum content updated.',
                                    ),
                                  ),
                                );
                              }
                            } catch (error) {
                              setSheet(() => saving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $error')),
                                );
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            lesson == null
                                ? 'SAVE TO CURRICULUM'
                                : 'SAVE CHANGES',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteLessonDialog(
    BuildContext context,
    WidgetRef ref,
    LessonModel lesson,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move Lesson to Trash'),
        content: Text(
          "Move '${lesson.title}' to trash? You can restore it later from the Recovery Center.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final deletedBy = ref
                    .read(authControllerProvider)
                    .currentUser
                    ?.uid;
                await adminDeleteLesson(lesson.id, deletedBy: deletedBy);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lesson moved to trash.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
                }
              }
            },
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsForCurrentUserProvider);
    final classesAsync = ref.watch(allClassesProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final role = currentUser?.role.toLowerCase() ?? '';
    final canManage = role == 'admin' || role == 'instructor';
    final lessons = lessonsAsync.value ?? const <LessonModel>[];
    final classes = classesAsync.value ?? const <ClassModel>[];
    final classesById = {for (final cls in classes) cls.id: cls};

    return DashboardModulePage(
      title: 'Curriculum',
      subtitle: canManage
          ? 'The BPED prospectus defines the curriculum. Add descriptions, files, and lesson materials under each fixed subject entry.'
          : 'Browse the full BPED program curriculum by year level and semester.',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          DashboardSectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.library_books_outlined,
                        color: kNavy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        canManage
                            ? 'Prospectus-Based Curriculum'
                            : 'BPED Curriculum Reference',
                        style: const TextStyle(
                          color: kNavy,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  canManage
                      ? 'Use the fixed BPED prospectus structure below, then attach notes, files, and lesson materials to each subject.'
                      : 'Browse all BPED subjects by year level and semester. Shared materials appear under each subject when available.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (lessonsAsync.isLoading || classesAsync.isLoading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(color: kNavy),
          ],
          if (lessonsAsync.hasError) ...[
            const SizedBox(height: 16),
            _StatusBanner(
              tone: Colors.red.shade700,
              message: 'Lesson materials could not be loaded right now.',
            ),
          ],
          if (classesAsync.hasError && canManage) ...[
            const SizedBox(height: 16),
            _StatusBanner(
              tone: Colors.red.shade700,
              message:
                  'Class sections could not be loaded, so curriculum editing is temporarily limited.',
            ),
          ],
          const SizedBox(height: 18),
          ...[1, 2, 3, 4].map((yearLevel) {
            final yearSubjects = BpedCurriculumService.subjectsFor(
              yearLevel: yearLevel,
            );
            if (yearSubjects.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _YearSection(
                title: BpedCurriculumService.formatYearLevel(yearLevel),
                children: ['1st Semester', '2nd Semester']
                    .map((semesterLabel) {
                      final semesterSubjects = yearSubjects
                          .where(
                            (subject) => subject.semesterLabel == semesterLabel,
                          )
                          .toList(growable: false);
                      if (semesterSubjects.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return _SemesterSection(
                        title: semesterLabel,
                        children: semesterSubjects
                            .map((subject) {
                              final subjectLessons =
                                  lessons
                                      .where(
                                        (lesson) => _lessonMatchesSubject(
                                          lesson,
                                          subject,
                                          classesById,
                                        ),
                                      )
                                      .toList(growable: false)
                                    ..sort(
                                      (a, b) => a.title.compareTo(b.title),
                                    );
                              final eligibleClasses = classes
                                  .where(
                                    (cls) => _classMatchesSubject(cls, subject),
                                  )
                                  .toList(growable: false);

                              return _SubjectCard(
                                subject: subject,
                                lessons: subjectLessons,
                                classesById: classesById,
                                canManage: canManage,
                                hasMatchingClass: eligibleClasses.isNotEmpty,
                                onAddContent: canManage
                                    ? () => _showManageLessonSheet(
                                        context,
                                        ref,
                                        subject: subject,
                                        classes: classes,
                                      )
                                    : null,
                                onEditLesson: canManage
                                    ? (lesson) => _showManageLessonSheet(
                                        context,
                                        ref,
                                        subject: subject,
                                        classes: classes,
                                        lesson: lesson,
                                      )
                                    : null,
                                onDeleteLesson: canManage
                                    ? (lesson) => _showDeleteLessonDialog(
                                        context,
                                        ref,
                                        lesson,
                                      )
                                    : null,
                              );
                            })
                            .toList(growable: false),
                      );
                    })
                    .toList(growable: false),
              ),
            );
          }),
        ],
      ),
    );
  }

  static bool _classMatchesSubject(
    ClassModel cls,
    BpedCurriculumSubject subject,
  ) {
    final normalizedSemester = BpedCurriculumService.normalizeSemesterLabel(
      cls.semesterLabel,
    );
    return cls.yearLevel == subject.yearLevel &&
        normalizedSemester == subject.semesterLabel &&
        subject.matches(cls.subject);
  }

  static bool _lessonMatchesSubject(
    LessonModel lesson,
    BpedCurriculumSubject subject,
    Map<String, ClassModel> classesById,
  ) {
    final label = lesson.subject.trim().isNotEmpty
        ? lesson.subject
        : (lesson.category ?? '');
    if (!subject.matches(label)) {
      return false;
    }

    final lessonClass = classesById[lesson.classId];
    if (lessonClass == null) {
      return true;
    }

    return _classMatchesSubject(lessonClass, subject);
  }
}

class _YearSection extends StatelessWidget {
  const _YearSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.school_outlined, color: kNavy, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: kNavy,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        ...children.where((child) => child is! SizedBox),
      ],
    );
  }
}

class _SemesterSection extends StatelessWidget {
  const _SemesterSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: kNavy.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: kNavy,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.lessons,
    required this.classesById,
    required this.canManage,
    required this.hasMatchingClass,
    this.onAddContent,
    this.onEditLesson,
    this.onDeleteLesson,
  });

  final BpedCurriculumSubject subject;
  final List<LessonModel> lessons;
  final Map<String, ClassModel> classesById;
  final bool canManage;
  final bool hasMatchingClass;
  final VoidCallback? onAddContent;
  final ValueChanged<LessonModel>? onEditLesson;
  final ValueChanged<LessonModel>? onDeleteLesson;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: kNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: kNavy,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${subject.code} - ${subject.title}',
                        style: const TextStyle(
                          color: kNavy,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MiniTag(
                            label:
                                '${lessons.length} material${lessons.length == 1 ? '' : 's'}',
                            color: kNavy,
                            icon: Icons.layers_outlined,
                          ),
                          const _MiniTag(
                            label: 'Prospectus',
                            color: Colors.indigo,
                            icon: Icons.library_books_outlined,
                          ),
                          if (canManage && !hasMatchingClass)
                            const _MiniTag(
                              label: 'No class section yet',
                              color: Colors.orange,
                              icon: Icons.warning_amber_outlined,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canManage)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: OutlinedButton(
                      onPressed: hasMatchingClass ? onAddContent : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(lessons.isEmpty ? 'Add' : 'Manage'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              lessons.isEmpty
                  ? canManage
                        ? 'This subject already exists in the prospectus. Add materials, notes, or media when you are ready.'
                        : 'This prospectus subject does not have shared materials yet.'
                  : 'Attached curriculum content',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            if (lessons.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...lessons.map(
                (lesson) => _LessonContentTile(
                  lesson: lesson,
                  classModel: classesById[lesson.classId],
                  canManage: canManage,
                  onEdit: onEditLesson == null
                      ? null
                      : () => onEditLesson!(lesson),
                  onDelete: onDeleteLesson == null
                      ? null
                      : () => onDeleteLesson!(lesson),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonContentTile extends StatelessWidget {
  const _LessonContentTile({
    required this.lesson,
    required this.classModel,
    required this.canManage,
    this.onEdit,
    this.onDelete,
  });

  final LessonModel lesson;
  final ClassModel? classModel;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;
    final hasPdf = lesson.pdfUrl != null && lesson.pdfUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: canManage || hasPdf || hasVideo
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonDetailScreen(lesson: lesson),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: const TextStyle(
                        color: kNavy,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (canManage)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blueAccent,
                          ),
                          tooltip: 'Edit content',
                          onPressed: onEdit,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Move to Trash',
                          onPressed: onDelete,
                        ),
                      ],
                    )
                  else
                    const Icon(Icons.chevron_right_rounded, color: kNavy),
                ],
              ),
              if (lesson.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  lesson.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (classModel != null)
                    _MiniTag(
                      label: classModel!.className,
                      color: Colors.teal.shade700,
                      icon: Icons.groups_outlined,
                    ),
                  if (hasPdf)
                    const _MiniTag(
                      label: 'PDF',
                      color: Colors.red,
                      icon: Icons.picture_as_pdf_outlined,
                    ),
                  if (hasVideo)
                    const _MiniTag(
                      label: 'Video',
                      color: Colors.blue,
                      icon: Icons.play_circle_outline,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.tone, required this.message});

  final Color tone;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: TextStyle(color: tone, fontWeight: FontWeight.w700),
      ),
    );
  }
}
