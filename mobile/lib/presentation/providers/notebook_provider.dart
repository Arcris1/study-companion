import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/objectbox.dart';
import '../../data/datasources/local/notebook_local_datasource.dart';
import '../../data/repositories/notebook_repository.dart';
import '../../domain/entities/notebook.dart';

final notebookDatasourceProvider = Provider<NotebookLocalDatasource>((ref) {
  return NotebookLocalDatasource(ref.read(objectBoxProvider));
});

final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  return NotebookRepository(ref.read(notebookDatasourceProvider));
});

final notebooksProvider = NotifierProvider<NotebooksNotifier, AsyncValue<List<Notebook>>>(NotebooksNotifier.new);

class NotebooksNotifier extends Notifier<AsyncValue<List<Notebook>>> {
  @override
  AsyncValue<List<Notebook>> build() {
    load();
    return const AsyncValue.loading();
  }

  NotebookRepository get _repository => ref.read(notebookRepositoryProvider);

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final notebooks = await _repository.getAll();
      state = AsyncValue.data(notebooks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Notebook> create(String title, {String? description, String color = '#6750A4'}) async {
    final now = DateTime.now();
    final notebook = await _repository.create(Notebook(
      title: title,
      description: description,
      color: color,
      createdAt: now,
      updatedAt: now,
    ));
    await load();
    return notebook;
  }

  Future<void> update(Notebook notebook) async {
    await _repository.update(notebook.copyWith(updatedAt: DateTime.now()));
    await load();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    await load();
  }
}
