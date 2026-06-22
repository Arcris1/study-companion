abstract class Failure {
  final String message;
  const Failure(this.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([String message = 'Database operation failed']) : super(message);
}

class LlmFailure extends Failure {
  const LlmFailure([String message = 'LLM operation failed']) : super(message);
}

class FileFailure extends Failure {
  const FileFailure([String message = 'File operation failed']) : super(message);
}

class ParsingFailure extends Failure {
  const ParsingFailure([String message = 'Parsing failed']) : super(message);
}
