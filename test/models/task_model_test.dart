import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/models/task_model.dart';

void main() {
  group('TaskModel', () {
    test('serializes quiz tasks with kind metadata', () {
      final deadline = DateTime(2026, 4, 20);
      final model = TaskModel(
        id: 'task-1',
        title: 'Midterm Quiz',
        description: 'Answer all questions.',
        maxScore: 50,
        deadline: deadline,
        lessonId: 'lesson-1',
        instructorId: 'instructor-1',
        classId: 'class-1',
        kind: 'quiz',
      );

      final map = model.toMap();

      expect(model.isQuiz, isTrue);
      expect(map['title'], 'Midterm Quiz');
      expect(map['description'], 'Answer all questions.');
      expect(map['maxScore'], 50);
      expect(map['deadline'], Timestamp.fromDate(deadline));
      expect(map['lessonId'], 'lesson-1');
      expect(map['instructorId'], 'instructor-1');
      expect(map['classId'], 'class-1');
      expect(map['kind'], 'quiz');
    });

    test('defaults to task kind', () {
      final model = TaskModel(
        id: 'task-2',
        title: 'Video Submission',
        description: 'Upload your performance.',
        maxScore: 100,
        deadline: DateTime(2026, 4, 22),
        lessonId: null,
        instructorId: 'instructor-1',
        classId: 'class-2',
      );

      expect(model.kind, 'task');
      expect(model.isQuiz, isFalse);
    });
  });
}
