import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../repositories/class_repository.dart';
import 'auth_provider.dart';

// 1. The Repository Provider
final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository(ref.watch(firestoreProvider));
});

// 2. The Stream Provider for all classes
final allClassesProvider = StreamProvider<List<ClassModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <ClassModel>[]);
  }

  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (authUser) {
      if (authUser == null) {
        return Stream.value(const <ClassModel>[]);
      }

      final repository = ref.watch(classRepositoryProvider);
      return repository.getClasses();
    },
    loading: () => Stream.value(const <ClassModel>[]),
    error: (_, _) => Stream.value(const <ClassModel>[]),
  );
});

final instructorClassesProvider = StreamProvider<List<ClassModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <ClassModel>[]);
  }

  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(const <ClassModel>[]);
      }
      return ref
          .watch(classRepositoryProvider)
          .getClassesForInstructor(user.uid);
    },
    loading: () => Stream.value(const <ClassModel>[]),
    error: (_, _) => Stream.value(const <ClassModel>[]),
  );
});

// 3. Provider for student's classes
final myClassesProvider = StreamProvider<List<ClassModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <ClassModel>[]);
  }

  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(const <ClassModel>[]);
      }
      return ref.watch(classRepositoryProvider).getClassesForStudent(user.uid);
    },
    loading: () => Stream.value(const <ClassModel>[]),
    error: (_, _) => Stream.value(const <ClassModel>[]),
  );
});

// 4. Provider for students enrolled in a specific class
final studentsInClassProvider = StreamProvider.family<List<AppUser>, String>((
  ref,
  classId,
) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <AppUser>[]);
  }

  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(const <AppUser>[]);
  }

  final firestore = ref.watch(firestoreProvider);
  final stream = firestore
      .collection('classes')
      .doc(classId)
      .snapshots()
      .asyncExpand((classDoc) async* {
        final enrolledStudentIds = List<String>.from(
          classDoc.data()?['enrolledStudentIds'] ?? [],
        );

        if (enrolledStudentIds.isEmpty) {
          yield const <AppUser>[];
          return;
        }

        final userDocs = await Future.wait(
          enrolledStudentIds.map(
            (uid) => firestore.collection('users').doc(uid).get(),
          ),
        );

        final students = userDocs
            .where((doc) => doc.exists && doc.data() != null)
            .map((doc) => AppUser.fromFirestore(doc.data()!, doc.id))
            .toList();

        yield students;
      });

  return guardAuthTransitionStream(
    ref,
    stream,
    fallbackValue: const <AppUser>[],
  );
});
