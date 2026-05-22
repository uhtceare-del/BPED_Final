import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/class_model.dart';
import '../models/reviewer_model.dart';
import 'auth_provider.dart';
import 'class_provider.dart';
import '../repositories/reviewer_repository.dart';

final reviewerRepositoryProvider = Provider<ReviewerRepository>((ref) {
  return ReviewerRepository(FirebaseFirestore.instance);
});

final allReviewersProvider = StreamProvider<List<ReviewerModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <ReviewerModel>[]);
  }

  final appUser = ref.watch(bootstrapAppUserProvider);
  if (appUser == null) {
    return Stream.value(const <ReviewerModel>[]);
  }

  final repository = ref.watch(reviewerRepositoryProvider);
  switch (appUser.role.trim().toLowerCase()) {
    case 'admin':
      return repository.getAllReviewers();
    case 'instructor':
      return repository.getReviewersForInstructor(appUser.uid);
    case 'student':
      final classesAsync = ref.watch(myClassesProvider);
      return classesAsync.when(
        data: (classes) {
          final classIds = classes.map((cls) => cls.id).toList(growable: false);
          if (classIds.isEmpty) {
            return Stream.value(const <ReviewerModel>[]);
          }
          return repository.getReviewersForClassIds(classIds);
        },
        loading: () => Stream.value(const <ReviewerModel>[]),
        error: (_, _) => Stream.value(const <ReviewerModel>[]),
      );
    default:
      return Stream.value(const <ReviewerModel>[]);
  }
});

final reviewersByClassProvider =
    StreamProvider.family<List<ReviewerModel>, String>((ref, classId) {
      if (ref.watch(signOutInProgressProvider)) {
        return Stream.value(const <ReviewerModel>[]);
      }

      final appUser = ref.watch(bootstrapAppUserProvider);
      if (appUser == null) {
        return Stream.value(const <ReviewerModel>[]);
      }

      final hasAccess =
          appUser.role.trim().toLowerCase() != 'student' ||
          (ref.watch(myClassesProvider).value ?? const <ClassModel>[]).any(
            (cls) => cls.id == classId,
          );
      if (!hasAccess) {
        return Stream.value(const <ReviewerModel>[]);
      }

      final stream = ref
          .watch(reviewerRepositoryProvider)
          .getReviewersForClassIds([classId]);
      return guardAuthTransitionStream(
        ref,
        stream,
        fallbackValue: const <ReviewerModel>[],
      );
    });
