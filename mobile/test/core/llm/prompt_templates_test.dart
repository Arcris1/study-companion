import 'package:flutter_test/flutter_test.dart';
import 'package:study_companion/core/llm/prompt_templates.dart';

void main() {
  group('PromptTemplates', () {
    group('summarize()', () {
      test('wraps text with begin_of_turn and end_of_turn tags', () {
        final result = PromptTemplates.summarize('Some study material');

        expect(result, contains('<|begin_of_turn|>system'));
        expect(result, contains('<|end_of_turn|>'));
        expect(result, contains('<|begin_of_turn|>user'));
        expect(result, contains('<|begin_of_turn|>assistant'));
      });

      test('includes the provided text in the prompt', () {
        const text = 'Photosynthesis is the process by which plants convert sunlight.';
        final result = PromptTemplates.summarize(text);

        expect(result, contains(text));
      });

      test('ends with assistant turn marker for generation', () {
        final result = PromptTemplates.summarize('test');
        final trimmed = result.trimRight();

        expect(trimmed, endsWith('<|begin_of_turn|>assistant'));
      });
    });

    group('generateQuiz()', () {
      test('includes numQuestions in the prompt', () {
        final result = PromptTemplates.generateQuiz(
          content: 'Biology notes',
          numQuestions: 5,
          questionType: 'multiple_choice',
          difficulty: 'medium',
        );

        expect(result, contains('5'));
      });

      test('includes questionType in the prompt', () {
        final result = PromptTemplates.generateQuiz(
          content: 'Biology notes',
          numQuestions: 3,
          questionType: 'true_false',
          difficulty: 'easy',
        );

        expect(result, contains('true_false'));
      });

      test('includes difficulty in the prompt', () {
        final result = PromptTemplates.generateQuiz(
          content: 'Biology notes',
          numQuestions: 3,
          questionType: 'multiple_choice',
          difficulty: 'hard',
        );

        expect(result, contains('hard'));
      });

      test('includes the content material', () {
        const content = 'The mitochondria is the powerhouse of the cell.';
        final result = PromptTemplates.generateQuiz(
          content: content,
          numQuestions: 2,
          questionType: 'multiple_choice',
          difficulty: 'easy',
        );

        expect(result, contains(content));
      });

      test('contains JSON format instructions', () {
        final result = PromptTemplates.generateQuiz(
          content: 'test',
          numQuestions: 1,
          questionType: 'multiple_choice',
          difficulty: 'easy',
        );

        expect(result, contains('"questions"'));
      });
    });

    group('answerQuestion()', () {
      test('includes both context and question', () {
        const context = 'Water boils at 100 degrees Celsius.';
        const question = 'At what temperature does water boil?';
        final result = PromptTemplates.answerQuestion(context, question);

        expect(result, contains(context));
        expect(result, contains(question));
      });

      test('wraps with turn tags', () {
        final result = PromptTemplates.answerQuestion('ctx', 'q');

        expect(result, contains('<|begin_of_turn|>system'));
        expect(result, contains('<|begin_of_turn|>user'));
        expect(result, contains('<|begin_of_turn|>assistant'));
      });

      test('places context before question', () {
        const ctx = 'CONTEXT_MARKER';
        const q = 'QUESTION_MARKER';
        final result = PromptTemplates.answerQuestion(ctx, q);

        expect(result.indexOf(ctx), lessThan(result.indexOf(q)));
      });
    });

    group('explainConcept()', () {
      test('includes the concept in the prompt', () {
        const concept = 'quantum entanglement';
        final result = PromptTemplates.explainConcept(concept, 'some context');

        expect(result, contains(concept));
      });

      test('includes the context in the prompt', () {
        const context = 'Physics chapter 12 covers quantum mechanics.';
        final result = PromptTemplates.explainConcept('entanglement', context);

        expect(result, contains(context));
      });

      test('wraps with turn tags', () {
        final result = PromptTemplates.explainConcept('test', 'ctx');

        expect(result, contains('<|begin_of_turn|>system'));
        expect(result, contains('<|begin_of_turn|>user'));
        expect(result, contains('<|begin_of_turn|>assistant'));
      });
    });
  });
}
