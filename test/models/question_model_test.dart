import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/models/question_model.dart';

void main() {
  group('QuestionModel', () {
    test('serializes choices and correct answer index', () {
      final question = QuestionModel(
        id: 'question-1',
        taskId: 'task-1',
        questionText: 'What is the correct stance?',
        choices: const ['Front', 'Side', 'Wide'],
        correctAnswerIndex: 2,
      );

      final map = question.toMap();

      expect(map['taskId'], 'task-1');
      expect(map['questionText'], 'What is the correct stance?');
      expect(map['choices'], ['Front', 'Side', 'Wide']);
      expect(map['correctAnswerIndex'], 2);
    });
  });
}
