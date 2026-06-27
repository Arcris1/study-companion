import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../config/app_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/animations.dart';
import '../../../config/theme/gradients.dart';
import '../../providers/chat_provider.dart';
import '../../providers/note_provider.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int notebookId;
  final int sessionId;

  const ChatScreen({
    super.key,
    required this.notebookId,
    required this.sessionId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showScrollFab = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechReady = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (AppConfig.voiceInputEnabled) _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (!_speechReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
        }
        return;
      }
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _messageController.text = result.recognizedWords;
              _messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: _messageController.text.length),
              );
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final shouldShow = maxExtent - currentScroll > 200;
    if (shouldShow != _showScrollFab) {
      setState(() => _showScrollFab = shouldShow);
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider(widget.sessionId).notifier).sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppAnimations.durationMedium,
          curve: AppAnimations.easeOut,
        );
      }
    });
  }

  void _insertSuggestion(String text) {
    _messageController.text = text;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    // Rebuild so the Send button re-evaluates `hasText` and activates.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider(widget.sessionId));
    final hasText = _messageController.text.trim().isNotEmpty;

    ref.listen(chatProvider(widget.sessionId), (_, next) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ask AI',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'AI answers based on your notes in this notebook',
            onPressed: () => _showInfoDialog(context, theme, isDark),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Subtle background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _ChatBackgroundPainter(
                color: AppColors.primary.withValues(alpha: 0.03),
              ),
            ),
          ),

          Column(
            children: [
              _ChatIndexBanner(notebookId: widget.notebookId),
              Expanded(
                child: chatState.messages.isEmpty && !chatState.isGenerating
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.screenPaddingH,
                          vertical: Spacing.space12,
                        ),
                        itemCount: chatState.messages.length +
                            (chatState.isGenerating ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatState.messages.length &&
                              chatState.isGenerating) {
                            return TypingIndicator(
                              streamingText: chatState.streamingContent,
                            );
                          }
                          return ChatBubble(
                            message: chatState.messages[index],
                          );
                        },
                      ),
              ),

              // Error banner
              if (chatState.error != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  color: isDark
                      ? AppColors.errorContainerDark
                      : AppColors.errorContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: isDark ? AppColors.errorDark : AppColors.error,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          chatState.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Input area
              _buildInputBar(context, theme, isDark, chatState, hasText),
            ],
          ),

          // Scroll-to-bottom FAB
          Positioned(
            right: Spacing.screenPaddingH,
            bottom: 90,
            child: AnimatedScale(
              scale: _showScrollFab ? 1.0 : 0.0,
              duration: AppAnimations.durationMedium,
              curve: AppAnimations.overshoot,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isDark
                      ? AppShadows.level2Dark
                      : AppShadows.level2,
                ),
                child: FloatingActionButton.small(
                  heroTag: 'scroll_to_bottom',
                  onPressed: _scrollToBottom,
                  backgroundColor: theme.colorScheme.surface,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Ask a question about your notes',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              "I'll search your notes and give you answers",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(
                  label: 'Summarize key concepts',
                  onTap: () => _insertSuggestion('Summarize key concepts'),
                ),
                _SuggestionChip(
                  label: 'Explain the main topic',
                  onTap: () => _insertSuggestion('Explain the main topic'),
                ),
                _SuggestionChip(
                  label: 'Quiz me on this',
                  onTap: () => _insertSuggestion('Quiz me on this'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    ChatState chatState,
    bool hasText,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.space12,
        vertical: Spacing.space12,
      ),
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
        boxShadow: isDark ? AppShadows.level4Dark : AppShadows.level4,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Microphone button (voice dictation) — hidden behind a feature
            // flag for now; flip AppConfig.voiceInputEnabled to re-enable.
            if (AppConfig.voiceInputEnabled) ...[
              GestureDetector(
                onTap: chatState.isGenerating ? null : _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? AppColors.error.withValues(alpha: 0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    semanticLabel: 'Voice input',
                    color: _isListening
                        ? AppColors.error
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
            ],

            // Pill-shaped text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: Spacing.borderRadiusPill,
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  onChanged: (_) => setState(() {}),
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.space12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.sm),

            // Send button
            _buildSendButton(theme, isDark, chatState),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(ThemeData theme, bool isDark, ChatState chatState) {
    final hasText = _messageController.text.trim().isNotEmpty;

    if (chatState.isGenerating) {
      // Stop button
      return GestureDetector(
        onTap: () {
          // Cancel generation (if supported)
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainerLight,
          ),
          child: Icon(
            Icons.stop_rounded,
            size: 20,
            color: isDark ? AppColors.errorDark : AppColors.error,
          ),
        ),
      );
    }

    if (hasText) {
      // Active send
      return GestureDetector(
        onTap: _sendMessage,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
            boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
          ),
          child: const Icon(
            Icons.arrow_upward_rounded,
            semanticLabel: 'Send message',
            size: 20,
            color: Colors.white,
          ),
        ),
      );
    }

    // Inactive send
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight,
      ),
      child: Icon(
        Icons.arrow_upward_rounded,
        semanticLabel: 'Send message',
        size: 20,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, ThemeData theme, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: Spacing.borderRadiusMd,
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: Spacing.borderRadiusSm,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: Spacing.space12),
            const Text('How it works'),
          ],
        ),
        content: Text(
          'The AI searches your notes for relevant information and uses it '
          'to answer your questions.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Got it',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.space12,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLight,
          borderRadius: Spacing.borderRadiusPill,
          border: Border.all(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Paints a subtle radial gradient at the top for the chat background.
// Prompts the user to index unindexed notes so chat can use semantic search.
// Hidden when all notes (with text) are indexed. Chat still works via keyword
// search when not indexed — this only improves answer quality.
class _ChatIndexBanner extends ConsumerStatefulWidget {
  final int notebookId;
  const _ChatIndexBanner({required this.notebookId});

  @override
  ConsumerState<_ChatIndexBanner> createState() => _ChatIndexBannerState();
}

class _ChatIndexBannerState extends ConsumerState<_ChatIndexBanner> {
  bool _indexing = false;
  int _done = 0;
  int _total = 0;

  Future<void> _indexAll() async {
    setState(() {
      _indexing = true;
      _done = 0;
      _total = 0;
    });
    try {
      await ref.read(noteRepositoryProvider).indexNotebook(
        widget.notebookId,
        onProgress: (d, t) {
          if (mounted) {
            setState(() {
              _done = d;
              _total = t;
            });
          }
        },
      );
      ref.invalidate(notebookIndexProvider(widget.notebookId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _indexing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateAsync = ref.watch(notebookIndexProvider(widget.notebookId));
    return stateAsync.maybeWhen(
      data: (s) {
        if (s.withText == 0) return const SizedBox.shrink();
        if (s.indexed >= s.withText && !_indexing) {
          return const SizedBox.shrink(); // all indexed
        }
        return Material(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md, vertical: Spacing.sm),
            child: _indexing
                ? Row(
                    children: [
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          _total > 0
                              ? 'Indexing notes… $_done / $_total'
                              : 'Indexing notes…',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 18,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          '${s.withText - s.indexed} note(s) not indexed — '
                          'index for smarter answers',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                      TextButton(
                        onPressed: _indexAll,
                        child: const Text('Index all'),
                      ),
                    ],
                  ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ChatBackgroundPainter extends CustomPainter {
  final Color color;

  _ChatBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 0);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.0,
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(
        Rect.fromCircle(center: center, radius: 400),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 400), paint);
  }

  @override
  bool shouldRepaint(_ChatBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}
