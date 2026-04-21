import 'dart:async';

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

  Stream<List<LessonModel>> getLessonsForInstructor(String instructorId) {
    return firestore
        .collection('lessons')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isDeleted'] != true)
              .map((doc) => LessonModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<LessonModel>> getLessonsForClassIds(List<String> classIds) {
    if (classIds.isEmpty) {
      return Stream.value(const <LessonModel>[]);
    }

    final uniqueIds = classIds.toSet().toList(growable: false);
    final chunks = <List<String>>[];
    for (var i = 0; i < uniqueIds.length; i += 10) {
      final end = (i + 10 < uniqueIds.length) ? i + 10 : uniqueIds.length;
      chunks.add(uniqueIds.sublist(i, end));
    }

    if (chunks.length == 1) {
      return firestore
          .collection('lessons')
          .where('classId', whereIn: chunks.first)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .where((doc) => doc.data()['isDeleted'] != true)
                .map((doc) => LessonModel.fromFirestore(doc))
                .toList(),
          );
    }

    final controller = StreamController<List<LessonModel>>();
    final latestByChunk = <int, List<LessonModel>>{};
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emitCombined() {
      final lessons =
          latestByChunk.values.expand((chunkLessons) => chunkLessons).toList()
            ..sort((a, b) => a.title.compareTo(b.title));
      controller.add(lessons);
    }

    controller.onListen = () {
      for (var index = 0; index < chunks.length; index++) {
        final subscription = firestore
            .collection('lessons')
            .where('classId', whereIn: chunks[index])
            .snapshots()
            .listen((snapshot) {
              latestByChunk[index] = snapshot.docs
                  .where((doc) => doc.data()['isDeleted'] != true)
                  .map((doc) => LessonModel.fromFirestore(doc))
                  .toList();
              emitCombined();
            }, onError: controller.addError);
        subscriptions.add(subscription);
      }
    };

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
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
