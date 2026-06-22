import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/animations.dart';
import '../../providers/notebook_provider.dart';
import '../../widgets/common/sc_button.dart';
import '../../widgets/common/sc_text_field.dart';

class CreateNotebookScreen extends ConsumerStatefulWidget {
  const CreateNotebookScreen({super.key});

  @override
  ConsumerState<CreateNotebookScreen> createState() =>
      _CreateNotebookScreenState();
}

class _CreateNotebookScreenState extends ConsumerState<CreateNotebookScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedColor = '#7C3AED';
  bool _isCreating = false;

  static const _colors = [
    '#7C3AED', '#4F46E5', '#3B82F6', '#06B6D4',
    '#10B981', '#84CC16', '#F59E0B', '#F97316',
    '#EF4444', '#EC4899', '#8B5CF6', '#6366F1',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isCreating = true);

    try {
      await ref.read(notebooksProvider.notifier).create(
            _titleController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            color: _selectedColor,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create notebook: $e')),
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
    final titleLength = _titleController.text.length;
    final descLength = _descController.text.length;
    final titleEmpty = _titleController.text.trim().isEmpty;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Create Notebook',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: Spacing.screenPaddingH,
          right: Spacing.screenPaddingH,
          top: Spacing.sectionGap,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            ScTextField(
              controller: _titleController,
              label: 'Notebook Title',
              hint: 'e.g., Biology 101',
              autofocus: true,
              maxLength: 50,
              onChanged: (_) => setState(() {}),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: Spacing.xs),
                child: AnimatedSwitcher(
                  duration: AppAnimations.durationFast,
                  child: Text(
                    '$titleLength/50',
                    key: ValueKey(titleLength),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: titleLength >= 50
                          ? (isDark ? AppColors.errorDark : AppColors.error)
                          : titleLength >= 40
                              ? (isDark
                                  ? AppColors.warningDark
                                  : AppColors.warning)
                              : (isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariantLight),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: Spacing.md),

            // Description field
            ScTextField(
              controller: _descController,
              label: 'Description (optional)',
              hint: 'What is this notebook about?',
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: Spacing.xs),
                child: Text(
                  '$descLength/200',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight,
                  ),
                ),
              ),
            ),

            const SizedBox(height: Spacing.sectionGap),

            // Color picker
            Text(
              'Color',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.listItemGap),
            Wrap(
              spacing: Spacing.listItemGap,
              runSpacing: Spacing.listItemGap,
              children: _colors.map((hex) {
                final color =
                    Color(int.parse(hex.replaceFirst('#', '0xFF')));
                final isSelected = hex == _selectedColor;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: AppAnimations.durationMedium,
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 48.0 : 44.0,
                    height: isSelected ? 48.0 : 44.0,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: isDark ? Colors.white : AppColors.onSurfaceLight,
                              width: 3,
                            )
                          : null,
                    ),
                    child: AnimatedSwitcher(
                      duration: AppAnimations.durationFast,
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('check'),
                              color: Colors.white,
                              size: 20,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('empty'),
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: Spacing.xl),

            // Save button
            ScButton(
              label: 'Create Notebook',
              icon: Icons.add_rounded,
              variant: titleEmpty
                  ? ScButtonVariant.secondary
                  : ScButtonVariant.gradient,
              isLoading: _isCreating,
              onPressed: titleEmpty ? null : _create,
            ),

            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
  }
}
