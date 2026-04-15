import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/class_model.dart';
import '../models/submission_model.dart';
import '../models/task_model.dart';

enum StudentTaskState { onTime, late, pending, overdue }

class DashboardBarDatum {
  const DashboardBarDatum({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class TaskProgressViewData {
  const TaskProgressViewData({
    required this.title,
    required this.classLabel,
    required this.deadline,
    required this.submittedCount,
    required this.totalStudents,
    required this.onTimeCount,
    required this.lateCount,
  });

  final String title;
  final String classLabel;
  final DateTime deadline;
  final int submittedCount;
  final int totalStudents;
  final int onTimeCount;
  final int lateCount;

  int get pendingCount =>
      (totalStudents - submittedCount).clamp(0, totalStudents);
  double get progress =>
      totalStudents == 0 ? 0 : submittedCount / totalStudents;
}

class StudentTaskStatusViewData {
  const StudentTaskStatusViewData({
    required this.title,
    required this.classLabel,
    required this.deadline,
    required this.state,
    this.submittedAt,
  });

  final String title;
  final String classLabel;
  final DateTime deadline;
  final StudentTaskState state;
  final DateTime? submittedAt;
}

List<TaskProgressViewData> buildTaskProgressData({
  required List<TaskModel> tasks,
  required List<SubmissionModel> submissions,
  required Map<String, ClassModel> classesById,
}) {
  final submissionsByTask = <String, Map<String, SubmissionModel>>{};
  for (final submission in submissions) {
    submissionsByTask.putIfAbsent(submission.taskId, () => {});
    final existing =
        submissionsByTask[submission.taskId]![submission.studentId];
    if (existing == null ||
        submission.submittedAt.isAfter(existing.submittedAt)) {
      submissionsByTask[submission.taskId]![submission.studentId] = submission;
    }
  }

  final rows = tasks.map((task) {
    final cls = classesById[task.classId];
    final latestByStudent =
        submissionsByTask[task.id]?.values.toList() ?? const [];
    final onTime = latestByStudent
        .where((s) => !s.submittedAt.isAfter(task.deadline))
        .length;
    final late = latestByStudent
        .where((s) => s.submittedAt.isAfter(task.deadline))
        .length;

    return TaskProgressViewData(
      title: task.title,
      classLabel: cls?.className ?? 'Unassigned class',
      deadline: task.deadline,
      submittedCount: latestByStudent.length,
      totalStudents: cls?.enrolledStudentIds.length ?? 0,
      onTimeCount: onTime,
      lateCount: late,
    );
  }).toList();

  rows.sort((a, b) => a.deadline.compareTo(b.deadline));
  return rows;
}

List<StudentTaskStatusViewData> buildStudentTaskStatusData({
  required List<TaskModel> tasks,
  required List<SubmissionModel> submissions,
  required Map<String, ClassModel> classesById,
}) {
  final latestByTask = <String, SubmissionModel>{};
  for (final submission in submissions) {
    final existing = latestByTask[submission.taskId];
    if (existing == null ||
        submission.submittedAt.isAfter(existing.submittedAt)) {
      latestByTask[submission.taskId] = submission;
    }
  }

  final now = DateTime.now();
  final rows = tasks.map((task) {
    final submission = latestByTask[task.id];
    final state = submission != null
        ? (submission.submittedAt.isAfter(task.deadline)
              ? StudentTaskState.late
              : StudentTaskState.onTime)
        : (task.deadline.isBefore(now)
              ? StudentTaskState.overdue
              : StudentTaskState.pending);

    return StudentTaskStatusViewData(
      title: task.title,
      classLabel: classesById[task.classId]?.className ?? 'Class task',
      deadline: task.deadline,
      state: state,
      submittedAt: submission?.submittedAt,
    );
  }).toList();

  rows.sort((a, b) => a.deadline.compareTo(b.deadline));
  return rows;
}

String formatShortDate(DateTime value) {
  return '${value.month}/${value.day}/${value.year}';
}

class InsightShell extends StatelessWidget {
  const InsightShell({
    super.key,
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
        gradient: const LinearGradient(
          colors: [Color(0xFFFEFEFB), Color(0xFFEAF0F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kNavyBorder),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: kNavy.withValues(alpha: 0.64),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class StatBadge extends StatelessWidget {
  const StatBadge({
    super.key,
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
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: tone.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: tone,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class InteractiveBarChart extends StatelessWidget {
  const InteractiveBarChart({
    super.key,
    required this.title,
    required this.data,
  });

  final String title;
  final List<DashboardBarDatum> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty
        ? 1
        : data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kNavyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kNavy,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((datum) {
                final heightFactor = maxValue == 0
                    ? 0.0
                    : datum.value / maxValue;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          datum.value.toString(),
                          style: const TextStyle(
                            color: kNavy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          height: 120 * heightFactor + 8,
                          decoration: BoxDecoration(
                            color: datum.color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          datum.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kNavy.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskProgressBoard extends StatelessWidget {
  const TaskProgressBoard({
    super.key,
    required this.items,
    this.emptyText = 'No task progress available yet.',
  });

  final List<TaskProgressViewData> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyPane(label: emptyText);
    }

    return Column(
      children: items.take(4).map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kNavyBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: kNavy,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.classLabel} • Due ${formatShortDate(item.deadline)}',
                style: TextStyle(
                  color: kNavy.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE8EDF3),
                  color: kNavy,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricPill(
                    label: 'Submitted',
                    value: '${item.submittedCount}/${item.totalStudents}',
                    tone: kNavy,
                  ),
                  _MetricPill(
                    label: 'On time',
                    value: '${item.onTimeCount}',
                    tone: Colors.green.shade700,
                  ),
                  _MetricPill(
                    label: 'Late',
                    value: '${item.lateCount}',
                    tone: Colors.orange.shade800,
                  ),
                  _MetricPill(
                    label: 'Pending',
                    value: '${item.pendingCount}',
                    tone: kMaroon,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class StudentTaskStatusBoard extends StatelessWidget {
  const StudentTaskStatusBoard({
    super.key,
    required this.items,
    this.emptyText = 'No task activity yet.',
  });

  final List<StudentTaskStatusViewData> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyPane(label: emptyText);
    }

    return Column(
      children: items.take(4).map((item) {
        final tone = switch (item.state) {
          StudentTaskState.onTime => Colors.green.shade700,
          StudentTaskState.late => Colors.orange.shade800,
          StudentTaskState.pending => kNavy,
          StudentTaskState.overdue => kMaroon,
        };

        final label = switch (item.state) {
          StudentTaskState.onTime => 'Submitted on time',
          StudentTaskState.late => 'Submitted late',
          StudentTaskState.pending => 'Pending submission',
          StudentTaskState.overdue => 'Past deadline',
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kNavyBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 52,
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: kNavy,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.classLabel} • Due ${formatShortDate(item.deadline)}',
                      style: TextStyle(
                        color: kNavy.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    if (item.submittedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Submitted ${formatShortDate(item.submittedAt!)}',
                        style: TextStyle(
                          color: tone,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: tone,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
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
        '$label $value',
        style: TextStyle(
          color: tone,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kNavyBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: kNavy.withValues(alpha: 0.58),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
