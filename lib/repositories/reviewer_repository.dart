import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reviewer_model.dart';

class ReviewerRepository {
  final FirebaseFirestore firestore;
  ReviewerRepository(this.firestore);

  Stream<List<ReviewerModel>> getAllReviewers() {
    return firestore
        .collection('reviewers')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((doc) => doc.data()['isDeleted'] != true)
              .map((doc) => ReviewerModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ReviewerModel>> getReviewersForInstructor(String instructorId) {
    return firestore
        .collection('reviewers')
        .where('instructorId', isEqualTo: instructorId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((doc) => doc.data()['isDeleted'] != true)
              .map((doc) => ReviewerModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ReviewerModel>> getReviewersForClassIds(List<String> classIds) {
    if (classIds.isEmpty) {
      return Stream.value(const <ReviewerModel>[]);
    }

    final uniqueIds = classIds.toSet().toList(growable: false);
    final chunks = <List<String>>[];
    for (var i = 0; i < uniqueIds.length; i += 10) {
      final end = (i + 10 < uniqueIds.length) ? i + 10 : uniqueIds.length;
      chunks.add(uniqueIds.sublist(i, end));
    }

    if (chunks.length == 1) {
      return firestore
          .collection('reviewers')
          .where('classId', whereIn: chunks.first)
          .orderBy('uploadedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .where((doc) => doc.data()['isDeleted'] != true)
                .map((doc) => ReviewerModel.fromFirestore(doc))
                .toList(),
          );
    }

    final controller = StreamController<List<ReviewerModel>>();
    final latestByChunk = <int, List<ReviewerModel>>{};
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emitCombined() {
      final reviewers =
          latestByChunk.values
              .expand((chunkReviewers) => chunkReviewers)
              .toList()
            ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      controller.add(reviewers);
    }

    controller.onListen = () {
      for (var index = 0; index < chunks.length; index++) {
        final subscription = firestore
            .collection('reviewers')
            .where('classId', whereIn: chunks[index])
            .orderBy('uploadedAt', descending: true)
            .snapshots()
            .listen((snapshot) {
              latestByChunk[index] = snapshot.docs
                  .where((doc) => doc.data()['isDeleted'] != true)
                  .map((doc) => ReviewerModel.fromFirestore(doc))
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

  Future<void> uploadReviewer(ReviewerModel reviewer) async {
    await firestore.collection('reviewers').add({
      ...reviewer.toMap(),
      'isDeleted': false,
    });
  }
}
