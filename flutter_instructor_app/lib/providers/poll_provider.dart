import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poll_models.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class PollsNotifier extends StateNotifier<AsyncValue<List<Poll>>> {
  final ApiService _apiService;

  PollsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _loadPolls();
  }

  Future<void> _loadPolls() async {
    try {
      // 1. Load from cache first
      final cachedPolls = await _apiService.getCachedPolls();
      if (cachedPolls.isNotEmpty) {
        state = AsyncValue.data(cachedPolls);
      }

      // 2. Fetch from network
      final freshPolls = await _apiService.fetchMyPolls();
      if (mounted) {
        state = AsyncValue.data(freshPolls);
      }
    } catch (e, st) {
      // If we have cached data, we might want to keep showing it but show a snackbar error.
      // For now, let's update state to error only if we don't have data.
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      } else {
        // We have data, but network failed. 
        // We could maybe set a side-effect or just log it.
        // For simplicity, we just keep the cached data.
        print('Network fetch failed, keeping cached data: $e');
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading(); // Optional: show loading indicator
    try {
      final freshPolls = await _apiService.fetchMyPolls(forceRefresh: true);
      if (mounted) {
        state = AsyncValue.data(freshPolls);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final pollsProvider = StateNotifierProvider<PollsNotifier, AsyncValue<List<Poll>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PollsNotifier(apiService);
});
