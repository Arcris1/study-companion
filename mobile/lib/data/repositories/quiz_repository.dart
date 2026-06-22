import 'dart:convert';
import '../../core/llm/llm_service.dart';
import '../../core/llm/prompt_templates.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/quiz_attempt.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/question_type.dart';
import '../../domain/repositories/i_quiz_repository.dart';
import '../datasources/local/quiz_local_datasource.dart';
import '../datasources/local/note_local_datasource.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import '../models/quiz_attempt_model.dart';

class QuizRepository implements IQuizRepository {
  final QuizLocalDatasource _quizDatasource;
  final NoteLocalDatasource _noteDatasource;
  final LlmService _llmService;

  QuizRepository(this._quizDatasource, this._noteDatasource, this._llmService);

  @override
  Future<List<Quiz>> getByNotebookId(int notebookId) async {
    return _quizDatasource.getByNotebookId(notebookId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<Quiz> generateQuiz({
    required int notebookId,
    required String title,
    required QuestionType questionType,
    required DifficultyLevel difficulty,
    required int questionCount,
  }) async {
    // Gather note content from notebook
    final notes = _noteDatasource.getByNotebookId(notebookId);
    if (notes.isEmpty) throw Exception('No notes found in notebook');

    // Collect chunks from all notes
    final allChunks = <String>[];
    for (final note in notes) {
      final chunks = _noteDatasource.getChunks(note.id);
      allChunks.addAll(chunks.map((c) => c.text));
    }

    // Gather a generous slice of content (OpenAI has a large context window).
    final buffer = StringBuffer();
    for (final chunk in allChunks) {
      if (buffer.length + chunk.length > 12000) break;
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(chunk);
    }
    final selectedContent = buffer.toString();

    final actualCount = questionCount.clamp(1, 30);

    final prompt = PromptTemplates.generateQuiz(
      content: selectedContent,
      numQuestions: actualCount,
      questionType: questionType.name,
      difficulty: difficulty.name,
    );

    final response = await _llmService.generate(prompt, maxTokens: 3000);

    // Parse JSON response — try multiple strategies
    List<QuizQuestionModel> questionModels;
    try {
      List questions;
      try {
        // Strategy 1: Response continues from prompt's {"questions": [
        final jsonStr = '{"questions": [$response';
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        questions = parsed['questions'] as List;
      } catch (_) {
        try {
          // Strategy 2: Response is complete JSON with {"questions": [...]}
          final parsed = jsonDecode(response) as Map<String, dynamic>;
          questions = parsed['questions'] as List;
        } catch (_) {
          try {
            // Strategy 3: Response is just a JSON array [...]
            questions = jsonDecode(response) as List;
          } catch (_) {
            // Strategy 4: Extract JSON from response text
            final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
            if (jsonMatch != null) {
              questions = jsonDecode(jsonMatch.group(0)!) as List;
            } else {
              throw const FormatException('No valid JSON found');
            }
          }
        }
      }

      // Create quiz first
      final quizModel = _quizDatasource.createQuiz(QuizModel(
        notebookId: notebookId,
        title: title,
        questionTypeStr: questionType.name,
        difficultyStr: difficulty.name,
        questionCount: questionCount,
        createdAt: DateTime.now(),
      ));

      questionModels = questions.asMap().entries.map((entry) {
        final q = entry.value as Map<String, dynamic>;
        return QuizQuestionModel(
          quizId: quizModel.id,
          question: q['question'] as String,
          typeStr: questionType.name,
          optionsJson: jsonEncode(q['options'] ?? []),
          correctAnswer: q['correct_answer'] as String,
          explanation: q['explanation'] as String?,
          questionIndex: entry.key,
          topic: q['topic'] as String?,
        );
      }).toList();

      _quizDatasource.saveQuestions(questionModels);
      return quizModel.toEntity();
    } catch (e) {
      // If parsing fails, create a simple fallback quiz
      final quizModel = _quizDatasource.createQuiz(QuizModel(
        notebookId: notebookId,
        title: title,
        questionTypeStr: questionType.name,
        difficultyStr: difficulty.name,
        questionCount: 1,
        createdAt: DateTime.now(),
      ));

      _quizDatasource.saveQuestions([
        QuizQuestionModel(
          quizId: quizModel.id,
          question: 'Quiz generation failed. Please try again with different settings.',
          typeStr: QuestionType.mcq.name,
          optionsJson: jsonEncode(['Try again', 'Adjust settings', 'Use different notes', 'All of the above']),
          correctAnswer: 'All of the above',
          explanation: 'The LLM response could not be parsed into quiz questions.',
          questionIndex: 0,
        ),
      ]);

      return quizModel.toEntity();
    }
  }

  @override
  Future<List<QuizQuestion>> getQuestions(int quizId) async {
    return _quizDatasource.getQuestions(quizId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<QuizAttempt> submitAttempt({
    required int quizId,
    required Map<int, String> answers,
  }) async {
    final questions = _quizDatasource.getQuestions(quizId);
    int score = 0;

    for (final question in questions) {
      final userAnswer = answers[question.questionIndex];
      if (userAnswer != null &&
          userAnswer.trim().toLowerCase() == question.correctAnswer.trim().toLowerCase()) {
        score++;
      }
    }

    final attemptModel = QuizAttemptModel(
      quizId: quizId,
      score: score,
      totalQuestions: questions.length,
      completedAt: DateTime.now(),
    );
    attemptModel.answers = answers;

    final saved = _quizDatasource.saveAttempt(attemptModel);
    return saved.toEntity();
  }

  @override
  Future<List<QuizAttempt>> getAttempts(int quizId) async {
    return _quizDatasource.getAttempts(quizId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<void> deleteQuiz(int id) async {
    _quizDatasource.deleteQuiz(id);
  }
}
