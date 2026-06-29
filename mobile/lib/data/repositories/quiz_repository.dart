import 'dart:convert';
import '../../core/ai/ai_config.dart';
import '../../core/text/content_sampler.dart';
import '../../core/llm/llm_service.dart';
import '../../core/llm/prompt_templates.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/quiz_attempt.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/quiz_style.dart';
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
    QuizStyle style = QuizStyle.mixed,
    List<int>? noteIds,
  }) async {
    // Gather note content from the notebook — optionally limited to a chosen
    // subset of notes (empty/null = all notes = "General").
    var notes = _noteDatasource.getByNotebookId(notebookId);
    if (noteIds != null && noteIds.isNotEmpty) {
      final idSet = noteIds.toSet();
      notes = notes.where((n) => idSet.contains(n.id)).toList();
    }
    if (notes.isEmpty) throw Exception('No notes found in notebook');

    // Collect chunks from all notes
    final allChunks = <String>[];
    for (final note in notes) {
      final chunks = _noteDatasource.getChunks(note.id);
      allChunks.addAll(chunks.map((c) => c.text));
    }

    // Sample across the whole document so questions aren't all from page 1.
    final selectedContent = sampleAcross(allChunks, 12000);
    if (selectedContent.trim().isEmpty) {
      throw Exception(
          'No readable text in these notes (a scanned PDF has no extractable text).');
    }

    final actualCount = questionCount.clamp(1, 30);

    final prompt = PromptTemplates.generateQuiz(
      content: selectedContent,
      numQuestions: actualCount,
      questionType: questionType.name,
      difficulty: difficulty.name,
      styleInstruction: style.promptInstruction,
    );

    // Scale tokens with the question count so large (and situational) quizzes
    // aren't truncated — this is why "20 requested" used to return only ~18.
    final base = AiConfig.instance.tokenLimit(AiOp.quiz);
    final scaled = actualCount * 400 + 800;
    // Floor at the configured limit, but always cap at the model's safe ceiling.
    final maxTokens = (scaled > base ? scaled : base).clamp(800, 12000);

    final response = await _llmService.generate(
      prompt,
      maxTokens: maxTokens,
    );

    // Parse JSON response — try multiple strategies
    List<QuizQuestionModel> questionModels;
    try {
      List questions;
      final r = response.trim();
      try {
        // Strategy 1: Response continues from prompt's {"questions": [
        questions =
            (jsonDecode('{"questions": [$r') as Map)['questions'] as List;
      } catch (_) {
        try {
          // Strategy 2: Response is complete JSON with {"questions": [...]}
          questions = (jsonDecode(r) as Map)['questions'] as List;
        } catch (_) {
          try {
            // Strategy 3: Response is just a JSON array [...]
            questions = jsonDecode(r) as List;
          } catch (_) {
            // Strategy 4: Salvage a truncated array by closing it at the last
            // complete object, so we keep every question that was generated.
            final lastBrace = r.lastIndexOf('}');
            if (lastBrace != -1) {
              questions = (jsonDecode(
                      '{"questions": [${r.substring(0, lastBrace + 1)}]}')
                  as Map)['questions'] as List;
            } else {
              final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(r);
              if (jsonMatch != null) {
                questions = jsonDecode(jsonMatch.group(0)!) as List;
              } else {
                throw const FormatException('No valid JSON found');
              }
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

      // Map defensively: skip malformed entries so one bad question doesn't
      // throw away the whole quiz (the model occasionally omits a field).
      questionModels = <QuizQuestionModel>[];
      for (final raw in questions) {
        if (raw is! Map) continue;
        final text = raw['question'];
        final answer = raw['correct_answer'];
        if (text is! String || text.trim().isEmpty || answer == null) continue;
        questionModels.add(QuizQuestionModel(
          quizId: quizModel.id,
          question: text,
          typeStr: questionType.name,
          optionsJson: jsonEncode(raw['options'] ?? []),
          correctAnswer: answer.toString(),
          explanation: raw['explanation']?.toString(),
          questionIndex: questionModels.length,
          topic: raw['topic']?.toString(),
        ));
      }

      if (questionModels.isEmpty) {
        questionModels.add(QuizQuestionModel(
          quizId: quizModel.id,
          question:
              'Quiz generation failed. Please try again with different settings.',
          typeStr: QuestionType.mcq.name,
          optionsJson: jsonEncode([
            'Try again',
            'Adjust settings',
            'Use different notes',
            'All of the above'
          ]),
          correctAnswer: 'All of the above',
          explanation: 'The AI response could not be parsed into questions.',
          questionIndex: 0,
        ));
      }

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
