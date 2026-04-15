import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/models/lesson_model.dart';

void main() {
  group('LessonModel', () {
    test('serializes curriculum lesson fields', () {
      final lesson = LessonModel(
        id: 'lesson-1',
        courseId: 'bped',
        classId: 'class-1',
        subject: 'Kinesiology',
        title: 'Principles of Movement',
        description: 'Introduce movement analysis basics.',
        videoUrl: 'https://example.com/video.mp4',
        pdfUrl: 'https://example.com/notes.pdf',
        category: 'Anatomy',
        instructorId: 'instructor-1',
      );

      final map = lesson.toMap();

      expect(map['courseId'], 'bped');
      expect(map['classId'], 'class-1');
      expect(map['subject'], 'Kinesiology');
      expect(map['title'], 'Principles of Movement');
      expect(map['description'], 'Introduce movement analysis basics.');
      expect(map['videoUrl'], 'https://example.com/video.mp4');
      expect(map['pdfUrl'], 'https://example.com/notes.pdf');
      expect(map['category'], 'Anatomy');
      expect(map['instructorId'], 'instructor-1');
    });
  });
}
