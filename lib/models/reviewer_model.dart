import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewerModel {
  final String id;
  final String title;
  final String fileUrl;
  final String category;
  final String subject;
  final DateTime uploadedAt;

  // --- NEW SECURITY FIELDS ---
  final String instructorId;
  final String classId;

  ReviewerModel({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.category,
    required this.subject,
    required this.uploadedAt,
    required this.instructorId, // Added here
    required this.classId, // Added here
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'fileUrl': fileUrl,
      'category': category,
      'subject': subject,
      'uploadedAt': FieldValue.serverTimestamp(),
      // --- ADDED TO DATABASE SAVE ---
      'instructorId': instructorId,
      'classId': classId,
    };
  }

  factory ReviewerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewerModel(
      id: doc.id,
      // Safely checks for 'title' first, but falls back to 'name' just in case
      title: data['title'] ?? data['name'] ?? 'Unnamed',
      fileUrl: data['fileUrl'] ?? '',
      category: data['category'] ?? 'General',
      subject: data['subject'] ?? 'General',
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // --- ADDED TO DATABASE READ ---
      instructorId: data['instructorId'] ?? '',
      classId: data['classId'] ?? '',
    );
  }
}
