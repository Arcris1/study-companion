import '../entities/notebook.dart';

abstract class INotebookRepository {
  Future<List<Notebook>> getAll();
  Future<Notebook?> getById(int id);
  Future<Notebook> create(Notebook notebook);
  Future<Notebook> update(Notebook notebook);
  Future<void> delete(int id);
}
