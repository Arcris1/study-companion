enum ModelStatus {
  notDownloaded,
  downloading,
  downloaded,
  loading,
  ready,
  error;

  bool get isAvailable => this == downloaded || this == ready;
}
