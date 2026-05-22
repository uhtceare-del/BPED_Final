import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/class_model.dart';
import '../models/submission_model.dart';
import '../models/task_model.dart';
import '../providers/lesson_provider.dart';
import '../providers/reviewer_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/task_provider.dart';
import '../screens/lesson_detail_screen.dart';
import '../screens/student_task_detail_screen.dart';
import '../screens/take_quiz_screen.dart';
import '../widgets/download_button.dart';
import '../widgets/dashboard_module.dart';
import '../widgets/pdf_viewer_widget.dart';

class StudentClassDetailScreen extends ConsumerWidget {
  final ClassModel classModel;

  const StudentClassDetailScreen({super.key, required this.classModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DashboardModuleHeader(
                  title: classModel.className,
                  subtitle: '${classModel.subject} • ${classModel.schedule}',
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: kNavy),
                  ),
                  trailing: DashboardTag(
                    label: classModel.classCode,
                    color: kMaroon,
                    icon: Icons.vpn_key_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kNavyBorder),
                  ),
                  child: const TabBar(
                    isScrollable: true,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(icon: Icon(Icons.menu_book), text: 'Lessons'),
                      Tab(icon: Icon(Icons.task_alt), text: 'Tasks'),
                      Tab(icon: Icon(Icons.picture_as_pdf), text: 'Reviewers'),
                      Tab(icon: Icon(Icons.assignment), text: 'Grades'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildLessonsTab(),
                      _buildTasksTab(),
                      _buildReviewersTab(),
                      _buildGradesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonsTab() {
    return Consumer(
      builder: (context, ref, _) {
        final lessonsAsync = ref.watch(lessonsByClassProvider(classModel.id));
        return lessonsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: kNavy)),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (lessons) {
            if (lessons.isEmpty) {
              return const DashboardEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No lessons yet',
                message:
                    'Your instructor has not published curriculum items for this class yet.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final hasPdf = lesson.pdfUrl?.isNotEmpty ?? false;
                final hasVideo = lesson.videoUrl?.isNotEmpty ?? false;

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    title: Text(
                      lesson.title,
                      style: const TextStyle(
                        color: kNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          lesson.description.isEmpty
                              ? 'No curriculum note provided.'
                              : lesson.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            DashboardTag(
                              label: lesson.subject,
                              color: kNavy,
                              icon: Icons.subject_outlined,
                            ),
                            if (hasPdf)
                              const DashboardTag(
                                label: 'PDF',
                                color: Colors.red,
                                icon: Icons.picture_as_pdf_outlined,
                              ),
                            if (hasVideo)
                              const DashboardTag(
                                label: 'Video',
                                color: Colors.blue,
                                icon: Icons.play_circle_outline,
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: kNavy,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LessonDetailScreen(lesson: lesson),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTasksTab() {
    return Consumer(
      builder: (context, ref, _) {
        final tasksAsync = ref.watch(tasksForMyClassesProvider);
        return tasksAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: kNavy)),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (tasks) {
            final classTasks =
                tasks.where((task) => task.classId == classModel.id).toList()
                  ..sort((a, b) => a.deadline.compareTo(b.deadline));
            if (classTasks.isEmpty) {
              return const DashboardEmptyState(
                icon: Icons.task_alt_outlined,
                title: 'No tasks yet',
                message:
                    'Assigned tasks and quizzes for this class will appear here.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: classTasks.length,
              itemBuilder: (context, index) {
                final task = classTasks[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    title: Text(
                      task.title,
                      style: const TextStyle(
                        color: kNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            DashboardTag(
                              label: task.isQuiz ? 'Quiz' : 'Task',
                              color: task.isQuiz
                                  ? Colors.purple.shade700
                                  : Colors.orange.shade800,
                              icon: task.isQuiz
                                  ? Icons.quiz_outlined
                                  : Icons.assignment_outlined,
                            ),
                            DashboardTag(
                              label: '${task.maxScore} points',
                              color: Colors.orange.shade800,
                              icon: Icons.score_outlined,
                            ),
                            DashboardTag(
                              label:
                                  'Due ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
                              color: kMaroon,
                              icon: Icons.event_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(
                      task.isQuiz
                          ? Icons.quiz_outlined
                          : Icons.chevron_right_rounded,
                      color: kNavy,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => task.isQuiz
                            ? TakeQuizScreen(task: task)
                            : StudentTaskDetailScreen(task: task),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReviewersTab() {
    return Consumer(
      builder: (context, ref, _) {
        final reviewersAsync = ref.watch(
          reviewersByClassProvider(classModel.id),
        );
        return reviewersAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: kNavy)),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (reviewers) {
            if (reviewers.isEmpty) {
              return const DashboardEmptyState(
                icon: Icons.picture_as_pdf_outlined,
                title: 'No reviewers yet',
                message:
                    'Reviewer PDFs for this class will appear here when your instructor uploads them.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: reviewers.length,
              itemBuilder: (context, index) {
                final reviewer = reviewers[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                      ),
                    ),
                    title: Text(
                      reviewer.title,
                      style: const TextStyle(
                        color: kNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          DashboardTag(
                            label: reviewer.subject.isNotEmpty
                                ? reviewer.subject
                                : reviewer.category,
                            color: kNavy,
                            icon: Icons.subject_outlined,
                          ),
                          DashboardTag(
                            label: 'Offline ready',
                            color: Colors.green.shade700,
                            icon: Icons.download_for_offline_outlined,
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility_outlined,
                            color: Colors.blueAccent,
                          ),
                          tooltip: 'Preview PDF',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfViewerWidget(
                                title: reviewer.title,
                                urlOrPath: reviewer.fileUrl,
                                isOffline: false,
                              ),
                            ),
                          ),
                        ),
                        DownloadButton(
                          materialId: reviewer.id,
                          title: reviewer.title,
                          url: reviewer.fileUrl,
                          fileExtension: '.pdf',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGradesTab() {
    return Consumer(
      builder: (context, ref, _) {
        final tasksAsync = ref.watch(tasksForMyClassesProvider);
        final submissionsAsync = ref.watch(mySubmissionsProvider);
        return tasksAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: kNavy)),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (tasks) {
            final classTasks = tasks
                .where((task) => task.classId == classModel.id)
                .toList();
            final tasksById = {for (final task in classTasks) task.id: task};
            return submissionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: kNavy)),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (submissions) {
                final classSubmissions =
                    submissions
                        .where(
                          (submission) =>
                              tasksById.containsKey(submission.taskId),
                        )
                        .toList()
                      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
                if (classSubmissions.isEmpty) {
                  return const DashboardEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No graded submissions yet',
                    message:
                        'Your submission history and grades for this class will appear here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: classSubmissions.length,
                  itemBuilder: (context, index) {
                    final submission = classSubmissions[index];
                    final task = tasksById[submission.taskId];
                    return _GradeCard(task: task, submission: submission);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.task, required this.submission});

  final TaskModel? task;
  final SubmissionModel submission;

  @override
  Widget build(BuildContext context) {
    final grade = submission.grade;
    final hasGrade = grade != null;
    final gradeLabel = hasGrade ? '$grade' : 'Pending';
    final gradeColor = hasGrade
        ? Colors.green.shade700
        : Colors.orange.shade800;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        title: Text(
          task?.title ?? 'Submission',
          style: const TextStyle(color: kNavy, fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DashboardTag(
                label:
                    'Submitted ${submission.submittedAt.day}/${submission.submittedAt.month}/${submission.submittedAt.year}',
                color: kNavy,
                icon: Icons.schedule_outlined,
              ),
              DashboardTag(
                label: gradeLabel,
                color: gradeColor,
                icon: hasGrade
                    ? Icons.check_circle_outline
                    : Icons.hourglass_bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
