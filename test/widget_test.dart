import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/models/class_model.dart';

void main() {
  test('ClassModel serializes class codes', () {
    final model = ClassModel(
      id: 'class-1',
      className: 'BPED 1-A',
      subject: 'Team Sports',
      schedule: 'MWF 8:00 AM',
      classCode: 'AB23CD',
      semesterLabel: '1st Semester',
      instructorId: 'teacher-1',
      enrolledStudentIds: const ['student-1'],
    );

    final map = model.toMap();

    expect(map['classCode'], 'AB23CD');
    expect(map['enrolledStudentIds'], ['student-1']);
  });
}

