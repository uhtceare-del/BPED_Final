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

  final appUser = ref.watch(bootstrapAppUserProvider);
  if (appUser == null) {
    return Stream.value(const <ClassModel>[]);
  }

  final repository = ref.watch(classRepositoryProvider);
  switch (appUser.role.trim().toLowerCase()) {
    case 'admin':
      return repository.getClasses();
    case 'instructor':
      return repository.getClassesForInstructor(appUser.uid);
    case 'student':
      return repository.getClassesForStudent(appUser.uid);
    default:
      return Stream.value(const <ClassModel>[]);
  }
});

final instructorClassesProvider = StreamProvider<List<ClassModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <ClassModel>[]);
  }

  final appUser = ref.watch(bootstrapAppUserProvider);
  if (appUser == null || appUser.role.trim().toLowerCase() != 'instructor') {
    return Stream.value(const <ClassModel>[]);
  }

  return ref
      .watch(classRepositoryProvider)
      .getClassesForInstructor(appUser.uid);
});

// 3. Provider for student's classes
final myClassesProvider = StreamProvider<List<ClassModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <ClassModel>[]);
  }

  final appUser = ref.watch(bootstrapAppUserProvider);
  if (appUser == null || appUser.role.trim().toLowerCase() != 'student') {
    return Stream.value(const <ClassModel>[]);
  }

  return ref.watch(classRepositoryProvider).getClassesForStudent(appUser.uid);
});

// 4. Provider for students enrolled in a specific class
final studentsInClassProvider = StreamProvider.family<List<AppUser>, String>((
  ref,
  classId,
) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <AppUser>[]);
  }

  final appUser = ref.watch(bootstrapAppUserProvider);
  if (appUser == null) {
    return Stream.value(const <AppUser>[]);
  }

  if (appUser.role.trim().toLowerCase() == 'student') {
    final enrolledClasses = ref.watch(myClassesProvider).value ?? const [];
    final isEnrolled = enrolledClasses.any((cls) => cls.id == classId);
    if (!isEnrolled) {
      return Stream.value(const <AppUser>[]);
    }
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
