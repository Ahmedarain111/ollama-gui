import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../chat/chat_providers.dart';

/// Models currently loaded in VRAM.
final runningModelsProvider = FutureProvider<List<RunningModel>>((ref) async {
  final client = ref.watch(ollamaClientProvider);
  return client.listRunning();
});

/// Detailed information for a specific model (Modelfile, parameters, template).
final modelInfoProvider =
    FutureProvider.family<ModelInfo, String>((ref, modelName) async {
  final client = ref.watch(ollamaClientProvider);
  return client.showModel(modelName);
});

/// Controller to refresh installed and running models.
class ModelsNotifier extends StateNotifier<AsyncValue<void>> {
  ModelsNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> refresh() async {
    ref.invalidate(installedModelsProvider);
    ref.invalidate(runningModelsProvider);
  }

  Future<void> deleteModel(String name) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(ollamaClientProvider);
      await client.deleteModel(name);
      await refresh();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final modelsNotifierProvider =
    StateNotifierProvider<ModelsNotifier, AsyncValue<void>>((ref) {
  return ModelsNotifier(ref);
});
