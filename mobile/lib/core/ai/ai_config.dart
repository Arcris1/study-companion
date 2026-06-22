import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

/// User-facing AI operations whose system prompt + token limit are editable.
enum AiOp { summary, chat, askAi, quiz, flashcards }

class AiOpMeta {
  final String key;
  final String title;
  final String description;
  final String defaultPrompt;
  final int defaultTokens;

  const AiOpMeta({
    required this.key,
    required this.title,
    required this.description,
    required this.defaultPrompt,
    required this.defaultTokens,
  });
}

const Map<AiOp, AiOpMeta> aiOps = {
  AiOp.summary: AiOpMeta(
    key: 'summary',
    title: 'Note Summary',
    description: 'System prompt for the "Generate Summary" feature.',
    defaultPrompt:
        'You are a helpful study assistant. Summarize the following study material concisely, highlighting key concepts, definitions, and important points. Use bullet points for clarity.',
    defaultTokens: 1024,
  ),
  AiOp.chat: AiOpMeta(
    key: 'chat',
    title: 'Ask AI (Chat)',
    description: 'System prompt for the notebook chat (RAG over your notes).',
    defaultPrompt:
        "You are a helpful study assistant. Answer the student's question using the provided context from their notes. Consider the conversation history to understand follow-up questions. Be concise and accurate.",
    defaultTokens: 1024,
  ),
  AiOp.askAi: AiOpMeta(
    key: 'ask_ai',
    title: 'Explain Selection',
    description:
        'System prompt for "Ask AI" on a selected passage in a note.',
    defaultPrompt:
        'You are a helpful study tutor. The student selected a passage from their own study notes and wants it explained. Clarify it concisely in simple language, define any key terms, and add a brief example or analogy if useful. Format your answer in Markdown.',
    defaultTokens: 900,
  ),
  AiOp.quiz: AiOpMeta(
    key: 'quiz',
    title: 'Quiz Generator',
    description:
        'Instructions for quiz generation. The required JSON format, question count and difficulty are appended automatically.',
    defaultPrompt:
        'You are a quiz generator. Write clear, accurate questions that test genuine understanding of the material.',
    defaultTokens: 3000,
  ),
  AiOp.flashcards: AiOpMeta(
    key: 'flashcards',
    title: 'Flashcard Generator',
    description:
        'Instructions for flashcard generation. The required JSON format and card count are appended automatically.',
    defaultPrompt:
        'You are a flashcard generator. Create useful study flashcards with a clear question/concept on the front and a concise, accurate answer on the back.',
    defaultTokens: 3000,
  ),
};

/// Holds the (possibly user-overridden) AI system prompts and token limits.
/// A singleton so non-Riverpod code (e.g. [PromptTemplates]) can read it
/// synchronously; loaded once at startup and updated from the settings UI.
class AiConfig {
  AiConfig._();
  static final AiConfig instance = AiConfig._();

  final Map<String, String> _prompts = {};
  final Map<String, int> _tokens = {};

  static const _chatModelKey = 'ai_chat_model';
  static const _embeddingModelKey = 'ai_embedding_model';
  String _chatModel = AppConfig.openAiChatModel;
  String _embeddingModel = AppConfig.openAiEmbeddingModel;

  String get chatModel => _chatModel;
  String get embeddingModel => _embeddingModel;
  String get defaultChatModel => AppConfig.openAiChatModel;
  String get defaultEmbeddingModel => AppConfig.openAiEmbeddingModel;

  String _promptKey(String k) => 'ai_prompt_$k';
  String _tokenKey(String k) => 'ai_tokens_$k';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final meta in aiOps.values) {
      _prompts[meta.key] =
          prefs.getString(_promptKey(meta.key)) ?? meta.defaultPrompt;
      _tokens[meta.key] =
          prefs.getInt(_tokenKey(meta.key)) ?? meta.defaultTokens;
    }
    _chatModel = prefs.getString(_chatModelKey) ?? AppConfig.openAiChatModel;
    _embeddingModel =
        prefs.getString(_embeddingModelKey) ?? AppConfig.openAiEmbeddingModel;
  }

  Future<void> setChatModel(String value) async {
    final v = value.trim();
    _chatModel = v.isEmpty ? AppConfig.openAiChatModel : v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatModelKey, _chatModel);
  }

  Future<void> setEmbeddingModel(String value) async {
    final v = value.trim();
    _embeddingModel = v.isEmpty ? AppConfig.openAiEmbeddingModel : v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_embeddingModelKey, _embeddingModel);
  }

  String systemPrompt(AiOp op) {
    final meta = aiOps[op]!;
    final v = _prompts[meta.key];
    return (v != null && v.trim().isNotEmpty) ? v : meta.defaultPrompt;
  }

  int tokenLimit(AiOp op) => _tokens[aiOps[op]!.key] ?? aiOps[op]!.defaultTokens;

  Future<void> setSystemPrompt(AiOp op, String value) async {
    final meta = aiOps[op]!;
    _prompts[meta.key] = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_promptKey(meta.key), value);
  }

  Future<void> setTokenLimit(AiOp op, int value) async {
    final meta = aiOps[op]!;
    final clamped = value.clamp(64, 16000);
    _tokens[meta.key] = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tokenKey(meta.key), clamped);
  }

  Future<void> reset(AiOp op) async {
    final meta = aiOps[op]!;
    _prompts[meta.key] = meta.defaultPrompt;
    _tokens[meta.key] = meta.defaultTokens;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_promptKey(meta.key));
    await prefs.remove(_tokenKey(meta.key));
  }

  Future<void> resetAll() async {
    for (final op in AiOp.values) {
      await reset(op);
    }
    _chatModel = AppConfig.openAiChatModel;
    _embeddingModel = AppConfig.openAiEmbeddingModel;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatModelKey);
    await prefs.remove(_embeddingModelKey);
  }
}
