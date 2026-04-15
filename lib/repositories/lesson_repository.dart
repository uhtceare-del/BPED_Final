import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';

class LessonRepository {
  final FirebaseFirestore firestore;
  LessonRepository(this.firestore);

  Stream<List<LessonModel>> getAllLessons() {
    return firestore
        .collection('lessons')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isDeleted'] != true)
              .map((doc) => LessonModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<LessonModel>> getLessonsByCourse(String courseId) {
    return firestore
        .collection('lessons')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isDeleted'] != true)
              .map((doc) => LessonModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<LessonModel>> getLessonsByClass(String classId) {
    return firestore
        .collection('lessons')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isDeleted'] != true)
              .map((doc) => LessonModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> createLesson(LessonModel lesson) async {
    await firestore.collection('lessons').add({
      ...lesson.toMap(),
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addLesson(LessonModel lesson) async {
    await createLesson(lesson);
  }
}
