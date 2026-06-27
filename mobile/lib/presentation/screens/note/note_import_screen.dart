import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/animations.dart';
import '../../providers/note_provider.dart';
import '../../providers/note_import_provider.dart';
import '../../widgets/common/sc_button.dart';
import '../../widgets/common/sc_text_field.dart';

class NoteImportScreen extends ConsumerStatefulWidget {
  final int notebookId;

  const NoteImportScreen({super.key, required this.notebookId});

  @override
  ConsumerState<NoteImportScreen> createState() => _NoteImportScreenState();
}

class _NoteImportScreenState extends ConsumerState<NoteImportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final importNotifier = ref.read(noteImportProvider.notifier);
    importNotifier.setPicking();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'pdf'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      importNotifier.reset();
      return;
    }

    final files = result.files.where((f) => f.path != null).toList();
    if (files.isEmpty) {
      importNotifier.setError('Could not access the selected file(s)');
      return;
    }

    final notesNotifier = ref.read(notesProvider(widget.notebookId).notifier);
    var imported = 0;
    final failed = <String>[];

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final label = files.length > 1
          ? '${file.name}  (${i + 1} of ${files.length})'
          : file.name;
      importNotifier.setImporting(label);
      try {
        await notesNotifier.importFile(file.path!);
        imported++;
      } catch (_) {
        failed.add(file.name);
      }
    }

    // All failed → stay on screen and show the error/retry state.
    if (imported == 0) {
      importNotifier.setError('Import failed for: ${failed.join(', ')}');
      return;
    }

    importNotifier.setSuccess();
    if (mounted) {
      ref.invalidate(notesProvider(widget.notebookId));
      final String message;
      if (failed.isEmpty) {
        message = imported == 1
            ? 'Note imported successfully!'
            : '$imported notes imported successfully!';
      } else {
        message =
            '$imported imported · ${failed.length} failed (${failed.join(', ')})';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.pop();
    }
  }

  Future<void> _createManual() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and content')),
      );
      return;
    }

    try {
      await ref.read(notesProvider(widget.notebookId).notifier).createManual(
            _titleController.text.trim(),
            _contentController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note created successfully!')),
        );
        ref.invalidate(notesProvider(widget.notebookId));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final importState = ref.watch(noteImportProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Add Note',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.screenPaddingH,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                _TabChip(
                  icon: Icons.upload_file_rounded,
                  label: 'Import File',
                  isActive: _activeTab == 0,
                  isDark: isDark,
                  onTap: () => _tabController.animateTo(0),
                ),
                const SizedBox(width: Spacing.sm),
                _TabChip(
                  icon: Icons.edit_rounded,
                  label: 'Write Manually',
                  isActive: _activeTab == 1,
                  isDark: isDark,
                  onTap: () => _tabController.animateTo(1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Import tab ──────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.screenPaddingH),
            child: importState.status == ImportStatus.importing
                ? _ImportProgressCard(
                    fileName: importState.fileName ?? '',
                    isDark: isDark,
                  )
                : importState.status == ImportStatus.error
                    ? _ImportErrorState(
                        message: importState.errorMessage ?? 'Import failed',
                        isDark: isDark,
                        onRetry: _pickFiles,
                      )
                    : _DropZone(
                        isDark: isDark,
                        onTap: _pickFiles,
                      ),
          ),

          // ── Manual tab ──────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.screenPaddingH),
            child: Column(
              children: [
                ScTextField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'Note title',
                ),
                const SizedBox(height: Spacing.md),
                // Content field with page-margin feel
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.20),
                        width: 2,
                      ),
                    ),
                  ),
                  child: ScTextField(
                    controller: _contentController,
                    label: 'Content',
                    hint: 'Paste or type your study notes here...',
                    maxLines: 15,
                    textStyle: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sectionGap),
                ScButton(
                  label: 'Create Note',
                  icon: Icons.save_rounded,
                  variant: ScButtonVariant.gradient,
                  onPressed: _createManual,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab chip ───────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _TabChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.durationMedium,
        curve: AppAnimations.easeOut,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLight),
          borderRadius: Spacing.borderRadiusPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : (isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariantLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : (isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Drop zone ──────────────────────────────────────────────────────────────

class _DropZone extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _DropZone({required this.isDark, required this.onTap});

  @override
  State<_DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
            borderRadius: Spacing.borderRadiusLg,
          ),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: AppColors.primary.withValues(alpha: 0.4),
              borderRadius: Spacing.radiusLg,
              strokeWidth: 2,
              dashLength: 8,
              gapLength: 6,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Floating upload icon
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (_, child) {
                    final offset = math.sin(_floatController.value * math.pi) * -8;
                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: child,
                    );
                  },
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 64,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),

                const SizedBox(height: Spacing.space20),

                Text(
                  'Tap to import documents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: widget.isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurfaceLight,
                  ),
                ),

                const SizedBox(height: Spacing.sm),

                Text(
                  'Supports TXT, Markdown & PDF · select one or more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight,
                  ),
                ),

                const SizedBox(height: Spacing.md),

                // File type badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FileTypeBadge(
                      icon: Icons.text_snippet_rounded,
                      label: 'TXT',
                      tint: AppColors.info,
                      isDark: widget.isDark,
                    ),
                    const SizedBox(width: Spacing.sm),
                    _FileTypeBadge(
                      icon: Icons.article_rounded,
                      label: 'MD',
                      tint: AppColors.success,
                      isDark: widget.isDark,
                    ),
                    const SizedBox(width: Spacing.sm),
                    _FileTypeBadge(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'PDF',
                      tint: AppColors.error,
                      isDark: widget.isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FileTypeBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final bool isDark;

  const _FileTypeBadge({
    required this.icon,
    required this.label,
    required this.tint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight,
        borderRadius: Spacing.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.onSurfaceVariantDark
                  : AppColors.onSurfaceVariantLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dashed border painter ──────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        final extracted = metric.extractPath(distance, end);
        canvas.drawPath(extracted, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      color != old.color;
}

// ─── Import progress card ───────────────────────────────────────────────────

class _ImportProgressCard extends StatelessWidget {
  final String fileName;
  final bool isDark;

  const _ImportProgressCard({
    required this.fileName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(Spacing.sectionGap),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: Spacing.borderRadiusMd,
          boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step indicators
            _ImportStep(
              number: 1,
              label: 'Reading file...',
              status: _StepStatus.current,
              isDark: isDark,
              isLast: false,
            ),
            _ImportStep(
              number: 2,
              label: 'Extracting text...',
              status: _StepStatus.pending,
              isDark: isDark,
              isLast: false,
            ),
            _ImportStep(
              number: 3,
              label: 'Chunking content...',
              status: _StepStatus.pending,
              isDark: isDark,
              isLast: false,
            ),
            _ImportStep(
              number: 4,
              label: 'Ready to study!',
              status: _StepStatus.pending,
              isDark: isDark,
              isLast: true,
            ),

            const SizedBox(height: Spacing.md),

            // File name
            Text(
              fileName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.onSurfaceVariantDark
                    : AppColors.onSurfaceVariantLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

enum _StepStatus { completed, current, pending }

class _ImportStep extends StatelessWidget {
  final int number;
  final String label;
  final _StepStatus status;
  final bool isDark;
  final bool isLast;

  const _ImportStep({
    required this.number,
    required this.label,
    required this.status,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator column
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status == _StepStatus.completed
                    ? AppColors.success
                    : status == _StepStatus.current
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.surfaceContainerDark
                            : AppColors.surfaceContainerLight),
              ),
              child: Center(
                child: status == _StepStatus.completed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : status == _StepStatus.current
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : Text(
                            '$number',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariantLight,
                            ),
                          ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: status == _StepStatus.completed
                    ? AppColors.success
                    : (isDark
                        ? AppColors.outlineDark
                        : AppColors.outlineLight),
              ),
          ],
        ),

        const SizedBox(width: Spacing.listItemGap),

        // Label
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: status == _StepStatus.current
                  ? (isDark
                      ? AppColors.onSurfaceDark
                      : AppColors.onSurfaceLight)
                  : (isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariantLight),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Import error state ─────────────────────────────────────────────────────

class _ImportErrorState extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback onRetry;

  const _ImportErrorState({
    required this.message,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: isDark ? AppColors.errorDark : AppColors.error,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.errorDark : AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sectionGap),
          ScButton(
            label: 'Try Again',
            icon: Icons.refresh,
            variant: ScButtonVariant.outlined,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
