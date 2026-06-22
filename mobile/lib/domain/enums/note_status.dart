enum NoteStatus {
  importing,
  processing,
  ready,
  error;

  String get label {
    switch (this) {
      case NoteStatus.importing: return 'Importing...';
      case NoteStatus.processing: return 'Processing...';
      case NoteStatus.ready: return 'Ready';
      case NoteStatus.error: return 'Error';
    }
  }

  bool get isLoading => this == importing || this == processing;
}
