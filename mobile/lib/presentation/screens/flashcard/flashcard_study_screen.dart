import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/animations.dart';
import '../../../domain/entities/flashcard.dart';
import '../../providers/flashcard_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/sc_button.dart';
import '../../widgets/flashcard/flip_card_widget.dart';

class FlashcardStudyScreen extends ConsumerStatefulWidget {
  final int deckId;

  const FlashcardStudyScreen({super.key, required this.deckId});

  @override
  ConsumerState<FlashcardStudyScreen> createState() =>
      _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends ConsumerState<FlashcardStudyScreen> {
  List<Flashcard> _dueCards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isReviewing = false;
  bool _isComplete = false;
  bool _isLoaded = false;
  final FlipCardController _flipController = FlipCardController();

  @override
  void initState() {
    super.initState();
    _loadDueCards();
  }

  Future<void> _loadDueCards() async {
    try {
      final cards = await ref
          .read(flashcardRepositoryProvider)
          .getDueCards(widget.deckId);
      if (mounted) {
        setState(() {
          _dueCards = cards;
          _isLoaded = true;
          _isComplete = cards.isEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    }
  }

  Future<void> _reviewCard(int quality) async {
    if (_isReviewing || _currentIndex >= _dueCards.length) return;

    setState(() => _isReviewing = true);

    try {
      final card = _dueCards[_currentIndex];
      await ref
          .read(flashcardRepositoryProvider)
          .reviewCard(card.id, quality);

      if (!mounted) return;

      if (_currentIndex >= _dueCards.length - 1) {
        setState(() {
          _isComplete = true;
          _isReviewing = false;
        });
      } else {
        setState(() {
          _currentIndex++;
          _isFlipped = false;
          _isReviewing = false;
        });
        _flipController.reset();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReviewing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review failed: $e')),
        );
      }
    }
  }

  /// Advance to the next card without recording a review (skip).
  void _nextCard() {
    if (_isReviewing || _currentIndex >= _dueCards.length) return;
    if (_currentIndex >= _dueCards.length - 1) {
      setState(() => _isComplete = true);
    } else {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
      _flipController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Study', style: theme.textTheme.titleLarge),
        actions: [
          if (_dueCards.isNotEmpty && !_isComplete) ...[
            IconButton(
              tooltip: 'Skip to next card',
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: _isReviewing ? null : _nextCard,
            ),
            Padding(
              padding: const EdgeInsets.only(right: Spacing.md),
              child: Center(
                child: Text(
                  '${_currentIndex + 1} / ${_dueCards.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: !_isLoaded
          ? const Center(child: CircularProgressIndicator())
          : _isComplete
              ? _buildCompletionScreen(theme, isDark)
              : _dueCards.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'No cards due',
                      subtitle: 'All caught up! Come back later for more review.',
                    )
                  : _buildStudyView(theme, isDark),
      ),
    );
  }

  Widget _buildStudyView(ThemeData theme, bool isDark) {
    final card = _dueCards[_currentIndex];
    final total = _dueCards.length;

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.screenPaddingH,
            vertical: Spacing.sm,
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: Spacing.borderRadiusPill,
                child: LinearProgressIndicator(
                  value: total > 0 ? (_currentIndex) / total : 0,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${total - _currentIndex} remaining',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.onSurfaceVariantDark
                          : AppColors.onSurfaceVariantLight,
                    ),
                  ),
                  _StatusPill(label: card.statusLabel),
                ],
              ),
            ],
          ),
        ),

        // Flip card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.screenPaddingH),
            child: FlipCardWidget(
              controller: _flipController,
              onFlip: () => setState(() => _isFlipped = !_isFlipped),
              front: _CardFace(
                label: 'FRONT',
                content: card.front,
                isDark: isDark,
                icon: Icons.touch_app_rounded,
                hint: 'Tap to reveal answer',
              ),
              back: _CardFace(
                label: 'BACK',
                content: card.back,
                isDark: isDark,
                isBack: true,
              ),
            ),
          ),
        ),

        // Quality rating buttons (shown after flip)
        AnimatedSwitcher(
          duration: AppAnimations.durationMedium,
          child: _isFlipped
              ? _buildRatingButtons(theme, isDark)
              : Padding(
                  padding: const EdgeInsets.all(Spacing.screenPaddingH),
                  child: Column(
                    children: [
                      Text(
                        'Tap the card to flip',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariantLight,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      OutlinedButton.icon(
                        onPressed: _isReviewing ? null : _nextCard,
                        icon: const Icon(Icons.skip_next_rounded, size: 18),
                        label: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
        ),

        const SizedBox(height: Spacing.md),
      ],
    );
  }

  Widget _buildRatingButtons(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenPaddingH),
      child: Column(
        children: [
          Text(
            'How well did you know this?',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark
                  ? AppColors.onSurfaceVariantDark
                  : AppColors.onSurfaceVariantLight,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              _RatingButton(
                label: 'Again',
                color: AppColors.error,
                isDark: isDark,
                isLoading: _isReviewing,
                onTap: () => _reviewCard(1),
              ),
              const SizedBox(width: Spacing.sm),
              _RatingButton(
                label: 'Hard',
                color: AppColors.warning,
                isDark: isDark,
                isLoading: _isReviewing,
                onTap: () => _reviewCard(2),
              ),
              const SizedBox(width: Spacing.sm),
              _RatingButton(
                label: 'Good',
                color: AppColors.success,
                isDark: isDark,
                isLoading: _isReviewing,
                onTap: () => _reviewCard(3),
              ),
              const SizedBox(width: Spacing.sm),
              _RatingButton(
                label: 'Easy',
                color: AppColors.info,
                isDark: isDark,
                isLoading: _isReviewing,
                onTap: () => _reviewCard(5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.screenPaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppGradients.success,
                shape: BoxShape.circle,
                boxShadow: isDark ? AppShadows.level2Dark : AppShadows.level2,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Session Complete!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              _dueCards.isNotEmpty
                  ? 'You reviewed ${_dueCards.length} card${_dueCards.length == 1 ? '' : 's'}. Great work!'
                  : 'No cards were due for review.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.onSurfaceVariantDark
                    : AppColors.onSurfaceVariantLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            ScButton(
              label: 'Back to Deck',
              icon: Icons.arrow_back_rounded,
              variant: ScButtonVariant.gradient,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card Face Widget ──────────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  final String label;
  final String content;
  final bool isDark;
  final IconData? icon;
  final String? hint;
  final bool isBack;

  const _CardFace({
    required this.label,
    required this.content,
    required this.isDark,
    this.icon,
    this.hint,
    this.isBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: Spacing.borderRadiusLg,
        boxShadow: isDark ? AppShadows.level2Dark : AppShadows.level2,
        border: isBack
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: isBack
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : (isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight),
              borderRadius: Spacing.borderRadiusPill,
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isBack ? AppColors.primary : null,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Hint
          if (hint != null) ...[
            const SizedBox(height: Spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight,
                  ),
                  const SizedBox(width: Spacing.xs),
                ],
                Text(
                  hint!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Rating Button Widget ──────────────────────────────────────────────────────

class _RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.color,
    required this.isDark,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: AppAnimations.durationFast,
          height: Spacing.buttonHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: Spacing.borderRadiusSm,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Status Pill Widget ────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  Color get _color {
    switch (label) {
      case 'New':
        return AppColors.info;
      case 'Learning':
        return AppColors.warning;
      case 'Mastered':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: Spacing.borderRadiusPill,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: _color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
