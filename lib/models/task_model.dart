import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final int maxScore;
  final DateTime deadline;
  final String?
  lessonId; // Make this optional if a task isn't always linked to a lesson

  // --- NEW SECURITY FIELDS ---
  final String instructorId;
  final String classId;
  final String kind;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.maxScore,
    required this.deadline,
    this.lessonId, // Optional
    required this.instructorId, // Added here
    required this.classId, // Added here
    this.kind = 'task',
  });

  bool get isQuiz => kind == 'quiz';

  /// Create TaskModel from Firestore DocumentSnapshot
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse deadline safely
    DateTime parsedDeadline = DateTime.now();
    final rawDeadline = data['deadline'];

    if (rawDeadline != null) {
      if (rawDeadline is Timestamp) {
        parsedDeadline = rawDeadline.toDate();
      } else if (rawDeadline is DateTime) {
        parsedDeadline = rawDeadline;
      } else if (rawDeadline is String) {
        parsedDeadline = DateTime.tryParse(rawDeadline) ?? DateTime.now();
      }
    }

    // Parse maxScore safely
    int parsedMaxScore = 100;
    final rawMaxScore = data['maxScore'];
    if (rawMaxScore != null) {
      if (rawMaxScore is int) {
        parsedMaxScore = rawMaxScore;
      } else {
        parsedMaxScore = int.tryParse(rawMaxScore.toString()) ?? 100;
      }
    }

    return TaskModel(
      id: doc.id,
      lessonId: data['lessonId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      maxScore: parsedMaxScore,
      deadline: parsedDeadline,
      // --- ADDED TO DATABASE READ ---
      instructorId: data['instructorId'] ?? '',
      classId: data['classId'] ?? '',
      kind: data['kind'] ?? 'task',
    );
  }

  /// Convert TaskModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'title': title,
      'description': description,
      'maxScore': maxScore,
      'deadline': Timestamp.fromDate(deadline), // store as Timestamp
      // --- ADDED TO DATABASE SAVE ---
      'instructorId': instructorId,
      'classId': classId,
      'kind': kind,
    };
  }
}
