import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../providers/flashcard_provider.dart';
import '../../../core/openai/openai_client.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/note_source_sheet.dart';

class FlashcardDeckListScreen extends ConsumerStatefulWidget {
  final int notebookId;

  const FlashcardDeckListScreen({super.key, required this.notebookId});

  @override
  ConsumerState<FlashcardDeckListScreen> createState() =>
      _FlashcardDeckListScreenState();
}

class _FlashcardDeckListScreenState
    extends ConsumerState<FlashcardDeckListScreen> {
  bool _isCreating = false;

  Future<void> _createDeck() async {
    final result = await showDialog<({String title, List<int> noteIds})>(
      context: context,
      builder: (_) => _NewDeckDialog(notebookId: widget.notebookId),
    );

    if (result == null || result.title.trim().isEmpty) return;
    final title = result.title;

    // Cache ALL refs before any async work
    final repository = ref.read(flashcardRepositoryProvider);

    if (!OpenAiClient.instance.hasKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No OpenAI API key set. Add your key in Settings > AI.')),
        );
      }
      return;
    }

    setState(() => _isCreating = true);
    try {
      final deck = await repository.createDeck(widget.notebookId, title.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating flashcards...')),
        );
      }

      await repository.generateFlashcards(
        deck.id,
        widget.notebookId,
        noteIds: result.noteIds,
      );

      // Refresh the list. Defer the invalidate to the next frame:
      // invalidating a family provider this screen is actively watching from
      // within the callback triggers Flutter's "_dependents.isEmpty" assertion.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flashcards generated successfully!')),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.invalidate(flashcardDecksProvider(widget.notebookId));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final decks = ref.watch(flashcardDecksProvider(widget.notebookId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Flashcard Decks', style: theme.textTheme.titleLarge),
      ),
      body: decks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.style_rounded,
              title: 'No flashcard decks yet',
              subtitle:
                  'Create AI-powered flashcards from your notes for spaced repetition study',
              actionLabel: 'Create Deck',
              onAction: _isCreating ? null : _createDeck,
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              Spacing.screenPaddingH,
              Spacing.screenPaddingH,
              Spacing.screenPaddingH,
              Spacing.screenPaddingH + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final deck = list[index];
              return _DeckCard(
                title: deck.title,
                cardCount: deck.cardCount,
                dueCount: deck.dueCount,
                isDark: isDark,
                onTap: () => context.push('/flashcard-deck/${deck.id}/study'),
                onStats: () => context.push('/flashcard-deck/${deck.id}/stats'),
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Deck?'),
                      content: const Text(
                          'This will delete all flashcards and review history in this deck.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(flashcardRepositoryProvider).deleteDeck(deck.id);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ref.invalidate(flashcardDecksProvider(widget.notebookId));
                      }
                    });
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: _isCreating
          ? const FloatingActionButton(
              onPressed: null,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          : FloatingActionButton(
              onPressed: _createDeck,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
    );
  }
}

// Self-contained dialog so its TextEditingController is owned and disposed
// by the dialog's own State (after the route is fully removed), avoiding the
// dispose-during-exit-animation race of a manually managed controller.
class _NewDeckDialog extends StatefulWidget {
  final int notebookId;
  const _NewDeckDialog({required this.notebookId});

  @override
  State<_NewDeckDialog> createState() => _NewDeckDialogState();
}

class _NewDeckDialogState extends State<_NewDeckDialog> {
  final _controller = TextEditingController();
  List<int> _noteIds = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop((title: _controller.text, noteIds: _noteIds));
  }

  Future<void> _pickSource() async {
    final result = await showNoteSourceSheet(
      context,
      notebookId: widget.notebookId,
      selected: _noteIds,
    );
    if (result != null) setState(() => _noteIds = result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAll = _noteIds.isEmpty;

    return AlertDialog(
      title: const Text('New Flashcard Deck'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Enter deck title',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Spacing.sm),
          OutlinedButton.icon(
            onPressed: _pickSource,
            icon: Icon(
              isAll ? Icons.auto_awesome_rounded : Icons.checklist_rounded,
              size: 18,
            ),
            label: Text(
              isAll
                  ? 'Source: All notes'
                  : 'Source: ${_noteIds.length} note${_noteIds.length == 1 ? '' : 's'}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              alignment: Alignment.centerLeft,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _DeckCard extends StatelessWidget {
  final String title;
  final int cardCount;
  final int dueCount;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onStats;
  final VoidCallback onDelete;

  const _DeckCard({
    required this.title,
    required this.cardCount,
    required this.dueCount,
    required this.isDark,
    required this.onTap,
    required this.onStats,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Container(
        padding: const EdgeInsets.all(Spacing.cardPadding),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: Spacing.borderRadiusMd,
          boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: Spacing.borderRadiusMd,
          child: Row(
            children: [
              // Gradient icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: Spacing.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.style_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: Spacing.listItemGap),
              // Title and card count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '$cardCount cards',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.onSurfaceVariantDark
                            : AppColors.onSurfaceVariantLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Due badge
              if (dueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: Spacing.borderRadiusPill,
                  ),
                  child: Text(
                    '$dueCount due',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: Spacing.xs),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariantLight,
                  size: 20,
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'stats',
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Statistics'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'stats') onStats();
                  if (value == 'delete') onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
