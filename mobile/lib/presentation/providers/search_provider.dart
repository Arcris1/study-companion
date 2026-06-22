import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/objectbox.dart';
import '../../core/embedding/embedding_service.dart';
import '../../core/storage/local_cache.dart';
import '../../data/datasources/local/notebook_local_datasource.dart';
import '../../data/repositories/search_repository.dart';
import '../../domain/entities/search_result.dart';
import 'note_provider.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(
    ref.read(noteDatasourceProvider),
    NotebookLocalDatasource(ref.read(objectBoxProvider)),
    ref.read(embeddingServiceProvider),
  );
});

final searchQueryProvider = NotifierProvider<_SearchQueryNotifier, String>(_SearchQueryNotifier.new);

class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final searchResultsProvider =
    FutureProvider.autoDispose<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.trim().isEmpty) return [];

  // Debounce: wait 300ms after last query change
  final completer = Completer<List<SearchResult>>();
  final timer = Timer(const Duration(milliseconds: 300), () async {
    try {
      final repository = ref.read(searchRepositoryProvider);
      final results = await repository.search(query);
      if (!completer.isCompleted) completer.complete(results);
    } catch (e, st) {
      if (!completer.isCompleted) completer.completeError(e, st);
    }
  });

  ref.onDispose(() {
    timer.cancel();
    if (!completer.isCompleted) completer.complete([]);
  });

  return completer.future;
});

/// Stores and retrieves recent search queries from SharedPreferences.
final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
        SearchHistoryNotifier.new);

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const String _historyKey = 'search_history';
  static const int _maxHistory = 10;

  @override
  List<String> build() {
    _loadHistory();
    return [];
  }

  LocalCache get _cache => ref.read(localCacheProvider);

  Future<void> _loadHistory() async {
    final raw = await _cache.getString(_historyKey);
    if (raw != null && raw.isNotEmpty) {
      state = raw.split('|||').where((s) => s.isNotEmpty).toList();
    }
  }

  Future<void> addQuery(String query) async {
    if (query.trim().isEmpty) return;
    final trimmed = query.trim();

    // Remove if already exists, then add to front
    final updated = [
      trimmed,
      ...state.where((q) => q != trimmed),
    ].take(_maxHistory).toList();

    state = updated;
    await _cache.setString(_historyKey, updated.join('|||'));
  }

  Future<void> removeQuery(String query) async {
    final updated = state.where((q) => q != query).toList();
    state = updated;
    await _cache.setString(_historyKey, updated.join('|||'));
  }

  Future<void> clearHistory() async {
    state = [];
    await _cache.setString(_historyKey, '');
  }
}
