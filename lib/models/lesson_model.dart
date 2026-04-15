import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String courseId;
  final String classId;
  final String subject;
  final String title;
  final String description;
  final String? videoUrl;
  final String? pdfUrl; // NEW: For technique demonstrations
  final String? category; // NEW: e.g., 'Anatomy', 'Pedagogy'

  // --- NEW SECURITY FIELD ---
  final String instructorId;

  LessonModel({
    required this.id,
    required this.courseId,
    required this.classId,
    required this.subject,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.pdfUrl,
    required this.category,
    required this.instructorId, // Added here
  });

  // Factory constructor from Firestore
  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null || data is! Map<String, dynamic>) {
      // Return empty/default values if data is null
      return LessonModel(
        id: doc.id,
        courseId: '',
        classId: '',
        subject: '',
        title: '',
        description: '',
        videoUrl: '',
        pdfUrl: '',
        category: '',
        instructorId: '', // Added here
      );
    }

    return LessonModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      classId: data['classId'] ?? '',
      subject: data['subject'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      pdfUrl: data['pdfUrl'] ?? '',
      category: data['category'] ?? '',
      instructorId: data['instructorId'] ?? '', // Added here
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'classId': classId,
      'subject': subject,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'pdfUrl': pdfUrl,
      'category': category,
      // --- ADDED TO DATABASE SAVE ---
      'instructorId': instructorId,
    };
  }
}
