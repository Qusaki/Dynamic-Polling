import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/poll_models.dart';
import '../../services/api_service.dart';
import '../../providers/poll_provider.dart'; // Import for apiServiceProvider

// Provider to fetch results
final pollResultsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, pollId) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getPollResults(pollId); // Need to add this method to ApiService
});

class ResultsScreen extends ConsumerWidget {
  final String pollId;

  const ResultsScreen({super.key, required this.pollId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int id = int.parse(pollId);
    final resultsAsync = ref.watch(pollResultsProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Poll Results')),
      body: SafeArea(
        child: resultsAsync.when(
          data: (data) {
            final results = data['results'] as List<dynamic>;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${index + 1}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (result['type'] == 'OPEN_ENDED')
                        ..._buildOpenEndedResults(context, result['responses'])
                      else
                        ..._buildVoteCounts(context, result['counts'], result['total']),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      ),
    );
  }

  List<Widget> _buildOpenEndedResults(BuildContext context, List<dynamic> responses) {
    if (responses.isEmpty) return [const Text('No responses yet.')];
    return responses.map((r) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text('• $r'),
    )).toList();
  }

  List<Widget> _buildVoteCounts(BuildContext context, Map<String, dynamic> counts, int total) {
    if (total == 0) return [const Text('No votes yet.')];
    
    return counts.entries.map((entry) {
      final percentage = (entry.value as int) / total;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key),
                Text('${entry.value} votes (${(percentage * 100).toStringAsFixed(1)}%)'),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: percentage, minHeight: 8),
          ],
        ),
      );
    }).toList();
  }
}
