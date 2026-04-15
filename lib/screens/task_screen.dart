import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/dashboard_module.dart';
import 'create_task_screen.dart';
import 'student_task_detail_screen.dart';
import 'take_quiz_screen.dart';

class TaskScreen extends ConsumerWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isInstructor = user?.role.toLowerCase() == 'instructor';
    final tasksAsync = isInstructor
        ? ref.watch(instructorTasksProvider)
        : ref.watch(tasksForMyClassesProvider);
    final classesAsync = isInstructor
        ? ref.watch(instructorClassesProvider)
        : ref.watch(myClassesProvider);

    return DashboardModulePage(
      title: 'Tasks & Quizzes',
      subtitle: isInstructor
          ? 'Create separate tasks or quizzes, assign them to classes, and delete deployed items when needed.'
          : 'Review assigned tasks, deadlines, and quizzes for your enrolled classes.',
      floatingActionButton: isInstructor ? const _CreateActions() : null,
      child: classesAsync.when(
        data: (classes) {
          final classesById = {
            for (final classModel in classes) classModel.id: classModel,
          };

          return tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return DashboardEmptyState(
                  icon: Icons.assignment_outlined,
                  title: isInstructor
                      ? 'No tasks or quizzes yet'
                      : 'No tasks assigned yet',
                  message: isInstructor
                      ? 'Use the separate buttons below to publish a task or create a quiz.'
                      : 'Your instructors have not assigned any tasks or quizzes to your current classes yet.',
                  action: isInstructor
                      ? const _CreateActions(inline: true)
                      : null,
                  tone: kNavy,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 104),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final classModel = classesById[task.classId];

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      title: Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: kNavy,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: kNavy.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              DashboardTag(
                                label: task.isQuiz ? 'Quiz' : 'Task',
                                color: task.isQuiz
                                    ? Colors.purple.shade700
                                    : Colors.orange.shade800,
                                icon: task.isQuiz
                                    ? Icons.quiz_outlined
                                    : Icons.assignment_outlined,
                              ),
                              DashboardTag(
                                label: '${task.maxScore} points',
                                color: Colors.orange.shade800,
                                icon: Icons.score_outlined,
                              ),
                              if (classModel != null)
                                DashboardTag(
                                  label: classModel.className,
                                  color: Colors.teal.shade700,
                                  icon: Icons.groups_outlined,
                                ),
                              DashboardTag(
                                label:
                                    'Due ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
                                color: kMaroon,
                                icon: Icons.event_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: isInstructor
                          ? IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Delete',
                              onPressed: () =>
                                  _confirmDelete(context: context, task: task),
                            )
                          : Icon(
                              task.isQuiz
                                  ? Icons.quiz_outlined
                                  : Icons.chevron_right_rounded,
                              color: kNavy,
                            ),
                      onTap: isInstructor
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => task.isQuiz
                                      ? TakeQuizScreen(task: task)
                                      : StudentTaskDetailScreen(task: task),
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
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kNavy)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _confirmDelete({
    required BuildContext context,
    required TaskModel task,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
          'Delete "${task.title}"? Deployed tasks and quizzes can be removed, but they are not editable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
  }
}

class _CreateActions extends StatelessWidget {
  const _CreateActions({this.inline = false});

  final bool inline;

  @override
  Widget build(BuildContext context) {
    final heroPrefix = inline ? 'inline' : 'fab';
    final children = [
      _CreateActionButton(
        heroTag: '$heroPrefix-task',
        label: 'New Task',
        icon: Icons.assignment_add,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CreateTaskScreen(kind: TaskComposerKind.task),
          ),
        ),
      ),
      _CreateActionButton(
        heroTag: '$heroPrefix-quiz',
        label: 'New Quiz',
        icon: Icons.quiz_outlined,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CreateTaskScreen(kind: TaskComposerKind.quiz),
          ),
        ),
      ),
    ];

    if (inline) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: children,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [children[0], const SizedBox(height: 10), children[1]],
    );
  }
}

class _CreateActionButton extends StatelessWidget {
  const _CreateActionButton({
    required this.heroTag,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String heroTag;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: kNavy,
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      icon: Icon(icon, color: Colors.white),
    );
  }
}
