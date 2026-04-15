import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/question_model.dart';
import '../models/submission_model.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/submission_provider.dart';

class TakeQuizScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TakeQuizScreen({super.key, required this.task});

  @override
  ConsumerState<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends ConsumerState<TakeQuizScreen> {
  final Map<String, int> _selectedAnswers = {};
  bool _isSubmitting = false;

  Future<void> _submitQuiz(List<QuestionModel> questions) async {
    if (_selectedAnswers.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submitting.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Grading Logic
      int correctAnswers = 0;
      for (var question in questions) {
        if (_selectedAnswers[question.id] == question.correctAnswerIndex) {
          correctAnswers++;
        }
      }

      double rawScore =
          (correctAnswers / questions.length) * widget.task.maxScore;
      String finalGrade = rawScore.round().toString();

      // 2. Get Current Student Info
      final user = ref
          .read(currentUserProvider)
          .value; // Updated to match your auth provider
      if (user == null) throw Exception("User not logged in");

      // 3. THE FIX: Create Submission Model with all required fields
      final submission = SubmissionModel(
        id: '',
        taskId: widget.task.id,
        studentId: user.uid,
        studentEmail: user.email ?? 'No Email',
        submittedAt: DateTime.now(),
        grade: finalGrade,
        instructorId: widget.task.instructorId, // THE MASTER KEY
        fileUrl: null, // Quizzes don't usually have file uploads
      );

      // 4. Save to Firestore
      await ref.read(submissionRepositoryProvider).createSubmission(submission);

      if (mounted) {
        _showResultsDialog(correctAnswers, questions.length, finalGrade);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showResultsDialog(int correct, int total, String finalGrade) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Quiz Submitted!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You got $correct out of $total correct.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Final Score: $finalGrade / ${widget.task.maxScore}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002147),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002147),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Return to Dashboard',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsByTaskProvider(widget.task.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Text('No questions available for this quiz.'),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.task.description,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${question.questionText}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...List.generate(question.choices.length, (
                              choiceIndex,
                            ) {
                              return RadioListTile<int>(
                                title: Text(question.choices[choiceIndex]),
                                value: choiceIndex,
                                groupValue: _selectedAnswers[question.id],
                                activeColor: const Color(0xFF002147),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(
                                      () =>
                                          _selectedAnswers[question.id] = value,
                                    );
                                  }
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002147),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitQuiz(questions),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Answers',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
