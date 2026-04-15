import 'package:flutter_test/flutter_test.dart';
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
        grade: '95',
        instructorId: 'instructor-1',
      );

      final map = submission.toFirestore();

      expect(map['taskId'], 'task-1');
      expect(map['studentId'], 'student-1');
      expect(map['studentEmail'], 'student@example.com');
      expect(map['fileUrl'], 'https://example.com/upload.mp4');
      expect(map['submittedAt'], submittedAt);
      expect(map['grade'], '95');
      expect(map['instructorId'], 'instructor-1');
    });
  });
}
