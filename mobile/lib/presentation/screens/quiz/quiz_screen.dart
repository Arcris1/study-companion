import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/animations.dart';
import '../../../domain/enums/question_type.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/quiz/mcq_question_widget.dart';
import '../../widgets/quiz/true_false_question_widget.dart';
import '../../widgets/quiz/fill_blank_question_widget.dart';
import '../../widgets/quiz/quiz_progress_bar.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/sc_button.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final int quizId;

  const QuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  final Map<int, TextEditingController> _fillControllers = {};
  bool _isSubmitting = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _fillControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppAnimations.durationMedium,
      curve: AppAnimations.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final questionsAsync = ref.watch(quizQuestionsProvider(widget.quizId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz', style: theme.textTheme.titleLarge),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => _submitQuiz(context),
            child: Text(
              'Submit',
              style: TextStyle(
                color: _isSubmitting
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('No questions found'));
          }

          final totalQuestions = questions.length;
          final allAnswered = _answers.length >= totalQuestions;
          final isLast = _currentIndex >= totalQuestions - 1;

          // Build answered-question booleans for the dots
          final answeredList = List.generate(
            totalQuestions,
            (i) => _answers.containsKey(i),
          );

          return Column(
            children: [
              // ── Progress section ─────────────────────────────────
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

              // ── Question PageView ────────────────────────────────
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
                          _buildQuestion(question),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Bottom navigation ────────────────────────────────
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
                      // Previous button
                      if (_currentIndex > 0)
                        Expanded(
                          flex: 4,
                          child: ScButton(
                            label: 'Previous',
                            icon: Icons.chevron_left_rounded,
                            variant: ScButtonVariant.outlined,
                            onPressed: () => _goToPage(_currentIndex - 1),
                          ),
                        ),
                      if (_currentIndex > 0)
                        const SizedBox(width: Spacing.space12),

                      // Mini question dots (center area)
                      if (totalQuestions <= 15)
                        Flexible(
                          flex: 3,
                          child: _QuestionDots(
                            total: totalQuestions,
                            current: _currentIndex,
                            answered: answeredList,
                            onTap: _goToPage,
                          ),
                        ),

                      if (_currentIndex > 0 || totalQuestions <= 15)
                        const SizedBox(width: Spacing.space12),

                      // Next / Submit button
                      Expanded(
                        flex: 4,
                        child: isLast
                            ? _SubmitButton(
                                isLoading: _isSubmitting,
                                allAnswered: allAnswered,
                                onPressed: () => _submitQuiz(context),
                              )
                            : ScButton(
                                label: 'Next',
                                icon: Icons.chevron_right_rounded,
                                onPressed: () =>
                                    _goToPage(_currentIndex + 1),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildQuestion(dynamic question) {
    switch (question.type) {
      case QuestionType.trueFalse:
        return TrueFalseQuestionWidget(
          question: question,
          selectedAnswer: _answers[question.questionIndex],
          onSelect: (v) =>
              setState(() => _answers[question.questionIndex] = v),
        );
      case QuestionType.fillBlank:
        _fillControllers.putIfAbsent(
          question.questionIndex,
          () => TextEditingController(
              text: _answers[question.questionIndex]),
        );
        final controller = _fillControllers[question.questionIndex]!;
        controller.addListener(() {
          _answers[question.questionIndex] = controller.text;
        });
        return FillBlankQuestionWidget(
          question: question,
          controller: controller,
        );
      default:
        return McqQuestionWidget(
          question: question,
          selectedAnswer: _answers[question.questionIndex],
          onSelect: (v) =>
              setState(() => _answers[question.questionIndex] = v),
        );
    }
  }

  Future<void> _submitQuiz(BuildContext context) async {
    setState(() => _isSubmitting = true);
    try {
      final attempt = await ref.read(quizRepositoryProvider).submitAttempt(
        quizId: widget.quizId,
        answers: _answers,
      );
      if (context.mounted) {
        context.pop();
        context.push('/quiz/${widget.quizId}/results/${attempt.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ─── Mini Question Dots ──────────────────────────────────────────────────────

class _QuestionDots extends StatelessWidget {
  final int total;
  final int current;
  final List<bool> answered;
  final ValueChanged<int> onTap;

  const _QuestionDots({
    required this.total,
    required this.current,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (index) {
          final isCurrent = index == current;
          final isAnswered = index < answered.length && answered[index];

          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: AppAnimations.durationFast,
              curve: AppAnimations.easeOut,
              width: isCurrent ? 8 : 6,
              height: isCurrent ? 8 : 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? Colors.transparent
                    : isAnswered
                        ? AppColors.primary
                        : AppColors.quizUnanswered.withValues(alpha: 0.4),
                border: isCurrent
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Submit Button with Pulse Animation ──────────────────────────────────────

class _SubmitButton extends StatefulWidget {
  final bool isLoading;
  final bool allAnswered;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isLoading,
    required this.allAnswered,
    required this.onPressed,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.allAnswered) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_SubmitButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allAnswered && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.allAnswered && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.allAnswered ? _pulseAnimation.value : 1.0,
          child: ScButton(
            label: 'Submit',
            icon: Icons.check_rounded,
            isLoading: widget.isLoading,
            variant: ScButtonVariant.gradient,
            onPressed: widget.onPressed,
          ),
        );
      },
    );
  }
}
