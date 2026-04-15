import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/models/class_model.dart';
import 'package:phys_ed/models/submission_model.dart';
import 'package:phys_ed/models/task_model.dart';
import 'package:phys_ed/widgets/dashboard_analytics.dart';

void main() {
  group('Dashboard analytics', () {
    test('buildTaskProgressData deduplicates by latest student submission', () {
      final tasks = [
        TaskModel(
          id: 'task-late',
          title: 'Late Submission Check',
          description: 'Upload performance video',
          maxScore: 100,
          deadline: DateTime(2026, 4, 10),
          lessonId: null,
          instructorId: 'instructor-1',
          classId: 'class-1',
        ),
        TaskModel(
          id: 'task-empty',
          title: 'No Submission Yet',
          description: 'Warmup routine',
          maxScore: 50,
          deadline: DateTime(2026, 4, 12),
          lessonId: null,
          instructorId: 'instructor-1',
          classId: 'class-1',
        ),
      ];

      final classesById = {
        'class-1': ClassModel(
          id: 'class-1',
          className: 'BPED 1-A',
          subject: 'Team Sports',
          schedule: 'MWF',
          classCode: 'AB23CD',
          semesterLabel: '1st Semester',
          instructorId: 'instructor-1',
          enrolledStudentIds: const ['student-1', 'student-2'],
        ),
      };

      final submissions = [
        SubmissionModel(
          id: 'submission-1',
          taskId: 'task-late',
          studentId: 'student-1',
          studentEmail: 'student1@example.com',
          fileUrl: null,
          submittedAt: DateTime(2026, 4, 9),
          grade: null,
          instructorId: 'instructor-1',
        ),
        SubmissionModel(
          id: 'submission-2',
          taskId: 'task-late',
          studentId: 'student-1',
          studentEmail: 'student1@example.com',
          fileUrl: null,
          submittedAt: DateTime(2026, 4, 11),
          grade: null,
          instructorId: 'instructor-1',
        ),
      ];

      final rows = buildTaskProgressData(
        tasks: tasks,
        submissions: submissions,
        classesById: classesById,
      );

      expect(rows, hasLength(2));
      expect(rows.first.title, 'Late Submission Check');
      expect(rows.first.classLabel, 'BPED 1-A');
      expect(rows.first.submittedCount, 1);
      expect(rows.first.onTimeCount, 0);
      expect(rows.first.lateCount, 1);
      expect(rows.first.pendingCount, 1);
      expect(rows.first.progress, 0.5);
      expect(rows.last.title, 'No Submission Yet');
      expect(rows.last.submittedCount, 0);
    });

    test('buildStudentTaskStatusData classifies task states', () {
      final now = DateTime.now();
      final tasks = [
        TaskModel(
          id: 'task-on-time',
          title: 'On Time Task',
          description: 'Description',
          maxScore: 100,
          deadline: now.add(const Duration(days: 2)),
          lessonId: null,
          instructorId: 'instructor-1',
          classId: 'class-1',
        ),
        TaskModel(
          id: 'task-late',
          title: 'Late Task',
          description: 'Description',
          maxScore: 100,
          deadline: now.subtract(const Duration(days: 1)),
          lessonId: null,
          instructorId: 'instructor-1',
          classId: 'class-1',
        ),
        TaskModel(
          id: 'task-pending',
          title: 'Pending Task',
          description: 'Description',
          maxScore: 100,
          deadline: now.add(const Duration(days: 1)),
          lessonId: null,
          instructorId: 'instructor-1',
          classId: 'class-1',
        ),
        TaskModel(
          id: 'task-overdue',
          title: 'Overdue Task',
          description: 'Description',
          maxScore: 100,
          deadline: now.subtract(const Duration(days: 2)),
          lessonId: null,
          instructorId: 'instructor-1',
          classId: 'class-1',
        ),
      ];

      final statuses = buildStudentTaskStatusData(
        tasks: tasks,
        submissions: [
          SubmissionModel(
            id: 'submission-on-time',
            taskId: 'task-on-time',
            studentId: 'student-1',
            studentEmail: 'student1@example.com',
            fileUrl: null,
            submittedAt: now.add(const Duration(hours: 2)),
            grade: null,
            instructorId: 'instructor-1',
          ),
          SubmissionModel(
            id: 'submission-late',
            taskId: 'task-late',
            studentId: 'student-1',
            studentEmail: 'student1@example.com',
            fileUrl: null,
            submittedAt: now,
            grade: null,
            instructorId: 'instructor-1',
          ),
        ],
        classesById: {
          'class-1': ClassModel(
            id: 'class-1',
            className: 'BPED 1-A',
            subject: 'Team Sports',
            schedule: 'MWF',
            classCode: 'AB23CD',
            semesterLabel: '1st Semester',
            instructorId: 'instructor-1',
            enrolledStudentIds: const ['student-1'],
          ),
        },
      );

      final byTitle = {for (final status in statuses) status.title: status};

      expect(byTitle['On Time Task']!.state, StudentTaskState.onTime);
      expect(byTitle['Late Task']!.state, StudentTaskState.late);
      expect(byTitle['Pending Task']!.state, StudentTaskState.pending);
      expect(byTitle['Overdue Task']!.state, StudentTaskState.overdue);
      expect(byTitle['Pending Task']!.classLabel, 'BPED 1-A');
    });

    test('formatShortDate uses month/day/year output', () {
      expect(formatShortDate(DateTime(2026, 4, 8)), '4/8/2026');
    });
  });
}
