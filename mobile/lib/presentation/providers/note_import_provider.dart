import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ImportStatus { idle, picking, importing, success, error }

class ImportState {
  final ImportStatus status;
  final String? fileName;
  final String? errorMessage;

  const ImportState({
    this.status = ImportStatus.idle,
    this.fileName,
    this.errorMessage,
  });

  ImportState copyWith({
    ImportStatus? status,
    String? fileName,
    String? errorMessage,
  }) {
    return ImportState(
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final noteImportProvider = NotifierProvider.autoDispose<NoteImportNotifier, ImportState>(NoteImportNotifier.new);

class NoteImportNotifier extends Notifier<ImportState> {
  @override
  ImportState build() {
    return const ImportState();
  }

  void setPicking() {
    state = state.copyWith(status: ImportStatus.picking);
  }

  void setImporting(String fileName) {
    state = state.copyWith(status: ImportStatus.importing, fileName: fileName);
  }

  void setSuccess() {
    state = state.copyWith(status: ImportStatus.success);
  }

  void setError(String message) {
    state = state.copyWith(status: ImportStatus.error, errorMessage: message);
  }

  void reset() {
    state = const ImportState();
  }
}
