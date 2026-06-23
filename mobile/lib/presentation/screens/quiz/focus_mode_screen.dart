import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/animations.dart';
import '../../../core/llm/llm_service.dart';
import '../../../core/llm/prompt_templates.dart';
import '../../../domain/entities/quiz_question.dart';
import '../../../domain/enums/question_type.dart';
import '../../providers/note_provider.dart';
import '../../widgets/quiz/mcq_question_widget.dart';
import '../../widgets/quiz/quiz_progress_bar.dart';
import '../../widgets/common/sc_button.dart';

class FocusModeScreen extends ConsumerStatefulWidget {
  final int notebookId;
  final String topic;

  const FocusModeScreen({
    super.key,
    required this.notebookId,
    required this.topic,
  });

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen> {
  List<QuizQuestion>? _questions;
  bool _isGenerating = true;
  String? _error;
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  bool _isSubmitted = false;
  int _score = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _generateFocusQuiz();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _generateFocusQuiz() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final noteDatasource = ref.read(noteDatasourceProvider);
      final notes = noteDatasource.getByNotebookId(widget.notebookId);

      if (notes.isEmpty) {
        setState(() {
          _error = 'No notes found in this notebook';
          _isGenerating = false;
        });
        return;
      }

      // Gather content
      final allChunks = <String>[];
      for (final note in notes) {
        final chunks = noteDatasource.getChunks(note.id);
        allChunks.addAll(chunks.map((c) => c.text));
      }
      final content = allChunks.take(15).join('\n\n');

      final prompt = PromptTemplates.generateFocusQuiz(
        content: content,
        numQuestions: 5,
        topic: widget.topic,
        difficulty: 'medium',
      );

      final llm = ref.read(llmServiceProvider);
      final response = await llm.generate(prompt, maxTokens: 3000);

      // Parse the response robustly — the model may return a full
      // {"questions":[...]} object (OpenAI JSON mode), a bare array, fenced
      // JSON, or a continuation of the prompt's opening.
      List questionList;
      try {
        questionList =
            (jsonDecode(response) as Map<String, dynamic>)['questions'] as List;
      } catch (_) {
        try {
          questionList = jsonDecode(response) as List;
        } catch (_) {
          try {
            questionList = (jsonDecode('{"questions": [$response')
                as Map<String, dynamic>)['questions'] as List;
          } catch (_) {
            final m = RegExp(r'\[[\s\S]*\]').firstMatch(response);
            if (m == null) {
              throw const FormatException('No valid JSON found in response');
            }
            questionList = jsonDecode(m.group(0)!) as List;
          }
        }
      }

      final questions = <QuizQuestion>[];
      for (final raw in questionList) {
        if (raw is! Map) continue;
        final text = raw['question']?.toString().trim() ?? '';
        final opts =
            (raw['options'] as List?)?.map((e) => e.toString()).toList() ??
                const <String>[];
        final correct = raw['correct_answer']?.toString() ?? '';
        if (text.isEmpty || opts.length < 2 || correct.isEmpty) continue;
        questions.add(QuizQuestion(
          id: 0,
          quizId: 0,
          question: text,
          type: QuestionType.mcq,
          options: opts,
          correctAnswer: correct,
          explanation: raw['explanation']?.toString(),
          questionIndex: questions.length,
          topic: widget.topic,
        ));
      }
      if (questions.isEmpty) {
        throw const FormatException('No valid questions were generated');
      }

      setState(() {
        _questions = questions;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate focus quiz: $e';
        _isGenerating = false;
      });
    }
  }

  void _goToPage(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppAnimations.durationMedium,
      curve: AppAnimations.easeInOut,
    );
  }

  void _submitQuiz() {
    if (_questions == null) return;

    int score = 0;
    for (final q in _questions!) {
      final answer = _answers[q.questionIndex];
      if (answer != null &&
          answer.trim().toLowerCase() ==
              q.correctAnswer.trim().toLowerCase()) {
        score++;
      }
    }

    setState(() {
      _isSubmitted = true;
      _score = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Focus: ${widget.topic}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isGenerating
          ? _buildLoadingState(theme, isDark)
          : _error != null
              ? _buildErrorState(theme, isDark)
              : _isSubmitted
                  ? _buildResults(theme, isDark)
                  : _buildQuiz(theme, isDark),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: Spacing.borderRadiusLg,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Generating Focus Quiz...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Creating questions about "${widget.topic}"',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.onSurfaceVariantDark
                  : AppColors.onSurfaceVariantLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.screenPaddingH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: Spacing.md),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.lg),
            ScButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              variant: ScButtonVariant.gradient,
              expanded: false,
              onPressed: _generateFocusQuiz,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz(ThemeData theme, bool isDark) {
    final questions = _questions!;
    final totalQuestions = questions.length;
    final allAnswered = _answers.length >= totalQuestions;
    final isLast = _currentIndex >= totalQuestions - 1;
    final answeredList = List.generate(
      totalQuestions,
      (i) => _answers.containsKey(i),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.screenPaddingH,
            vertical: Spacing.space12,
          ),
          child: QuizProgressBar(
            current: _currentIndex,
            total: totalQuestions,
            answered: _answers.length,
            answeredQuestions: answeredList,
            onDotTap: (index) => _goToPage(index),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalQuestions,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final question = questions[index];
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.screenPaddingH,
                  vertical: Spacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    McqQuestionWidget(
                      question: question,
                      selectedAnswer: _answers[question.questionIndex],
                      onSelect: (v) => setState(
                          () => _answers[question.questionIndex] = v),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(Spacing.screenPaddingH),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.outlineVariantDark
                    : AppColors.outlineVariantLight,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: ScButton(
                      label: 'Previous',
                      icon: Icons.chevron_left_rounded,
                      variant: ScButtonVariant.outlined,
                      onPressed: () => _goToPage(_currentIndex - 1),
                    ),
                  ),
                if (_currentIndex > 0)
                  const SizedBox(width: Spacing.space12),
                Expanded(
                  child: isLast
                      ? ScButton(
                          label: 'Submit',
                          icon: Icons.check_rounded,
                          variant: ScButtonVariant.gradient,
                          onPressed: allAnswered ? _submitQuiz : null,
                        )
                      : ScButton(
                          label: 'Next',
                          icon: Icons.chevron_right_rounded,
                          onPressed: () => _goToPage(_currentIndex + 1),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(ThemeData theme, bool isDark) {
    final questions = _questions!;
    final pct = questions.isEmpty ? 0.0 : _score / questions.length * 100;
    return ListView(
      padding: const EdgeInsets.all(Spacing.screenPaddingH),
      children: [
        // Score card
        Container(
          padding: const EdgeInsets.all(Spacing.cardPaddingLarge),
          decoration: BoxDecoration(
            gradient: pct >= 80 ? AppGradients.success : AppGradients.primary,
            borderRadius: Spacing.borderRadiusLg,
            boxShadow: isDark ? AppShadows.level2Dark : AppShadows.level2,
          ),
          child: Column(
            children: [
              Text(
                'Focus Quiz Results',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                '${pct.round()}%',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$_score / ${questions.length} correct',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Topic: ${widget.topic}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sectionGap),

        // Question review
        Text(
          'Review',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.md),

        ...questions.map((q) {
          final userAnswer = _answers[q.questionIndex];
          final isCorrect = userAnswer != null &&
              userAnswer.trim().toLowerCase() ==
                  q.correctAnswer.trim().toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Container(
              padding: const EdgeInsets.all(Spacing.cardPadding),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                borderRadius: Spacing.borderRadiusMd,
                border: Border.all(
                  color: isCorrect
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow:
                    isDark ? AppShadows.level1Dark : AppShadows.level1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: isCorrect
                            ? AppColors.success
                            : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          q.question,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isCorrect) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'Your answer: ${userAnswer ?? "Not answered"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      'Correct answer: ${q.correctAnswer}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                  if (q.explanation != null) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      q.explanation!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.onSurfaceVariantDark
                            : AppColors.onSurfaceVariantLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: Spacing.lg),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ScButton(
                label: 'Try Again',
                icon: Icons.refresh_rounded,
                variant: ScButtonVariant.outlined,
                onPressed: () {
                  setState(() {
                    _isSubmitted = false;
                    _answers.clear();
                    _currentIndex = 0;
                    _score = 0;
                    _pageController = PageController();
                  });
                  _generateFocusQuiz();
                },
              ),
            ),
            const SizedBox(width: Spacing.space12),
            Expanded(
              child: ScButton(
                label: 'Done',
                icon: Icons.check_rounded,
                variant: ScButtonVariant.gradient,
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
      ],
    );
  }
}
