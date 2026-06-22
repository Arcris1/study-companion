import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../../domain/entities/search_result.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common/empty_state_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Auto-focus the search bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).set(query);
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addQuery(query);
      ref.read(searchQueryProvider.notifier).set(query);
    }
  }

  void _onHistoryTap(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    ref.read(searchQueryProvider.notifier).set(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final query = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final searchHistory = ref.watch(searchHistoryProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            _SearchBar(
              controller: _searchController,
              focusNode: _focusNode,
              isDark: isDark,
              theme: theme,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              onBack: () => context.pop(),
              onClear: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).set('');
              },
            ),

            // Content
            Expanded(
              child: query.trim().isEmpty
                  ? _RecentSearches(
                      history: searchHistory,
                      isDark: isDark,
                      theme: theme,
                      onTap: _onHistoryTap,
                      onRemove: (q) =>
                          ref.read(searchHistoryProvider.notifier).removeQuery(q),
                      onClearAll: () =>
                          ref.read(searchHistoryProvider.notifier).clearHistory(),
                    )
                  : searchResults.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Search error: $e',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.errorDark
                                : AppColors.error,
                          ),
                        ),
                      ),
                      data: (results) {
                        if (results.isEmpty) {
                          return EmptyStateWidget(
                            icon: Icons.search_off_rounded,
                            title: 'No results found',
                            subtitle:
                                'Try different keywords or check your notes',
                          );
                        }
                        return _SearchResultsList(
                          results: results,
                          isDark: isDark,
                          theme: theme,
                          onTap: (result) {
                            ref
                                .read(searchHistoryProvider.notifier)
                                .addQuery(query);
                            context.push('/note/${result.noteId}');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search Bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onBack;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.theme,
    required this.onChanged,
    required this.onSubmitted,
    required this.onBack,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.screenPaddingH,
        right: Spacing.screenPaddingH,
        top: Spacing.screenPaddingV,
        bottom: Spacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: Spacing.borderRadiusMd,
          boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark
                    ? AppColors.onSurfaceVariantDark
                    : AppColors.onSurfaceVariantLight,
              ),
              onPressed: onBack,
            ),

            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColors.onSurfaceDark
                      : AppColors.onSurfaceLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: Spacing.space12,
                  ),
                ),
              ),
            ),

            // Clear button
            if (controller.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariantLight,
                ),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Searches ─────────────────────────────────────────────────────────

class _RecentSearches extends StatelessWidget {
  final List<String> history;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  const _RecentSearches({
    required this.history,
    required this.isDark,
    required this.theme,
    required this.onTap,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_rounded,
        title: 'Search your notes',
        subtitle: 'Find content across all your notebooks',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenPaddingH,
      ),
      children: [
        // Header
        Row(
          children: [
            Text(
              'Recent Searches',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.onSurfaceDark
                    : AppColors.onSurfaceLight,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClearAll,
              child: Text(
                'Clear All',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        // History items
        ...history.map((query) => _RecentSearchItem(
              query: query,
              isDark: isDark,
              theme: theme,
              onTap: () => onTap(query),
              onRemove: () => onRemove(query),
            )),
      ],
    );
  }
}

class _RecentSearchItem extends StatelessWidget {
  final String query;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchItem({
    required this.query,
    required this.isDark,
    required this.theme,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: Spacing.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.sm,
          horizontal: Spacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 20,
              color: isDark
                  ? AppColors.onSurfaceVariantDark
                  : AppColors.onSurfaceVariantLight,
            ),
            const SizedBox(width: Spacing.space12),
            Expanded(
              child: Text(
                query,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.onSurfaceDark
                      : AppColors.onSurfaceLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: isDark
                    ? AppColors.onSurfaceVariantDark
                    : AppColors.onSurfaceVariantLight,
              ),
              onPressed: onRemove,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search Results List ─────────────────────────────────────────────────────

class _SearchResultsList extends StatelessWidget {
  final List<SearchResult> results;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<SearchResult> onTap;

  const _SearchResultsList({
    required this.results,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenPaddingH,
      ),
      itemCount: results.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(
              top: Spacing.xs,
              bottom: Spacing.sm,
            ),
            child: Text(
              '${results.length} result${results.length == 1 ? '' : 's'} found',
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDark
                    ? AppColors.onSurfaceVariantDark
                    : AppColors.onSurfaceVariantLight,
              ),
            ),
          );
        }

        final result = results[index - 1];
        return _SearchResultCard(
          result: result,
          isDark: isDark,
          theme: theme,
          onTap: () => onTap(result),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.result,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  Color _relevanceColor() {
    if (result.relevanceScore >= 0.7) return AppColors.success;
    if (result.relevanceScore >= 0.4) return AppColors.warning;
    return AppColors.onSurfaceVariantLight;
  }

  @override
  Widget build(BuildContext context) {
    // Create a snippet preview (first 150 chars of chunk text)
    final snippet = result.chunk.text.length > 150
        ? '${result.chunk.text.substring(0, 150)}...'
        : result.chunk.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: Spacing.borderRadiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: Spacing.borderRadiusMd,
          child: Container(
            padding: const EdgeInsets.all(Spacing.cardPadding),
            decoration: BoxDecoration(
              borderRadius: Spacing.borderRadiusMd,
              boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: notebook > note title + relevance
                Row(
                  children: [
                    // Notebook/note context
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: Spacing.xs),
                          Flexible(
                            child: Text(
                              result.notebookTitle,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.xs),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariantLight,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              result.noteTitle,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? AppColors.onSurfaceVariantDark
                                    : AppColors.onSurfaceVariantLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Relevance indicator
                    const SizedBox(width: Spacing.sm),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _relevanceColor(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: Spacing.sm),

                // Snippet preview
                Text(
                  snippet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurfaceLight,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
