import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/question_model.dart'; // <--- ADD THIS LINE
import '../repositories/task_repository.dart';
import 'auth_provider.dart';
import 'class_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(firestoreProvider));
});
final tasksByLessonProvider = StreamProvider.family<List<TaskModel>, String>((
  ref,
  lessonId,
) {
  if (!ref.watch(bootstrapProfileReadyProvider)) {
    return Stream.value(const <TaskModel>[]);
  }
  return ref.watch(taskRepositoryProvider).getTasksByLesson(lessonId);
});
final allTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <TaskModel>[]);
  }

  final appUser = ref.watch(bootstrapAppUserProvider);
  if (appUser == null) {
    return Stream.value(const <TaskModel>[]);
  }

  switch (appUser.role.trim().toLowerCase()) {
    case 'admin':
      return ref.watch(taskRepositoryProvider).getAllTasks();
    case 'instructor':
      return ref.watch(taskRepositoryProvider).getTasksForInstructor(appUser.uid);
    case 'student':
      final classesAsync = ref.watch(myClassesProvider);
      return classesAsync.when(
        data: (classes) {
          final classIds = classes.map((cls) => cls.id).toList(growable: false);
          if (classIds.isEmpty) {
            return Stream.value(const <TaskModel>[]);
          }
          return ref.watch(taskRepositoryProvider).getTasksForClassIds(classIds);
        },
        loading: () => Stream.value(const <TaskModel>[]),
        error: (_, _) => Stream.value(const <TaskModel>[]),
      );
    default:
      return Stream.value(const <TaskModel>[]);
  }
});

final instructorTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <TaskModel>[]);
  }

  final appUser = ref.watch(bootstrapAppUserProvider);
  if (appUser == null || appUser.role.trim().toLowerCase() != 'instructor') {
    return Stream.value(const <TaskModel>[]);
  }

  return ref.watch(taskRepositoryProvider).getTasksForInstructor(appUser.uid);
});

final tasksForMyClassesProvider = StreamProvider<List<TaskModel>>((ref) {
  final classesAsync = ref.watch(myClassesProvider);
  return classesAsync.when(
    data: (classes) {
      final classIds = classes.map((cls) => cls.id).toList(growable: false);
      if (classIds.isEmpty) {
        return Stream.value(const <TaskModel>[]);
      }
      return ref.watch(taskRepositoryProvider).getTasksForClassIds(classIds);
    },
    loading: () => Stream.value(const <TaskModel>[]),
    error: (_, _) => Stream.value(const <TaskModel>[]),
  );
});

// Student tasks (filtered by current user)
final studentTasksProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <TaskModel>[]);
  }

  final appUser = ref.watch(bootstrapAppUserProvider);
  if (appUser == null || appUser.role.trim().toLowerCase() != 'student') {
    return Stream.value(const <TaskModel>[]);
  }

  // Use Timestamp.now() to avoid errors
  final now = Timestamp.now();

  final stream = ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(appUser.uid)
      .collection('tasks')
      .where('deadline', isGreaterThanOrEqualTo: now)
      .orderBy('deadline')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
      );

  return guardAuthTransitionStream(
    ref,
    stream,
    fallbackValue: const <TaskModel>[],
  );
});
final questionsByTaskProvider =
    StreamProvider.family<List<QuestionModel>, String>((ref, taskId) {
      return ref.watch(taskRepositoryProvider).getQuestionsByTask(taskId);
    });
