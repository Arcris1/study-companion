import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../providers/note_provider.dart';

/// Opens the note-source picker. Returns the chosen note IDs, where an **empty
/// list means "General — all notes"**; `null` means the user cancelled.
Future<List<int>?> showNoteSourceSheet(
  BuildContext context, {
  required int notebookId,
  required List<int> selected,
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NoteSourceSheet(notebookId: notebookId, initial: selected),
  );
}

class _NoteSourceSheet extends ConsumerStatefulWidget {
  final int notebookId;
  final List<int> initial;
  const _NoteSourceSheet({required this.notebookId, required this.initial});

  @override
  ConsumerState<_NoteSourceSheet> createState() => _NoteSourceSheetState();
}

class _NoteSourceSheetState extends ConsumerState<_NoteSourceSheet> {
  late final Set<int> _selected = {...widget.initial};

  bool get _isAll => _selected.isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notesAsync = ref.watch(notesProvider(widget.notebookId));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: Spacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.screenPaddingH,
                  Spacing.md,
                  Spacing.screenPaddingH,
                  Spacing.sm,
                ),
                child: Row(
                  children: [
                    Text('Choose source', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      _isAll ? 'All notes' : '${_selected.length} selected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: notesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (notes) {
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: Spacing.sm),
                      children: [
                        // General — all notes
                        ListTile(
                          onTap: () => setState(_selected.clear),
                          leading: const Icon(Icons.auto_awesome_rounded),
                          title: const Text('General — all notes'),
                          subtitle: Text('Use every note in this notebook',
                              style: theme.textTheme.bodySmall),
                          trailing: Icon(
                            _isAll
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: _isAll
                                ? AppColors.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Divider(height: 1),
                        if (notes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(Spacing.lg),
                            child: Text('No notes in this notebook yet.',
                                style: theme.textTheme.bodySmall),
                          ),
                        ...notes.map((note) {
                          final checked = _selected.contains(note.id);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(note.id);
                              } else {
                                _selected.remove(note.id);
                              }
                            }),
                            title: Text(note.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            secondary: Icon(
                              note.sourceType == 'md'
                                  ? Icons.article_rounded
                                  : Icons.description_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.screenPaddingH),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_selected.toList()),
                      child: Text(_isAll
                          ? 'Use all notes'
                          : 'Use ${_selected.length} note${_selected.length == 1 ? '' : 's'}'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
