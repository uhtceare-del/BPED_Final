import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String taskId;
  final String studentId;
  final String studentEmail;
  final String?
  fileUrl; // <-- ADDED: This stores the link to the student's PDF/Video
  final DateTime submittedAt;
  final String? grade;
  final String
  instructorId; // <-- ADDED: This lets the Master Key find this submission

  SubmissionModel({
    required this.id,
    required this.taskId,
    required this.studentId,
    required this.studentEmail,
    this.fileUrl, // <-- ADDED
    required this.submittedAt,
    this.grade,
    required this.instructorId, // <-- ADDED
  });

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubmissionModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      fileUrl: data['fileUrl'], // <-- FETCH from Firestore
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      grade: data['grade'],
      instructorId: data['instructorId'] ?? '', // <-- FETCH from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'studentId': studentId,
      'studentEmail': studentEmail,
      'fileUrl': fileUrl, // <-- SAVE to Firestore
      'submittedAt': submittedAt,
      'grade': grade,
      'instructorId': instructorId, // <-- SAVE to Firestore
    };
  }
}
