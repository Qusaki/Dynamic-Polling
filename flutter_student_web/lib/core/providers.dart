
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../models/poll_models.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final pollProvider = FutureProvider.family<PollPublic, String>((ref, accessCode) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getPollByAccessCode(accessCode);
});
