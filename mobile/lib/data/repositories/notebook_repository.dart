import '../../domain/entities/notebook.dart';
import '../../domain/repositories/i_notebook_repository.dart';
import '../datasources/local/notebook_local_datasource.dart';
import '../models/notebook_model.dart';

class NotebookRepository implements INotebookRepository {
  final NotebookLocalDatasource _datasource;

  NotebookRepository(this._datasource);

  @override
  Future<List<Notebook>> getAll() async {
    final models = _datasource.getAll();
    return models.map((m) => m.toEntity(
      noteCount: _datasource.getNoteCount(m.id),
    )).toList();
  }

  @override
  Future<Notebook?> getById(int id) async {
    final model = _datasource.getById(id);
    if (model == null) return null;
    return model.toEntity(
      noteCount: _datasource.getNoteCount(model.id),
    );
  }

  @override
  Future<Notebook> create(Notebook notebook) async {
    final model = NotebookModel.fromEntity(notebook);
    final created = _datasource.create(model);
    return created.toEntity();
  }

  @override
  Future<Notebook> update(Notebook notebook) async {
    final model = NotebookModel.fromEntity(notebook);
    final updated = _datasource.update(model);
    return updated.toEntity(
      noteCount: _datasource.getNoteCount(updated.id),
    );
  }

  @override
  Future<void> delete(int id) async {
    _datasource.delete(id);
  }
}
