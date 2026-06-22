import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/exceptions.dart';
import '../openai/openai_client.dart';

final llmServiceProvider = Provider<LlmService>((ref) {
  return LlmService();
});

enum LlmStatus { unloaded, loading, ready, generating, error }

/// Generation service backed by the OpenAI chat-completions API.
///
/// The public interface is kept identical to the previous on-device
/// (llama.cpp) implementation so existing repositories/providers and the
/// Gemma-style [PromptTemplates] continue to work unchanged. "Readiness"
/// now simply means an API key is configured.
class LlmService {
  LlmStatus _status = LlmStatus.unloaded;

  LlmService();

  LlmStatus get status => _status;

  /// Ready when an OpenAI API key is configured.
  bool get isReady => OpenAiClient.instance.hasKey;

  /// Kept for interface compatibility with the old model-download flow.
  /// There is no model to load for the cloud backend — readiness depends
  /// only on the API key — so this is a no-op.
  Future<void> loadModel(String modelPath) async {
    _status = LlmStatus.ready;
  }

  void unloadModel() {
    _status = LlmStatus.unloaded;
  }

  Future<String> generate(
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.7,
    List<String>? stopTokens,
  }) async {
    if (!isReady) throw const LlmException('OpenAI API key not set');

    _status = LlmStatus.generating;
    try {
      final result = await OpenAiClient.instance.chat(
        _toMessages(prompt),
        maxTokens: maxTokens,
        temperature: temperature,
        jsonMode: _expectsJson(prompt),
      );
      _status = LlmStatus.ready;
      return result;
    } catch (e) {
      _status = LlmStatus.ready;
      if (e is LlmException) rethrow;
      throw LlmException('Generation failed: $e');
    }
  }

  Stream<String> generateStream(
    String prompt, {
    int maxTokens = 1024,
    double temperature = 0.7,
  }) async* {
    if (!isReady) throw const LlmException('OpenAI API key not set');

    _status = LlmStatus.generating;
    try {
      yield* OpenAiClient.instance.chatStream(
        _toMessages(prompt),
        maxTokens: maxTokens,
        temperature: temperature,
      );
      _status = LlmStatus.ready;
    } catch (e) {
      _status = LlmStatus.ready;
      if (e is LlmException) rethrow;
      throw LlmException('Stream generation failed: $e');
    }
  }

  // ─── Prompt conversion ──────────────────────────────────────────────

  /// JSON mode is enabled when the prompt explicitly asks for JSON output
  /// (all of the JSON-returning templates say "Return ONLY valid JSON").
  bool _expectsJson(String prompt) => prompt.toLowerCase().contains('valid json');

  /// Convert a Gemma-style tagged prompt (`<|begin_of_turn|>system|user`)
  /// into OpenAI chat messages. The trailing assistant priming used by the
  /// templates is intentionally dropped — OpenAI returns a complete message.
  List<Map<String, String>> _toMessages(String prompt) {
    final messages = <Map<String, String>>[];

    final systemMatch = RegExp(
      r'<\|begin_of_turn\|>system\s*\n(.*?)<\|end_of_turn\|>',
      dotAll: true,
    ).firstMatch(prompt);
    if (systemMatch != null) {
      messages.add({'role': 'system', 'content': systemMatch.group(1)!.trim()});
    }

    final userMatch = RegExp(
      r'<\|begin_of_turn\|>user\s*\n(.*?)<\|end_of_turn\|>',
      dotAll: true,
    ).firstMatch(prompt);
    if (userMatch != null) {
      messages.add({'role': 'user', 'content': userMatch.group(1)!.trim()});
    }

    if (messages.isEmpty) {
      messages.add({'role': 'user', 'content': prompt});
    }
    return messages;
  }
}
