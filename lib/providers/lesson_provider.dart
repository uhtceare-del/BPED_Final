import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lesson_model.dart';
import '../repositories/lesson_repository.dart';
import 'auth_provider.dart';
import 'class_provider.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository(ref.watch(firestoreProvider));
});

final allLessonsProvider = StreamProvider<List<LessonModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <LessonModel>[]);
  }

  final appUser = ref.watch(bootstrapAppUserProvider);
  if (appUser == null) {
    return Stream.value(const <LessonModel>[]);
  }

  final repository = ref.watch(lessonRepositoryProvider);
  switch (appUser.role.trim().toLowerCase()) {
    case 'admin':
      return repository.getAllLessons();
    case 'instructor':
      return repository.getLessonsForInstructor(appUser.uid);
    case 'student':
      final classesAsync = ref.watch(myClassesProvider);
      return classesAsync.when(
        data: (classes) {
          final classIds = classes.map((cls) => cls.id).toList();
          if (classIds.isEmpty) {
            return Stream.value(const <LessonModel>[]);
          }
          return repository.getLessonsForClassIds(classIds);
        },
        loading: () => Stream.value(const <LessonModel>[]),
        error: (_, _) => Stream.value(const <LessonModel>[]),
      );
    default:
      return Stream.value(const <LessonModel>[]);
  }
});

final lessonsByCourseProvider =
    StreamProvider.family<List<LessonModel>, String>((ref, courseId) {
      if (!ref.watch(bootstrapProfileReadyProvider)) {
        return Stream.value(const <LessonModel>[]);
      }
      return ref.watch(lessonRepositoryProvider).getLessonsByCourse(courseId);
    });

final lessonsByClassProvider =
    StreamProvider.family<List<LessonModel>, String>((ref, classId) {
      if (!ref.watch(bootstrapProfileReadyProvider)) {
        return Stream.value(const <LessonModel>[]);
      }
      return ref.watch(lessonRepositoryProvider).getLessonsByClass(classId);
    });

final lessonsForCurrentUserProvider =
    StreamProvider.autoDispose<List<LessonModel>>((ref) {
      if (ref.watch(signOutInProgressProvider)) {
        return Stream.value(const <LessonModel>[]);
      }

      final appUser = ref.watch(bootstrapAppUserProvider);
      if (appUser == null) {
        return Stream.value(const <LessonModel>[]);
      }

      final repository = ref.watch(lessonRepositoryProvider);
      switch (appUser.role.trim().toLowerCase()) {
        case 'admin':
          return repository.getAllLessons();
        case 'instructor':
          return repository.getLessonsForInstructor(appUser.uid);
        case 'student':
          final classesAsync = ref.watch(myClassesProvider);
          return classesAsync.when(
            data: (classes) {
              final classIds = classes.map((cls) => cls.id).toList();
              if (classIds.isEmpty) {
                return Stream.value(const <LessonModel>[]);
              }
              return repository.getLessonsForClassIds(classIds);
            },
            loading: () => Stream.value(const <LessonModel>[]),
            error: (_, _) => Stream.value(const <LessonModel>[]),
          );
        default:
          return Stream.value(const <LessonModel>[]);
      }
    });
