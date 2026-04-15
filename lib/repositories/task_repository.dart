import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/question_model.dart';

class TaskRepository {
  final FirebaseFirestore firestore;
  TaskRepository(this.firestore);

  Stream<List<TaskModel>> getAllTasks() {
    return firestore
        .collection('tasks')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isDeleted'] != true)
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<TaskModel>> getTasksByLesson(String lessonId) {
    return firestore
        .collection('tasks')
        .where('lessonId', isEqualTo: lessonId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isDeleted'] != true)
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<TaskModel>> getTasksForInstructor(String instructorId) {
    return firestore
        .collection('tasks')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isDeleted'] != true)
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<TaskModel>> getTasksForClassIds(List<String> classIds) {
    if (classIds.isEmpty) {
      return Stream.value(const <TaskModel>[]);
    }

    final uniqueIds = classIds.toSet().toList(growable: false);
    final chunks = <List<String>>[];
    for (var i = 0; i < uniqueIds.length; i += 10) {
      final end = (i + 10 < uniqueIds.length) ? i + 10 : uniqueIds.length;
      chunks.add(uniqueIds.sublist(i, end));
    }

    if (chunks.length == 1) {
      return firestore
          .collection('tasks')
          .where('classId', whereIn: chunks.first)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .where((doc) => doc.data()['isDeleted'] != true)
                .map((doc) => TaskModel.fromFirestore(doc))
                .toList(),
          );
    }

    final controller = StreamController<List<TaskModel>>();
    final latestByChunk = <int, List<TaskModel>>{};
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emitCombined() {
      final tasks =
          latestByChunk.values.expand((chunkTasks) => chunkTasks).toList()
            ..sort((a, b) => a.deadline.compareTo(b.deadline));
      controller.add(tasks);
    }

    controller.onListen = () {
      for (var index = 0; index < chunks.length; index++) {
        final subscription = firestore
            .collection('tasks')
            .where('classId', whereIn: chunks[index])
            .snapshots()
            .listen((snapshot) {
              latestByChunk[index] = snapshot.docs
                  .where((doc) => doc.data()['isDeleted'] != true)
                  .map((doc) => TaskModel.fromFirestore(doc))
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

  // --- NEW: Quiz Question Methods ---

  Future<void> addQuestion(QuestionModel question) async {
    await firestore.collection('questions').add(question.toMap());
  }

  Future<void> updateGrade(String submissionId, String grade) async {
    await firestore.collection('submissions').doc(submissionId).update({
      'grade': grade,
    });
  }

  Future<String> createTask(TaskModel task) async {
    final doc = await firestore.collection('tasks').add({
      'title': task.title,
      'description': task.description,
      'maxScore': task.maxScore,
      'deadline': task.deadline,
      'lessonId': task.lessonId,
      'instructorId': task.instructorId,
      'classId': task.classId,
      'kind': task.kind,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
    });
    return doc.id;
  }

  Stream<List<QuestionModel>> getQuestionsByTask(String taskId) {
    return firestore
        .collection('questions')
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuestionModel.fromFirestore(doc))
              .toList(),
        );
  }
}
