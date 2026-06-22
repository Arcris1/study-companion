class AppConfig {
  static const String appName = 'Study Companion';
  static const String appVersion = '1.0.0';

  // LLM defaults
  static const int defaultContextLength = 2048;
  static const int maxContextLength = 4096;
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 512;

  // Chunking
  static const int chunkSize = 500;
  static const int chunkOverlap = 100;

  // RAG
  static const int ragTopK = 5;

  // Quiz
  static const int defaultQuizQuestions = 10;
  static const int minQuizQuestions = 5;
  static const int maxQuizQuestions = 30;

  // ─── OpenAI (cloud AI backend) ──────────────────────────────────────
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  // Chat/completions model used for chat, quiz/flashcard generation, etc.
  static const String openAiChatModel = 'gpt-4o-mini';
  // Embeddings model + output dimensionality (must match the ObjectBox
  // HnswIndex dimension on NoteChunkModel.embedding — currently 384).
  static const String openAiEmbeddingModel = 'text-embedding-3-small';
  static const int embeddingDimensions = 384;

  // ─── Feature flags ──────────────────────────────────────────────────
  // Voice dictation (mic button) in the chat screen. Hidden for now but the
  // speech_to_text wiring is kept intact — flip to true to re-enable.
  static final bool voiceInputEnabled = false;
}
