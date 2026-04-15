import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reviewer_model.dart';
import '../repositories/reviewer_repository.dart';

final reviewerRepositoryProvider = Provider<ReviewerRepository>((ref) {
  return ReviewerRepository(FirebaseFirestore.instance);
});

final allReviewersProvider = StreamProvider<List<ReviewerModel>>((ref) {
  return ref.watch(reviewerRepositoryProvider).getAllReviewers();
});