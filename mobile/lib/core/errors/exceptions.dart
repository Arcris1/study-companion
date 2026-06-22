class DatabaseException implements Exception {
  final String message;
  const DatabaseException([this.message = 'Database error']);
  @override
  String toString() => 'DatabaseException: $message';
}

class LlmException implements Exception {
  final String message;
  const LlmException([this.message = 'LLM error']);
  @override
  String toString() => 'LlmException: $message';
}

class FileException implements Exception {
  final String message;
  const FileException([this.message = 'File error']);
  @override
  String toString() => 'FileException: $message';
}
