import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/class_model.dart';
import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/dashboard_module.dart';
import 'create_question_screen.dart';

enum TaskComposerKind { task, quiz }

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key, required this.kind});

  final TaskComposerKind kind;

  bool get isQuiz => kind == TaskComposerKind.quiz;

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _scoreController = TextEditingController(text: '100');

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedClassId;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class section.')),
      );
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      return;
    }

    setState(() => _isSaving = true);

    final newTask = TaskModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      maxScore: int.tryParse(_scoreController.text) ?? 100,
      deadline: _selectedDate,
      lessonId: null,
      instructorId: user.uid,
      classId: _selectedClassId!,
      kind: widget.isQuiz ? 'quiz' : 'task',
    );

    try {
      final taskId = await ref.read(taskRepositoryProvider).createTask(newTask);

      if (!mounted) {
        return;
      }

      if (widget.isQuiz) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                CreateQuestionScreen(taskId: taskId, taskTitle: newTask.title),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(instructorClassesProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: DashboardModulePage(
              title: widget.isQuiz ? 'New Quiz' : 'New Task',
              subtitle: widget.isQuiz
                  ? 'Create the quiz details, assign a class, then save to continue adding questions.'
                  : 'Create a performance or file-submission task, assign it to a class, and save it.',
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  DashboardSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assignment Details',
                          style: TextStyle(
                            color: kNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isQuiz
                              ? 'Quiz details are saved first. You will add questions in the next step.'
                              : 'Tasks are saved immediately and remain delete-only after deployment.',
                          style: TextStyle(
                            color: kNavy.withValues(alpha: 0.62),
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        classesAsync.when(
                          data: (classes) => _ClassDropdown(
                            classes: classes,
                            selectedClassId: _selectedClassId,
                            onChanged: (value) =>
                                setState(() => _selectedClassId = value),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (error, _) => Text(
                            'Could not load class sections: $error',
                            style: const TextStyle(color: kMaroon),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: widget.isQuiz
                                ? 'Quiz Title'
                                : 'Task Title',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a ${widget.isQuiz ? 'quiz' : 'task'} title'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: widget.isQuiz
                                ? 'Quiz Instructions'
                                : 'Task Instructions',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter instructions'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _scoreController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max Points',
                                ),
                                validator: (value) =>
                                    int.tryParse(value ?? '') == null
                                    ? 'Enter a valid number'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(Icons.calendar_month),
                                label: Text(
                                  '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.isQuiz) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kNavyTint,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kNavyBorder),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: kNavy,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'After saving, the app opens question entry so you can finish the quiz before leaving.',
                                    style: TextStyle(
                                      color: kNavy,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveTask,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            widget.isQuiz ? 'SAVE QUIZ' : 'SAVE TASK',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassDropdown extends StatelessWidget {
  const _ClassDropdown({
    required this.classes,
    required this.selectedClassId,
    required this.onChanged,
  });

  final List<ClassModel> classes;
  final String? selectedClassId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const Text(
        'No class sections available. Create a class first before adding a task or quiz.',
        style: TextStyle(color: kMaroon, fontWeight: FontWeight.w600),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedClassId,
      decoration: const InputDecoration(
        labelText: 'Assign Class Section',
        prefixIcon: Icon(Icons.groups_outlined),
      ),
      items: classes
          .map(
            (classModel) => DropdownMenuItem(
              value: classModel.id,
              child: Text('${classModel.className} • ${classModel.subject}'),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Select a class section' : null,
    );
  }
}
