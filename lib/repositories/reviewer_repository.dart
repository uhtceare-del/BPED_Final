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

  Future<void> uploadReviewer(ReviewerModel reviewer) async {
    await firestore.collection('reviewers').add({
      ...reviewer.toMap(),
      'isDeleted': false,
    });
  }
}
