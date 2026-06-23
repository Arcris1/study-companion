import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/animations.dart';
import '../../../domain/enums/question_type.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/quiz/mcq_question_widget.dart';
import '../../widgets/quiz/true_false_question_widget.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/sc_button.dart';

class QuizResultsScreen extends ConsumerStatefulWidget {
  final int quizId;
  final int attemptId;

  const QuizResultsScreen({
    super.key,
    required this.quizId,
    required this.attemptId,
  });

  @override
  ConsumerState<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends ConsumerState<QuizResultsScreen> {
  bool _confettiFired = false;
  bool _showConfetti = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final questionsAsync = ref.watch(quizQuestionsProvider(widget.quizId));
    final attemptsAsync = ref.watch(quizAttemptsProvider(widget.quizId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Results', style: theme.textTheme.titleLarge),
      ),
      body: Stack(
        children: [
          questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (questions) {
          return attemptsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateWidget(message: e.toString()),
            data: (attempts) {
              final attempt = attempts
                  .where((a) => a.id == widget.attemptId)
                  .firstOrNull;
              if (attempt == null) {
                return const Center(child: Text('Attempt not found'));
              }

              // Fire confetti for good scores (once)
              if (!_confettiFired && attempt.percentage >= 80) {
                _confettiFired = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _showConfetti = true);
                });
              }

              final gradeColor = AppColors.gradeColor(attempt.percentage);
              final totalQuestions = attempt.totalQuestions;
              final correctCount = attempt.score;
              final incorrectCount = totalQuestions - correctCount;
              // Count skipped (questions not answered)
              final answeredCount = attempt.answers.length;
              final skippedCount = totalQuestions - answeredCount;
              final wrongCount = incorrectCount - skippedCount;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.screenPaddingH,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: Spacing.xl),

                    // ── Animated Score Gauge ─────────────────────────
                    _AnimatedScoreGauge(
                      percentage: attempt.percentage,
                      grade: attempt.grade,
                      gradeColor: gradeColor,
                      isDark: isDark,
                    ),

                    const SizedBox(height: Spacing.md),
                    Text(
                      '${attempt.score} / ${attempt.totalQuestions} correct',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: Spacing.lg),

                    // ── Grade Breakdown Card ─────────────────────────
                    Container(
                      padding: const EdgeInsets.all(Spacing.cardPadding),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: Spacing.borderRadiusMd,
                        boxShadow:
                            isDark ? AppShadows.level1Dark : AppShadows.level1,
                      ),
                      child: Row(
                        children: [
                          _StatCell(
                            icon: Icons.check_circle_rounded,
                            iconColor: AppColors.success,
                            value: '$correctCount',
                            label: 'Correct',
                            theme: theme,
                          ),
                          _StatCell(
                            icon: Icons.cancel_rounded,
                            iconColor: AppColors.error,
                            value: '$wrongCount',
                            label: 'Wrong',
                            theme: theme,
                          ),
                          _StatCell(
                            icon: Icons.remove_circle_outline_rounded,
                            iconColor: AppColors.quizUnanswered,
                            value: '$skippedCount',
                            label: 'Skipped',
                            theme: theme,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: Spacing.lg),

                    // ── Review Section ───────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Review Answers',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),

                    ...questions.asMap().entries.map((entry) {
                      final q = entry.value;
                      final userAnswer =
                          attempt.answers[q.questionIndex];
                      final isCorrect =
                          userAnswer == q.correctAnswer;
                      final isSkipped = userAnswer == null;

                      Color leftBorderColor;
                      if (isSkipped) {
                        leftBorderColor = AppColors.quizUnanswered;
                      } else if (isCorrect) {
                        leftBorderColor = AppColors.success;
                      } else {
                        leftBorderColor = AppColors.error;
                      }

                      return _ReviewQuestionCard(
                        questionIndex: q.questionIndex,
                        question: q,
                        userAnswer: userAnswer,
                        leftBorderColor: leftBorderColor,
                        isCorrect: isCorrect,
                        isSkipped: isSkipped,
                        isDark: isDark,
                        theme: theme,
                      );
                    }),

                    const SizedBox(height: Spacing.lg),

                    // ── Actions ──────────────────────────────────────
                    ScButton(
                      label: 'View all attempts',
                      icon: Icons.history_rounded,
                      variant: ScButtonVariant.gradient,
                      onPressed: () =>
                          context.push('/quiz/${widget.quizId}/history'),
                    ),
                    const SizedBox(height: Spacing.sm),
                    ScButton(
                      label: 'Done',
                      variant: ScButtonVariant.outlined,
                      onPressed: () => context.pop(),
                    ),

                    SizedBox(height: MediaQuery.of(context).padding.bottom + Spacing.lg),
                  ],
                ),
              );
            },
          );
        },
      ),
          if (_showConfetti) _ConfettiOverlay(key: const ValueKey('confetti')),
        ],
      ),
    );
  }
}

// ─── Animated Score Gauge ────────────────────────────────────────────────────

class _AnimatedScoreGauge extends StatefulWidget {
  final double percentage;
  final String grade;
  final Color gradeColor;
  final bool isDark;

  const _AnimatedScoreGauge({
    required this.percentage,
    required this.grade,
    required this.gradeColor,
    required this.isDark,
  });

  @override
  State<_AnimatedScoreGauge> createState() => _AnimatedScoreGaugeState();
}

class _AnimatedScoreGaugeState extends State<_AnimatedScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.durationEmphasis,
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage / 100)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _ScoreGaugePainter(
              progress: _animation.value,
              trackColor: widget.isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLight,
              progressColor: widget.gradeColor,
              strokeWidth: 12,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.grade,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.gradeColor,
                    ),
                  ),
                  Text(
                    '${(_animation.value * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreGaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ScoreGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreGaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}

// ─── Stat Cell ───────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final ThemeData theme;

  const _StatCell({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: Spacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Review Question Card (Expandable) ───────────────────────────────────────

class _ReviewQuestionCard extends StatefulWidget {
  final int questionIndex;
  final dynamic question;
  final String? userAnswer;
  final Color leftBorderColor;
  final bool isCorrect;
  final bool isSkipped;
  final bool isDark;
  final ThemeData theme;

  const _ReviewQuestionCard({
    required this.questionIndex,
    required this.question,
    required this.userAnswer,
    required this.leftBorderColor,
    required this.isCorrect,
    required this.isSkipped,
    required this.isDark,
    required this.theme,
  });

  @override
  State<_ReviewQuestionCard> createState() => _ReviewQuestionCardState();
}

class _ReviewQuestionCardState extends State<_ReviewQuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final q = widget.question;

    // Badge color
    Color badgeColor;
    if (widget.isSkipped) {
      badgeColor = AppColors.quizUnanswered;
    } else if (widget.isCorrect) {
      badgeColor = AppColors.success;
    } else {
      badgeColor = AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: AppAnimations.durationMedium,
          curve: AppAnimations.easeOut,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: Spacing.borderRadiusMd,
            border: Border(
              left: BorderSide(
                color: widget.leftBorderColor,
                width: 3,
              ),
            ),
            boxShadow: widget.isDark
                ? AppShadows.level1Dark
                : AppShadows.level1,
          ),
          child: Column(
            children: [
              // Collapsed header
              Padding(
                padding: const EdgeInsets.all(Spacing.cardPadding),
                child: Row(
                  children: [
                    // Question number badge
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: badgeColor,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.questionIndex + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.space12),
                    // Question text preview
                    Expanded(
                      child: Text(
                        q.question,
                        maxLines: _expanded ? 10 : 1,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppAnimations.durationFast,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded content
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.cardPadding,
                    0,
                    Spacing.cardPadding,
                    Spacing.cardPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: Spacing.space12),
                      if (q.type == QuestionType.trueFalse)
                        TrueFalseQuestionWidget(
                          question: q,
                          selectedAnswer: widget.userAnswer,
                          correctAnswer: q.correctAnswer,
                          onSelect: (_) {},
                        )
                      else
                        McqQuestionWidget(
                          question: q,
                          selectedAnswer: widget.userAnswer,
                          correctAnswer: q.correctAnswer,
                          onSelect: (_) {},
                        ),
                    ],
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: AppAnimations.durationMedium,
                sizeCurve: AppAnimations.easeOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({super.key});

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  static const _colors = [
    Color(0xFF7C3AED),
    Color(0xFF4F46E5),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(_ConfettiParticle(
        x: rng.nextDouble(),
        speed: 0.3 + rng.nextDouble() * 0.7,
        drift: (rng.nextDouble() - 0.5) * 0.3,
        size: 4 + rng.nextDouble() * 6,
        color: _colors[rng.nextInt(_colors.length)],
        delay: rng.nextDouble() * 0.3,
      ));
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _controller.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double speed;
  final double drift;
  final double size;
  final Color color;
  final double delay;

  const _ConfettiParticle({
    required this.x,
    required this.speed,
    required this.drift,
    required this.size,
    required this.color,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final opacity = t < 0.8 ? 1.0 : (1.0 - (t - 0.8) / 0.2);
      final x = p.x * size.width + p.drift * size.width * t;
      final y = t * size.height * p.speed;
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: p.size, height: p.size * 0.6),
          Radius.circular(p.size * 0.15),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
