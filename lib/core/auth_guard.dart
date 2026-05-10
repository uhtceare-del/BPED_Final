import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final signOutInProgressProvider = StateProvider<bool>((ref) => false);

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

bool shouldIgnoreAuthTransitionError(Ref ref, Object error) {
  if (error is! FirebaseException) {
    return false;
  }

  if (error.plugin != 'cloud_firestore' || error.code != 'permission-denied') {
    return false;
  }

  return ref.read(signOutInProgressProvider) ||
      ref.read(firebaseAuthProvider).currentUser == null;
}

Stream<T> guardAuthTransitionStream<T>(
  Ref ref,
  Stream<T> stream, {
  required T fallbackValue,
}) async* {
  try {
    yield* stream;
  } catch (error) {
    if (shouldIgnoreAuthTransitionError(ref, error)) {
      yield fallbackValue;
      return;
    }
    rethrow;
  }
}

Future<T> guardAuthTransitionFuture<T>(
  Ref ref,
  Future<T> Function() action, {
  required T fallbackValue,
}) async {
  try {
    return await action();
  } catch (error) {
    if (shouldIgnoreAuthTransitionError(ref, error)) {
      return fallbackValue;
    }
    rethrow;
  }
}
