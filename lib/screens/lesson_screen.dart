import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../models/lesson_model.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import 'lesson_detail_screen.dart';
import 'create_lesson_screen.dart';
import '../constants/app_colors.dart';
import '../widgets/dashboard_module.dart';

final studentClassIdsForLessonsProvider =
    StreamProvider.autoDispose<List<String>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null || user.role.toLowerCase() == 'instructor') {
        return Stream.value([]);
      }

      return FirebaseFirestore.instance
          .collection('classes')
          .where('enrolledStudentIds', arrayContains: user.uid)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map((doc) => doc.id).toSet().toList(),
          );
    });

// --- 2. THE FIX: SECURED MASTER-KEY LESSON STREAM ---
final securedLessonsStreamProvider =
    StreamProvider.autoDispose<List<LessonModel>>((ref) async* {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) {
        yield [];
        return;
      }

      final isInstructor = user.role.toLowerCase() == 'instructor';
      final db = FirebaseFirestore.instance;

      if (isInstructor) {
        // INSTRUCTOR: Only see lessons they created themselves
        yield* db
            .collection('lessons')
            .where('instructorId', isEqualTo: user.uid)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => LessonModel.fromFirestore(doc))
                  .toList(),
            );
      } else {
        final classIdsAsync = ref.watch(studentClassIdsForLessonsProvider);

        if (classIdsAsync.isLoading || classIdsAsync.hasError) {
          yield [];
          return;
        }

        final classIds = classIdsAsync.value ?? [];
        if (classIds.isEmpty) {
          yield [];
          return;
        }

        yield* db
            .collection('lessons')
            .where('classId', whereIn: classIds)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => LessonModel.fromFirestore(doc))
                  .toList(),
            );
      }
    });
// --------------------------------------------------

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key});

  // --- CRUD: DELETE LESSON ---
  void _showDeleteLessonDialog(BuildContext context, LessonModel lesson) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Delete Lesson",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text("Are you sure you want to delete '${lesson.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('lessons')
                    .doc(lesson.id)
                    .delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lesson deleted!"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error deleting: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(securedLessonsStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final classesAsync = ref.watch(allClassesProvider);
    final isInstructor = currentUser?.role.toLowerCase() == 'instructor';

    return DashboardModulePage(
      title: 'Curriculum',
      subtitle: isInstructor
          ? 'Organize curriculum by class and subject, then publish materials in a cleaner stream.'
          : 'Browse curriculum items connected to your enrolled classes in one consistent view.',
      floatingActionButton: isInstructor
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateLessonScreen(),
                  ),
                );
              },
              backgroundColor: kNavy,
              foregroundColor: Colors.white,
              label: const Text(
                'Create Lesson',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.add),
            )
          : null,
      child: lessonsAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return _buildEmptyState(isInstructor);
          }
          final classes = classesAsync.value ?? const <ClassModel>[];
          final classesById = {for (final cls in classes) cls.id: cls};
          final groupedLessons = <String, List<LessonModel>>{};
          for (final lesson in lessons) {
            final key = lesson.subject.trim().isEmpty
                ? (lesson.category?.trim().isNotEmpty ?? false)
                      ? lesson.category!.trim()
                      : 'General'
                : lesson.subject.trim();
            groupedLessons.putIfAbsent(key, () => []).add(lesson);
          }
          final subjects = groupedLessons.keys.toList()..sort();
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A2E5D), Color(0xFF335B93)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInstructor
                          ? 'Organize curriculum by class and subject'
                          : 'Browse your class curriculum like a classroom stream',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isInstructor
                          ? 'Upload materials once, keep subjects consistent from your class records, and publish handouts or videos in one place.'
                          : 'Open PDFs, watch lesson videos, and stay inside the subjects connected to your enrolled classes.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...subjects.map((subject) {
                final subjectLessons = groupedLessons[subject]!
                  ..sort((a, b) => a.title.compareTo(b.title));
                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: kNavy.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFEFF4FB), Color(0xFFDDE9F7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: kNavy,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject,
                                    style: const TextStyle(
                                      color: kNavy,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${subjectLessons.length} curriculum item${subjectLessons.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      color: kNavy.withValues(alpha: 0.68),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: subjectLessons.map((lesson) {
                            final lessonClass = classesById[lesson.classId];
                            final hasVideo =
                                lesson.videoUrl != null &&
                                lesson.videoUrl!.isNotEmpty;
                            final hasPdf =
                                lesson.pdfUrl != null &&
                                lesson.pdfUrl!.isNotEmpty;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBFCFE),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          LessonDetailScreen(lesson: lesson),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: kNavy.withValues(
                                                alpha: 0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              hasVideo
                                                  ? Icons.ondemand_video_rounded
                                                  : Icons.menu_book_rounded,
                                              color: kNavy,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lesson.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                    color: kNavy,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  lesson.description.isEmpty
                                                      ? 'No curriculum note provided.'
                                                      : lesson.description,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (lessonClass != null)
                                            _CurriculumChip(
                                              icon: Icons.groups_outlined,
                                              label: lessonClass.className,
                                            ),
                                          if (hasPdf)
                                            const _CurriculumChip(
                                              icon:
                                                  Icons.picture_as_pdf_outlined,
                                              label: 'PDF',
                                            ),
                                          if (hasVideo)
                                            const _CurriculumChip(
                                              icon: Icons.play_circle_outline,
                                              label: 'Video',
                                            ),
                                        ],
                                      ),
                                      if (isInstructor) ...[
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                            tooltip: "Delete Lesson",
                                            onPressed: () =>
                                                _showDeleteLessonDialog(
                                                  context,
                                                  lesson,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
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
      icon: Icons.play_lesson_rounded,
      title: 'No lessons available',
      message: isInstructor
          ? 'Publish your first lesson to start building a curriculum stream for your classes.'
          : 'You are not enrolled in any classes with active lessons right now.',
      tone: kNavy,
    );
  }
}

class _CurriculumChip extends StatelessWidget {
  const _CurriculumChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kNavy),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: kNavy, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
