import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/embedding/embedding_service.dart';

class EmbeddingState {
  final EmbeddingStatus status;
  final bool isEmbedding;
  final double embeddingProgress;
  final String? error;

  const EmbeddingState({
    this.status = EmbeddingStatus.unloaded,
    this.isEmbedding = false,
    this.embeddingProgress = 0,
    this.error,
  });

  EmbeddingState copyWith({
    EmbeddingStatus? status,
    bool? isEmbedding,
    double? embeddingProgress,
    String? error,
  }) {
    return EmbeddingState(
      status: status ?? this.status,
      isEmbedding: isEmbedding ?? this.isEmbedding,
      embeddingProgress: embeddingProgress ?? this.embeddingProgress,
      error: error,
    );
  }
}

final embeddingStateProvider =
    NotifierProvider<EmbeddingNotifier, EmbeddingState>(EmbeddingNotifier.new);

class EmbeddingNotifier extends Notifier<EmbeddingState> {
  @override
  EmbeddingState build() {
    return const EmbeddingState();
  }

  EmbeddingService get _service => ref.read(embeddingServiceProvider);

  Future<void> loadModel(String path) async {
    state = state.copyWith(status: EmbeddingStatus.loading);
    try {
      await _service.loadModel(path);
      state = state.copyWith(status: EmbeddingStatus.ready);
    } catch (e) {
      state = state.copyWith(
          status: EmbeddingStatus.error, error: e.toString());
    }
  }

  void unloadModel() {
    _service.unloadModel();
    state = const EmbeddingState();
  }
}
