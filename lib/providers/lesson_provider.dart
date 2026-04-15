import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/lesson_repository.dart';
import '../models/lesson_model.dart';
import 'auth_provider.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository(ref.watch(firestoreProvider));
});

// All lessons
final allLessonsProvider = StreamProvider<List<LessonModel>>((ref) {
  return ref.watch(lessonRepositoryProvider).getAllLessons();
});

// Lessons by course
final lessonsByCourseProvider = StreamProvider.family<List<LessonModel>, String>((ref, courseId) {
  return ref.watch(lessonRepositoryProvider).getLessonsByCourse(courseId);
});

final lessonsByClassProvider = StreamProvider.family<List<LessonModel>, String>((ref, classId) {
  return ref.watch(lessonRepositoryProvider).getLessonsByClass(classId);
});
