import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../services/class_code_service.dart';

class ClassRepository {
  final FirebaseFirestore _firestore;
  ClassRepository(this._firestore);

  Stream<List<ClassModel>> getClasses() {
    return _firestore
        .collection('classes')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClassModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ClassModel>> getClassesForInstructor(String instructorId) {
    return _firestore
        .collection('classes')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClassModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<ClassModel> createClass(ClassModel classData) async {
    final classCode = classData.classCode.isEmpty
        ? await _generateUniqueClassCode()
        : ClassCodeService.sanitize(classData.classCode);

    final payload = {...classData.toMap(), 'classCode': classCode};

    final doc = await _firestore.collection('classes').add(payload);

    return ClassModel(
      id: doc.id,
      className: classData.className,
      subject: classData.subject,
      schedule: classData.schedule,
      classCode: classCode,
      semesterLabel: classData.semesterLabel,
      instructorId: classData.instructorId,
      enrolledStudentIds: classData.enrolledStudentIds,
    );
  }

  Stream<List<ClassModel>> getClassesForStudent(String studentId) {
    return _firestore
        .collection('classes')
        .where('enrolledStudentIds', arrayContains: studentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClassModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<ClassModel?> getClassByCode(String code) async {
    final normalizedCode = ClassCodeService.sanitize(code);
    final query = await _firestore
        .collection('classes')
        .where('classCode', isEqualTo: normalizedCode)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      return null;
    }
    return ClassModel.fromFirestore(query.docs.first);
  }

  Future<void> enrollStudent({
    required String classId,
    required String studentId,
  }) async {
    await _firestore.collection('classes').doc(classId).update({
      'enrolledStudentIds': FieldValue.arrayUnion([studentId]),
    });
  }

  Future<void> unenrollStudent({
    required String classId,
    required String studentId,
  }) async {
    await _firestore.collection('classes').doc(classId).update({
      'enrolledStudentIds': FieldValue.arrayRemove([studentId]),
    });
  }

  Future<String> _generateUniqueClassCode() async {
    for (var attempt = 0; attempt < 12; attempt++) {
      final code = ClassCodeService.generate(Random.secure());
      final query = await _firestore
          .collection('classes')
          .where('classCode', isEqualTo: code)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        return code;
      }
    }

    throw Exception('Unable to generate a unique class code.');
  }
}
