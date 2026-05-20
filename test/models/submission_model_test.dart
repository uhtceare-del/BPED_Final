import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phys_ed/models/submission_model.dart';

void main() {
  group('SubmissionModel', () {
    test('serializes submission payload including instructor key', () {
      final submittedAt = DateTime(2026, 4, 8, 9, 30);
      final submission = SubmissionModel(
        id: 'submission-1',
        taskId: 'task-1',
        studentId: 'student-1',
        studentEmail: 'student@example.com',
        fileUrl: 'https://example.com/upload.mp4',
        submittedAt: submittedAt,
        grade: 95,
        instructorId: 'instructor-1',
      );
      final map = submission.toFirestore();
      expect(map['taskId'], 'task-1');
      expect(map['studentId'], 'student-1');
      expect(map['studentEmail'], 'student@example.com');
      expect(map['fileUrl'], 'https://example.com/upload.mp4');
      expect(map['submittedAt'], submittedAt);
      expect(map['grade'], 95);
      expect(map['instructorId'], 'instructor-1');
    });

    test('parses legacy submission records safely', () {
      final snapshot = _FakeDocumentSnapshot({
        'taskId': 'task-legacy',
        'studentId': 'student-legacy',
        'studentEmail': 'legacy@example.com',
        'submittedAt': '2026-04-08T09:30:00.000',
        'grade': '88.5',
        'instructorId': 'instructor-legacy',
      });

      final submission = SubmissionModel.fromFirestore(snapshot);

      expect(submission.taskId, 'task-legacy');
      expect(submission.studentId, 'student-legacy');
      expect(submission.studentEmail, 'legacy@example.com');
      expect(submission.submittedAt, DateTime.parse('2026-04-08T09:30:00.000'));
      expect(submission.grade, 88.5);
      expect(submission.instructorId, 'instructor-legacy');
    });
  });
}

class _FakeDocumentSnapshot extends Fake implements DocumentSnapshot {
  _FakeDocumentSnapshot(this._data);

  final Map<String, dynamic> _data;

  @override
  String get id => 'submission-legacy';

  @override
  dynamic data() => _data;
}
