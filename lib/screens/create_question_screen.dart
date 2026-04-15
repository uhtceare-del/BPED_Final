import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/question_model.dart';
import '../providers/task_provider.dart';
import '../widgets/dashboard_module.dart';

class CreateQuestionScreen extends ConsumerStatefulWidget {
  const CreateQuestionScreen({super.key, required this.taskId, this.taskTitle});

  final String taskId;
  final String? taskTitle;

  @override
  ConsumerState<CreateQuestionScreen> createState() =>
      _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends ConsumerState<CreateQuestionScreen> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _choiceControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  int _correctAnswerIndex = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _choiceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addChoice() {
    setState(() {
      _choiceControllers.add(TextEditingController());
    });
  }

  void _removeChoice(int index) {
    setState(() {
      _choiceControllers[index].dispose();
      _choiceControllers.removeAt(index);
      if (_correctAnswerIndex >= _choiceControllers.length) {
        _correctAnswerIndex = 0;
      }
    });
  }

  void _resetForm() {
    _questionController.clear();
    for (var index = _choiceControllers.length - 1; index >= 2; index--) {
      _choiceControllers[index].dispose();
      _choiceControllers.removeAt(index);
    }
    for (final controller in _choiceControllers) {
      controller.clear();
    }
    _correctAnswerIndex = 0;
  }

  Future<void> _saveQuestion() async {
    final choicesText = _choiceControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (_questionController.text.trim().isEmpty || choicesText.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a question and at least 2 choices.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final newQuestion = QuestionModel(
      id: '',
      taskId: widget.taskId,
      questionText: _questionController.text.trim(),
      choices: choicesText,
      correctAnswerIndex: _correctAnswerIndex,
    );

    try {
      await ref.read(taskRepositoryProvider).addQuestion(newQuestion);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question successfully saved.')),
      );
      setState(_resetForm);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save question: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DashboardModulePage(
            title: 'Add Quiz Questions',
            subtitle:
                'Save each question as you build the quiz, then finish when you are done.',
            trailing: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Finish Quiz'),
            ),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                DashboardSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((widget.taskTitle ?? '').isNotEmpty) ...[
                        Text(
                          widget.taskTitle!,
                          style: const TextStyle(
                            color: kNavy,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Questions are written directly to this quiz. Instructors can delete deployed items but not edit them.',
                          style: TextStyle(
                            color: kNavy.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextField(
                        controller: _questionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Question Text',
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Choices',
                        style: TextStyle(
                          color: kNavy,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select the radio button for the correct answer.',
                        style: TextStyle(
                          color: kNavy.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RadioGroup<int>(
                        groupValue: _correctAnswerIndex,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _correctAnswerIndex = value);
                          }
                        },
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _choiceControllers.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Radio<int>(value: index),
                                  Expanded(
                                    child: TextField(
                                      controller: _choiceControllers[index],
                                      decoration: InputDecoration(
                                        hintText: 'Choice ${index + 1}',
                                      ),
                                    ),
                                  ),
                                  if (_choiceControllers.length > 2)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeChoice(index),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addChoice,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Another Choice'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isLoading ? null : _saveQuestion,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SAVE QUESTION',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
