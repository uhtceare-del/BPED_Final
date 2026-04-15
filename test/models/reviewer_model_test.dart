import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/models/reviewer_model.dart';

void main() {
  group('ReviewerModel', () {
    test('serializes reviewer upload metadata', () {
      final reviewer = ReviewerModel(
        id: 'reviewer-1',
        title: 'Basketball Fundamentals',
        fileUrl: 'https://example.com/reviewer.pdf',
        category: 'Technique',
        subject: 'Team Sports',
        uploadedAt: DateTime(2026, 4, 8),
        instructorId: 'instructor-1',
        classId: 'class-1',
      );

      final map = reviewer.toMap();

      expect(map['title'], 'Basketball Fundamentals');
      expect(map['fileUrl'], 'https://example.com/reviewer.pdf');
      expect(map['category'], 'Technique');
      expect(map['subject'], 'Team Sports');
      expect(map['uploadedAt'], isA<FieldValue>());
      expect(map['instructorId'], 'instructor-1');
      expect(map['classId'], 'class-1');
    });
  });
}
