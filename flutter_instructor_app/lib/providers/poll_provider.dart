import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poll_models.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final pollsProvider = FutureProvider<List<Poll>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchMyPolls();
});
