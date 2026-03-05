import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/poll_provider.dart'; // Import for apiServiceProvider
import '../../utils/pdf_generator.dart';
import 'package:printing/printing.dart';
import '../../models/poll_models.dart';

// Provider to fetch both Poll info and its Results
final pollResultsProvider = FutureProvider.family<({Poll poll, Map<int, Map<String, dynamic>> tallies}), int>((ref, pollId) async {
  final apiService = ref.read(apiServiceProvider);
  final resultsData = await apiService.getPollResults(pollId);
  final poll = await apiService.getPoll(pollId);

  final List<dynamic> resultsList = resultsData['results'];
  final Map<int, Map<String, dynamic>> tallies = {
    for (var r in resultsList)
      r['question_id'] as int: r as Map<String, dynamic>
  };

  return (poll: poll, tallies: tallies);
});

class ResultsScreen extends ConsumerWidget {
  final String pollId;

  const ResultsScreen({super.key, required this.pollId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int id = int.parse(pollId);
    final resultsAsync = ref.watch(pollResultsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poll Results'),
        actions: [
          resultsAsync.maybeWhen(
            data: (data) => IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () async {
                final pdfBytes = await PdfGenerator.generatePollResultsPdf(data.poll, data.tallies);
                await Printing.sharePdf(
                  bytes: pdfBytes,
                  filename: '${data.poll.title}_result.pdf',
                );
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: resultsAsync.when(
          data: (data) {
            final poll = data.poll;
            final tallies = data.tallies;
            
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            itemCount: poll.questions.length,
            itemBuilder: (context, index) {
              final question = poll.questions[index];
              final result = tallies[question.id];
              
              if (result == null || result['results'] == null) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Question ${index + 1}: ${question.text}', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        const Text('No votes yet.'),
                      ],
                    ),
                  ),
                );
              }

              final resultsMap = result['results'];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${index + 1}: ${question.text}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (question.type == QuestionType.open_ended)
                        ..._buildOpenEndedResults(context, (resultsMap as List<dynamic>?) ?? [])
                      else
                        ..._buildVoteCounts(context, (resultsMap as Map<String, dynamic>?) ?? {}),
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

  List<Widget> _buildVoteCounts(BuildContext context, Map<String, dynamic> counts) {
    if (counts.isEmpty) return [const Text('No votes yet.')];
    
    int total = 0;
    counts.forEach((key, value) {
      total += (value as int);
    });

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
