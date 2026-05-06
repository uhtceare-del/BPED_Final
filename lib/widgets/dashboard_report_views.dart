import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/class_model.dart';
import '../models/lesson_model.dart';
import '../models/submission_model.dart';
import '../models/task_model.dart';
import '../providers/admin_provider.dart';
import '../providers/class_provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/task_provider.dart';
import 'dashboard_analytics.dart';

class AdminReportsView extends ConsumerStatefulWidget {
  const AdminReportsView({
    super.key,
    this.padding = const EdgeInsets.only(bottom: 24),
  });

  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends ConsumerState<AdminReportsView> {
  int _selectedChart = 0;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final classesAsync = ref.watch(allClassesProvider);
    final tasksAsync = ref.watch(allTasksProvider);
    final submissionsAsync = ref.watch(submissionProvider);

    if (usersAsync.isLoading ||
        classesAsync.isLoading ||
        tasksAsync.isLoading ||
        submissionsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: kNavy));
    }

    if (usersAsync.hasError) {
      return Center(child: Text('Error: ${usersAsync.error}'));
    }
    if (classesAsync.hasError) {
      return Center(child: Text('Error: ${classesAsync.error}'));
    }
    if (tasksAsync.hasError) {
      return Center(child: Text('Error: ${tasksAsync.error}'));
    }
    if (submissionsAsync.hasError) {
      return Center(child: Text('Error: ${submissionsAsync.error}'));
    }

    final users = usersAsync.value ?? const <Map<String, dynamic>>[];
    final classes = classesAsync.value ?? const <ClassModel>[];
    final tasks = tasksAsync.value ?? const <TaskModel>[];
    final submissions = submissionsAsync.value ?? const <SubmissionModel>[];
    final classesById = {for (final cls in classes) cls.id: cls};
    final progressItems = buildTaskProgressData(
      tasks: tasks,
      submissions: submissions,
      classesById: classesById,
    );

    final roleCounts = <String, int>{'student': 0, 'instructor': 0, 'admin': 0};
    for (final user in users) {
      final role = (user['role'] ?? '').toString().toLowerCase();
      if (roleCounts.containsKey(role)) {
        roleCounts[role] = roleCounts[role]! + 1;
      }
    }

    final totalOnTime = progressItems.fold<int>(
      0,
      (total, item) => total + item.onTimeCount,
    );
    final totalLate = progressItems.fold<int>(
      0,
      (total, item) => total + item.lateCount,
    );
    final totalPending = progressItems.fold<int>(
      0,
      (total, item) => total + item.pendingCount,
    );
    final totalTaskSlots = progressItems.fold<int>(
      0,
      (total, item) => total + item.totalStudents,
    );
    final totalCompletedSlots = progressItems.fold<int>(
      0,
      (total, item) => total + item.submittedCount,
    );
    final completionRate = totalTaskSlots == 0
        ? 0.0
        : (totalCompletedSlots / totalTaskSlots) * 100;

    final chartSets = [
      <DashboardBarDatum>[
        DashboardBarDatum(
          label: 'Students',
          value: roleCounts['student'] ?? 0,
          color: kNavy,
        ),
        DashboardBarDatum(
          label: 'Instructors',
          value: roleCounts['instructor'] ?? 0,
          color: kGold,
        ),
        DashboardBarDatum(
          label: 'Admins',
          value: roleCounts['admin'] ?? 0,
          color: kMaroon,
        ),
        DashboardBarDatum(
          label: 'Classes',
          value: classes.length,
          color: Colors.teal.shade700,
        ),
      ],
      <DashboardBarDatum>[
        DashboardBarDatum(label: 'Tasks', value: tasks.length, color: kNavy),
        DashboardBarDatum(
          label: 'Uploads',
          value: submissions.length,
          color: Colors.green.shade700,
        ),
        DashboardBarDatum(
          label: 'On time',
          value: totalOnTime,
          color: Colors.lightGreen.shade700,
        ),
        DashboardBarDatum(
          label: 'Late',
          value: totalLate,
          color: Colors.orange.shade800,
        ),
      ],
      <DashboardBarDatum>[
        DashboardBarDatum(
          label: 'Pending',
          value: totalPending,
          color: kMaroon,
        ),
        DashboardBarDatum(
          label: 'Live tasks',
          value: progressItems.length,
          color: kNavy,
        ),
        DashboardBarDatum(
          label: 'Classes live',
          value: classes.length,
          color: Colors.indigo.shade700,
        ),
        DashboardBarDatum(
          label: 'Uploads',
          value: submissions.length,
          color: Colors.cyan.shade700,
        ),
      ],
    ];

    final chartTitles = [
      'Population snapshot',
      'Submission activity',
      'Workload pressure',
    ];

    return ListView(
      padding: widget.padding,
      children: [
        InsightShell(
          title: 'System-wide reporting',
          subtitle:
              'Monitor users, class activity, and submission health from one shared reporting layer.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Population'),
                    selected: _selectedChart == 0,
                    onSelected: (_) => setState(() => _selectedChart = 0),
                  ),
                  ChoiceChip(
                    label: const Text('Submissions'),
                    selected: _selectedChart == 1,
                    onSelected: (_) => setState(() => _selectedChart = 1),
                  ),
                  ChoiceChip(
                    label: const Text('Backlog'),
                    selected: _selectedChart == 2,
                    onSelected: (_) => setState(() => _selectedChart = 2),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MetricStrip(
                children: [
                  StatBadge(
                    label: 'Active users',
                    value: '${users.length}',
                    tone: kNavy,
                  ),
                  StatBadge(
                    label: 'Classes',
                    value: '${classes.length}',
                    tone: Colors.teal.shade700,
                  ),
                  StatBadge(
                    label: 'Tasks',
                    value: '${tasks.length}',
                    tone: kGold,
                  ),
                  StatBadge(
                    label: 'Completion',
                    value: _formatPercent(completionRate),
                    tone: Colors.green.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              InteractiveBarChart(
                title: chartTitles[_selectedChart],
                data: chartSets[_selectedChart],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _InsightPanel(
          title: 'Activity watchlist',
          subtitle:
              'Keep an eye on late work, pending submissions, and the tasks drawing the most traffic.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(
                    label: 'Late submissions',
                    value: '$totalLate',
                    tone: Colors.orange.shade800,
                  ),
                  _SummaryChip(
                    label: 'Pending slots',
                    value: '$totalPending',
                    tone: kMaroon,
                  ),
                  _SummaryChip(
                    label: 'Uploaded work',
                    value: '${submissions.length}',
                    tone: Colors.green.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TaskProgressBoard(items: progressItems),
            ],
          ),
        ),
      ],
    );
  }
}

class InstructorReportsView extends ConsumerWidget {
  const InstructorReportsView({
    super.key,
    this.padding = const EdgeInsets.only(bottom: 24),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(instructorClassesProvider);
    final tasksAsync = ref.watch(instructorTasksProvider);
    final submissionsAsync = ref.watch(securedSubmissionsProvider);

    if (classesAsync.isLoading ||
        tasksAsync.isLoading ||
        submissionsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: kNavy));
    }

    if (classesAsync.hasError) {
      return Center(child: Text('Error: ${classesAsync.error}'));
    }
    if (tasksAsync.hasError) {
      return Center(child: Text('Error: ${tasksAsync.error}'));
    }
    if (submissionsAsync.hasError) {
      return Center(child: Text('Error: ${submissionsAsync.error}'));
    }

    final classes = classesAsync.value ?? const <ClassModel>[];
    final classIds = classes.map((cls) => cls.id).toSet();
    final tasks = (tasksAsync.value ?? const <TaskModel>[])
        .where((task) => classIds.contains(task.classId))
        .toList();
    final submissions = submissionsAsync.value ?? const <SubmissionModel>[];
    final classesById = {for (final cls in classes) cls.id: cls};
    final progressItems = buildTaskProgressData(
      tasks: tasks,
      submissions: submissions,
      classesById: classesById,
    );

    final totalStudents = classes.fold<int>(
      0,
      (sum, cls) => sum + cls.enrolledStudentIds.length,
    );
    final totalOnTime = progressItems.fold<int>(
      0,
      (sum, item) => sum + item.onTimeCount,
    );
    final totalLate = progressItems.fold<int>(
      0,
      (sum, item) => sum + item.lateCount,
    );
    final totalPending = progressItems.fold<int>(
      0,
      (sum, item) => sum + item.pendingCount,
    );
    final totalSlots = progressItems.fold<int>(
      0,
      (sum, item) => sum + item.totalStudents,
    );
    final totalCompleted = progressItems.fold<int>(
      0,
      (sum, item) => sum + item.submittedCount,
    );
    final completionRate = totalSlots == 0
        ? 0.0
        : (totalCompleted / totalSlots) * 100;
    final averageClassSize = classes.isEmpty
        ? 0
        : totalStudents / classes.length;

    final classLoadData = [...classes]
      ..sort(
        (a, b) =>
            b.enrolledStudentIds.length.compareTo(a.enrolledStudentIds.length),
      );

    return ListView(
      padding: padding,
      children: [
        InsightShell(
          title: 'Instruction performance board',
          subtitle:
              'Review class performance, submission timing, and completion trends without leaving your dashboard flow.',
          child: Column(
            children: [
              _MetricStrip(
                children: [
                  StatBadge(
                    label: 'Classes',
                    value: '${classes.length}',
                    tone: kNavy,
                  ),
                  StatBadge(
                    label: 'Students',
                    value: '$totalStudents',
                    tone: Colors.teal.shade700,
                  ),
                  StatBadge(
                    label: 'Tasks',
                    value: '${tasks.length}',
                    tone: kGold,
                  ),
                  StatBadge(
                    label: 'Completion',
                    value: _formatPercent(completionRate),
                    tone: Colors.green.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              InteractiveBarChart(
                title: 'Submission status by task portfolio',
                data: [
                  DashboardBarDatum(
                    label: 'On time',
                    value: totalOnTime,
                    color: Colors.green.shade700,
                  ),
                  DashboardBarDatum(
                    label: 'Late',
                    value: totalLate,
                    color: Colors.orange.shade800,
                  ),
                  DashboardBarDatum(
                    label: 'Pending',
                    value: totalPending,
                    color: kMaroon,
                  ),
                  DashboardBarDatum(
                    label: 'Tasks',
                    value: tasks.length,
                    color: kNavy,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _InsightPanel(
          title: 'Class load snapshot',
          subtitle:
              'Surface the busiest sections, average roster size, and the tasks that still need student action.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(
                    label: 'Average roster',
                    value: averageClassSize.toStringAsFixed(
                      averageClassSize % 1 == 0 ? 0 : 1,
                    ),
                    tone: Colors.indigo.shade700,
                  ),
                  _SummaryChip(
                    label: 'Late submissions',
                    value: '$totalLate',
                    tone: Colors.orange.shade800,
                  ),
                  _SummaryChip(
                    label: 'Pending work',
                    value: '$totalPending',
                    tone: kMaroon,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              InteractiveBarChart(
                title: 'Largest class sections',
                data: classLoadData.take(4).map((cls) {
                  return DashboardBarDatum(
                    label: cls.className,
                    value: cls.enrolledStudentIds.length,
                    color: Colors.teal.shade700,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Task progress spotlight',
          style: TextStyle(
            color: kNavy,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        TaskProgressBoard(
          items: progressItems,
          emptyText: 'Create a task to start tracking class progress.',
        ),
      ],
    );
  }
}

class StudentReportsView extends ConsumerWidget {
  const StudentReportsView({
    super.key,
    this.padding = const EdgeInsets.only(bottom: 24),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(myClassesProvider);
    final tasksAsync = ref.watch(tasksForMyClassesProvider);
    final submissionsAsync = ref.watch(mySubmissionsProvider);
    final lessonsAsync = ref.watch(lessonsForCurrentUserProvider);

    if (classesAsync.isLoading ||
        tasksAsync.isLoading ||
        submissionsAsync.isLoading ||
        lessonsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: kNavy));
    }

    if (classesAsync.hasError) {
      return Center(child: Text('Error: ${classesAsync.error}'));
    }
    if (tasksAsync.hasError) {
      return Center(child: Text('Error: ${tasksAsync.error}'));
    }
    if (submissionsAsync.hasError) {
      return Center(child: Text('Error: ${submissionsAsync.error}'));
    }
    if (lessonsAsync.hasError) {
      return Center(child: Text('Error: ${lessonsAsync.error}'));
    }

    final classes = classesAsync.value ?? const <ClassModel>[];
    final tasks = tasksAsync.value ?? const <TaskModel>[];
    final submissions = submissionsAsync.value ?? const <SubmissionModel>[];
    final lessons = lessonsAsync.value ?? const <LessonModel>[];
    final classIds = classes.map((cls) => cls.id).toSet();
    final classesById = {for (final cls in classes) cls.id: cls};
    final studentTasks =
        tasks.where((task) => classIds.contains(task.classId)).toList()
          ..sort((a, b) => a.deadline.compareTo(b.deadline));
    final taskStatuses = buildStudentTaskStatusData(
      tasks: studentTasks,
      submissions: submissions,
      classesById: classesById,
    );

    final onTimeCount = taskStatuses
        .where((task) => task.state == StudentTaskState.onTime)
        .length;
    final lateCount = taskStatuses
        .where((task) => task.state == StudentTaskState.late)
        .length;
    final pendingCount = taskStatuses
        .where((task) => task.state == StudentTaskState.pending)
        .length;
    final overdueCount = taskStatuses
        .where((task) => task.state == StudentTaskState.overdue)
        .length;
    final submittedCount = onTimeCount + lateCount;
    final completionRate = studentTasks.isEmpty
        ? 0.0
        : (submittedCount / studentTasks.length) * 100;

    final scoredSubmissions = submissions
        .map((submission) => _tryParseGrade(submission.grade))
        .whereType<double>()
        .toList();
    final averageScore = scoredSubmissions.isEmpty
        ? null
        : scoredSubmissions.reduce((a, b) => a + b) / scoredSubmissions.length;
    final highestScore = scoredSubmissions.isEmpty
        ? null
        : scoredSubmissions.reduce(max);
    final awaitingReviewCount = submissions.length - scoredSubmissions.length;

    final lessonsWithVideo = lessons
        .where((lesson) => (lesson.videoUrl ?? '').trim().isNotEmpty)
        .length;
    final lessonsWithHandout = lessons
        .where((lesson) => (lesson.pdfUrl ?? '').trim().isNotEmpty)
        .length;
    final classesWithCurriculum = classes
        .where((cls) => lessons.any((lesson) => lesson.classId == cls.id))
        .length;

    return ListView(
      padding: padding,
      children: [
        InsightShell(
          title: 'Personal progress snapshot',
          subtitle:
              'Follow your submission pace, personal completion rate, and current task pressure in one place.',
          child: Column(
            children: [
              _MetricStrip(
                children: [
                  StatBadge(
                    label: 'Classes',
                    value: '${classes.length}',
                    tone: kNavy,
                  ),
                  StatBadge(
                    label: 'Tasks',
                    value: '${studentTasks.length}',
                    tone: kGold,
                  ),
                  StatBadge(
                    label: 'Submitted',
                    value: '$submittedCount',
                    tone: Colors.green.shade700,
                  ),
                  StatBadge(
                    label: 'Completion',
                    value: _formatPercent(completionRate),
                    tone: Colors.teal.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              InteractiveBarChart(
                title: 'Task status',
                data: [
                  DashboardBarDatum(
                    label: 'On time',
                    value: onTimeCount,
                    color: Colors.green.shade700,
                  ),
                  DashboardBarDatum(
                    label: 'Late',
                    value: lateCount,
                    color: Colors.orange.shade800,
                  ),
                  DashboardBarDatum(
                    label: 'Pending',
                    value: pendingCount,
                    color: kNavy,
                  ),
                  DashboardBarDatum(
                    label: 'Overdue',
                    value: overdueCount,
                    color: kMaroon,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _InsightPanel(
          title: 'Scores and curriculum coverage',
          subtitle:
              'Review graded work alongside the lesson library currently published to your enrolled classes.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(
                    label: 'Graded tasks',
                    value: '${scoredSubmissions.length}',
                    tone: Colors.indigo.shade700,
                  ),
                  _SummaryChip(
                    label: 'Average score',
                    value: averageScore == null
                        ? 'N/A'
                        : _formatScore(averageScore),
                    tone: Colors.green.shade700,
                  ),
                  _SummaryChip(
                    label: 'Highest score',
                    value: highestScore == null
                        ? 'N/A'
                        : _formatScore(highestScore),
                    tone: kGold,
                  ),
                  _SummaryChip(
                    label: 'Awaiting review',
                    value: '$awaitingReviewCount',
                    tone: kMaroon,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              InteractiveBarChart(
                title: 'Curriculum availability',
                data: [
                  DashboardBarDatum(
                    label: 'Lessons',
                    value: lessons.length,
                    color: kNavy,
                  ),
                  DashboardBarDatum(
                    label: 'With video',
                    value: lessonsWithVideo,
                    color: Colors.teal.shade700,
                  ),
                  DashboardBarDatum(
                    label: 'With handout',
                    value: lessonsWithHandout,
                    color: Colors.orange.shade800,
                  ),
                  DashboardBarDatum(
                    label: 'Classes covered',
                    value: classesWithCurriculum,
                    color: Colors.indigo.shade700,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Recent task status',
          style: TextStyle(
            color: kNavy,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        StudentTaskStatusBoard(
          items: taskStatuses,
          emptyText: 'No active tasks across your enrolled classes yet.',
        ),
      ],
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kNavyBorder),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kNavy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: kNavy.withValues(alpha: 0.64),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: tone,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

double? _tryParseGrade(String? grade) {
  if (grade == null) {
    return null;
  }

  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(grade);
  if (match == null) {
    return null;
  }

  return double.tryParse(match.group(0)!);
}

String _formatPercent(double value) {
  return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%';
}

String _formatScore(double value) {
  return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
}
