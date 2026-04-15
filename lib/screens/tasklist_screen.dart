import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'student_task_detail_screen.dart';
import '../models/task_model.dart';
// NOTE: Ensure your TaskModel is imported if it's not already in task_provider!
// import '../models/task_model.dart';
import '../constants/app_colors.dart';

// --- THE FIX: SECURED ROLE-BASED TASK STREAM ---
final securedTasksStreamProvider = StreamProvider.autoDispose<List<dynamic>>((
  ref,
) async* {
  final user = ref.watch(currentUserProvider).value;

  if (user == null) {
    yield [];
    return;
  }

  final isInstructor = user.role.toLowerCase() == 'instructor';
  final db = FirebaseFirestore.instance;

  if (isInstructor) {
    // INSTRUCTOR: Only see tasks they created
    yield* db
        .collection('tasks')
        .where('instructorId', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TaskModel.fromFirestore(doc),
              ) // Ensure TaskModel has fromFirestore!
              .toList(),
        );
  } else {
    // STUDENT: 1st - Get the classes they are enrolled in
    final classSnap = await db
        .collection('classes')
        .where('enrolledStudents', arrayContains: user.uid)
        .get();

    final enrolledClassIds = classSnap.docs.map((d) => d.id).toList();

    if (enrolledClassIds.isEmpty) {
      // Not enrolled in any classes = No tasks!
      yield [];
      return;
    }

    // STUDENT: 2nd - Get tasks assigned to those specific classes
    yield* db.collection('tasks').snapshots().map((snapshot) {
      return snapshot.docs
          // Filter tasks so they only show if their classId matches an enrolled class
          .where((doc) => enrolledClassIds.contains(doc.data()['classId']))
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    });
  }
});
// --------------------------------------------------

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WATCH THE NEW SECURED PROVIDER
    final tasksAsync = ref.watch(securedTasksStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isInstructor = currentUser?.role.toLowerCase() == 'instructor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Tasks & Quizzes',
          style: TextStyle(fontWeight: FontWeight.bold, color: kNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: kNavy),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return _buildEmptyState(isInstructor);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in,
                      color: Colors.orange,
                    ),
                  ),
                  title: Text(
                    task.title ?? 'Unnamed Task',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kNavy,
                    ),
                  ),
                  subtitle: Text(
                    "Max Score: ${task.maxScore ?? 0}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // This goes to the student task detail screen!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StudentTaskDetailScreen(task: task),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kNavy)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState(bool isInstructor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt_rounded,
              size: 80,
              color: Colors.orange.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Active Tasks',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              isInstructor
                  ? 'Create a task from the Instructor Dashboard.'
                  : 'Woohoo! You have no pending assignments right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
