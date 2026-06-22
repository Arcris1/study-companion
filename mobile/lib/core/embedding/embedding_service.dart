import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/exceptions.dart';
import '../openai/openai_client.dart';

final embeddingServiceProvider = Provider<EmbeddingService>((ref) {
  return EmbeddingService();
});

enum EmbeddingStatus { unloaded, loading, ready, error }

/// Embedding service backed by the OpenAI embeddings API
/// (text-embedding-3-small, requested at [AppConfig.embeddingDimensions]
/// dimensions so vectors match the ObjectBox HnswIndex). Replaces the old
/// stubbed/on-device implementation. "Readiness" means an API key is set.
class EmbeddingService {
  EmbeddingStatus _status = EmbeddingStatus.unloaded;

  EmbeddingStatus get status => _status;

  bool get isReady => OpenAiClient.instance.hasKey;

  /// No model to load for the cloud backend — kept for interface
  /// compatibility with the old model-download flow.
  Future<void> loadModel(String modelPath) async {
    _status = EmbeddingStatus.ready;
  }

  /// Generate an embedding vector for a single text.
  Future<Float32List> embed(String text) async {
    if (!isReady) throw const LlmException('OpenAI API key not set');
    final vectors = await OpenAiClient.instance.embed([text]);
    if (vectors.isEmpty) {
      throw const LlmException('Embedding returned no vector');
    }
    return vectors.first;
  }

  /// Generate embeddings for multiple texts in one (batched) call.
  Future<List<Float32List>> embedBatch(List<String> texts) async {
    if (!isReady) throw const LlmException('OpenAI API key not set');
    return OpenAiClient.instance.embed(texts);
  }

  void unloadModel() {
    _status = EmbeddingStatus.unloaded;
  }
}
