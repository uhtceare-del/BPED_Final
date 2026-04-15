import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String className;
  final String subject;
  final String schedule;
  final String classCode;
  final String semesterLabel;
  final String instructorId;
  final List<String> enrolledStudentIds;

  ClassModel({
    required this.id,
    required this.className,
    required this.subject,
    required this.schedule,
    required this.classCode,
    required this.semesterLabel,
    required this.instructorId,
    this.enrolledStudentIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subject': subject,
      'schedule': schedule,
      'classCode': classCode,
      'semesterLabel': semesterLabel,
      'instructorId': instructorId,
      'enrolledStudentIds': enrolledStudentIds,
    };
  }

  factory ClassModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      className: data['className'] ?? '',
      subject: data['subject'] ?? '',
      schedule: data['schedule'] ?? '',
      classCode: data['classCode'] ?? '',
      semesterLabel: data['semesterLabel'] ?? '1st Semester',
      instructorId: data['instructorId'] ?? '',
      enrolledStudentIds: List<String>.from(data['enrolledStudentIds'] ?? []),
    );
  }
}
