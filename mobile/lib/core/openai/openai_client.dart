import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../ai/ai_config.dart';
import '../errors/exceptions.dart';

/// Thin client for the OpenAI REST API (chat completions + embeddings).
///
/// The app is local-first with no backend, so this calls the OpenAI API
/// directly from the device using the user's own API key. The key is held
/// in memory here (loaded from secure storage at startup / when saved in
/// settings) so that sync readiness checks like `LlmService.isReady` work.
class OpenAiClient {
  OpenAiClient._();
  static final OpenAiClient instance = OpenAiClient._();

  String? _apiKey;

  /// Set/clear the in-memory API key (call after loading from secure storage
  /// or when the user saves a new key in settings).
  void setApiKey(String? key) {
    final trimmed = key?.trim();
    _apiKey = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  bool get hasKey => _apiKey != null;
  String? get apiKey => _apiKey;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

  Map<String, String> _keyHeaders(String? key) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      };

  // ─── Text-generation provider routing (OpenAI or DeepSeek) ──────────
  // Embeddings + vision always use OpenAI; only chat/completions can be
  // routed to DeepSeek (it has no embeddings/vision API).

  String? _deepseekKey;

  void setDeepseekApiKey(String? key) {
    final t = key?.trim();
    _deepseekKey = (t != null && t.isNotEmpty) ? t : null;
  }

  bool get hasDeepseekKey => _deepseekKey != null;

  /// Whether the active text-generation provider has a key configured.
  bool get hasTextKey =>
      AiConfig.instance.usingDeepseek ? _deepseekKey != null : hasKey;

  ({String baseUrl, String? key, String model}) get _textTarget =>
      AiConfig.instance.usingDeepseek
          ? (
              baseUrl: AppConfig.deepseekBaseUrl,
              key: _deepseekKey,
              model: AiConfig.instance.deepseekModel,
            )
          : (
              baseUrl: AppConfig.openAiBaseUrl,
              key: _apiKey,
              model: AiConfig.instance.chatModel,
            );

  // ─── Chat completions ───────────────────────────────────────────────

  Future<String> chat(
    List<Map<String, String>> messages, {
    int maxTokens = 512,
    double temperature = 0.7,
    bool jsonMode = false,
  }) async {
    final t = _textTarget;
    if (t.key == null) throw const LlmException('AI API key not set');
    final res = await _post(
      Uri.parse('${t.baseUrl}/chat/completions'),
      headers: _keyHeaders(t.key),
      body: jsonEncode({
        'model': t.model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': temperature,
        if (jsonMode) 'response_format': {'type': 'json_object'},
      }),
    );
    if (res.statusCode != 200) {
      throw LlmException(
          'Chat failed (${res.statusCode}): ${_errorMessage(res.body)}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) return '';
    final message = choices.first['message'];
    final content = message is Map ? message['content'] : null;
    return (content is String ? content : '').trim();
  }

  Stream<String> chatStream(
    List<Map<String, String>> messages, {
    int maxTokens = 1024,
    double temperature = 0.7,
  }) async* {
    final t = _textTarget;
    if (t.key == null) throw const LlmException('AI API key not set');
    final request = http.Request(
      'POST',
      Uri.parse('${t.baseUrl}/chat/completions'),
    );
    request.headers.addAll(_keyHeaders(t.key));
    request.body = jsonEncode({
      'model': t.model,
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': true,
    });

    final response = await _send(request);
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw LlmException(
          'Chat failed (${response.statusCode}): ${_errorMessage(body)}');
    }

    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;
      if (payload == '[DONE]') break;
      try {
        final json = jsonDecode(payload) as Map<String, dynamic>;
        final choices = json['choices'] as List?;
        if (choices == null || choices.isEmpty) continue;
        final delta = choices.first['delta'];
        final content = delta is Map ? delta['content'] : null;
        if (content is String && content.isNotEmpty) yield content;
      } catch (_) {
        // Ignore malformed SSE keep-alive lines.
      }
    }
  }

  /// Streams a vision completion: sends [prompt] plus a PNG [imageBytes]
  /// (e.g. a boxed region of a note) to a vision-capable chat model.
  Stream<String> visionStream(
    String prompt,
    Uint8List imageBytes, {
    int maxTokens = 700,
  }) async* {
    if (!hasKey) throw const LlmException('OpenAI API key not set');
    final b64 = base64Encode(imageBytes);
    final request = http.Request(
      'POST',
      Uri.parse('${AppConfig.openAiBaseUrl}/chat/completions'),
    );
    request.headers.addAll(_headers);
    request.body = jsonEncode({
      'model': AiConfig.instance.chatModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/png;base64,$b64'},
            },
          ],
        },
      ],
      'max_tokens': maxTokens,
      'stream': true,
    });

    final response = await _send(request);
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw LlmException(
          'OpenAI vision failed (${response.statusCode}): ${_errorMessage(body)}');
    }

    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;
      if (payload == '[DONE]') break;
      try {
        final json = jsonDecode(payload) as Map<String, dynamic>;
        final choices = json['choices'] as List?;
        if (choices == null || choices.isEmpty) continue;
        final delta = choices.first['delta'];
        final content = delta is Map ? delta['content'] : null;
        if (content is String && content.isNotEmpty) yield content;
      } catch (_) {
        // Ignore keep-alive lines.
      }
    }
  }

  // ─── Embeddings ─────────────────────────────────────────────────────

  /// Embeds [texts] into vectors of [dimensions] length. Batches requests so
  /// large imports stay within the API's per-request input limits.
  Future<List<Float32List>> embed(
    List<String> texts, {
    int dimensions = AppConfig.embeddingDimensions,
  }) async {
    if (!hasKey) throw const LlmException('OpenAI API key not set');
    if (texts.isEmpty) return [];

    final out = <Float32List>[];
    const batchSize = 96;
    for (var i = 0; i < texts.length; i += batchSize) {
      final end = (i + batchSize) > texts.length ? texts.length : i + batchSize;
      final batch = texts.sublist(i, end);

      final res = await _post(
        Uri.parse('${AppConfig.openAiBaseUrl}/embeddings'),
        headers: _headers,
        body: jsonEncode({
          'model': AiConfig.instance.embeddingModel,
          'input': batch,
          'dimensions': dimensions,
        }),
      );
      if (res.statusCode != 200) {
        throw LlmException(
            'OpenAI embeddings failed (${res.statusCode}): ${_errorMessage(res.body)}');
      }
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final list = (data['data'] as List)
          .cast<Map<String, dynamic>>()
        ..sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));
      for (final item in list) {
        final vec = (item['embedding'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
        out.add(Float32List.fromList(vec));
      }
    }
    return out;
  }

  Future<http.Response> _post(
    Uri url, {
    required Map<String, String> headers,
    required String body,
  }) async {
    try {
      return await http.post(url, headers: headers, body: body);
    } catch (e) {
      throw _networkError(e);
    }
  }

  Future<http.StreamedResponse> _send(http.Request request) async {
    try {
      return await http.Client().send(request);
    } catch (e) {
      throw _networkError(e);
    }
  }

  /// Converts low-level connection failures into a friendly, user-facing
  /// message instead of a raw SocketException.
  LlmException _networkError(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('No address associated') ||
        s.contains('Network is unreachable') ||
        s.contains('Connection refused') ||
        s.contains('Connection reset') ||
        s.contains('Connection closed') ||
        s.contains('Connection timed out') ||
        s.contains('timed out')) {
      return const LlmException(
          'No internet connection. Check your network and try again.');
    }
    return LlmException(e.toString());
  }

  String _errorMessage(String body) {
    try {
      final json = jsonDecode(body);
      return json['error']?['message']?.toString() ?? body;
    } catch (_) {
      return body;
    }
  }
}
