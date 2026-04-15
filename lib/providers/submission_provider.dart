import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/submission_model.dart';
import '../repositories/submission_repository.dart';
import 'auth_provider.dart'; // To get the current user's ID

// 1. The Repository Provider
final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  return SubmissionRepository(ref.watch(firestoreProvider));
});

// 2. All Submissions (For Instructors)
final submissionProvider = StreamProvider<List<SubmissionModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <SubmissionModel>[]);
  }

  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (authUser) {
      if (authUser == null) {
        return Stream.value(const <SubmissionModel>[]);
      }

      final repository = ref.watch(submissionRepositoryProvider);
      return repository.getAllSubmissions();
    },
    loading: () => Stream.value(const <SubmissionModel>[]),
    error: (_, _) => Stream.value(const <SubmissionModel>[]),
  );
});

// 3. My Submissions (For Students)
final mySubmissionsProvider = StreamProvider<List<SubmissionModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <SubmissionModel>[]);
  }

  final repository = ref.watch(submissionRepositoryProvider);

  // Use watch to get the AsyncValue of the auth state
  final authState = ref.watch(authStateProvider);

  // We return the stream only if the user is data-ready and not null
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return repository.getSubmissionsByStudent(user.uid);
    },
    loading: () => Stream.value([]), // Return empty stream while loading
    error: (err, stack) => Stream.value([]), // Return empty stream on error
  );
});

final securedSubmissionsProvider =
    StreamProvider.autoDispose<List<SubmissionModel>>((ref) {
      if (ref.watch(signOutInProgressProvider)) {
        return Stream.value(const <SubmissionModel>[]);
      }

      final user = ref.watch(currentUserProvider).value;
      if (user == null) {
        return Stream.value(const <SubmissionModel>[]);
      }

      final db = FirebaseFirestore.instance;
      if (user.role.toLowerCase() == 'instructor') {
        final stream = db
            .collection('submissions')
            .where('instructorId', isEqualTo: user.uid)
            .orderBy('submittedAt', descending: true)
            .snapshots()
            .map(
              (snap) => snap.docs
                  .map((doc) => SubmissionModel.fromFirestore(doc))
                  .toList(),
            );
        return guardAuthTransitionStream(
          ref,
          stream,
          fallbackValue: const <SubmissionModel>[],
        );
      }

      final stream = db
          .collection('submissions')
          .where('studentId', isEqualTo: user.uid)
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) => SubmissionModel.fromFirestore(doc))
                .toList(),
          );
      return guardAuthTransitionStream(
        ref,
        stream,
        fallbackValue: const <SubmissionModel>[],
      );
    });
