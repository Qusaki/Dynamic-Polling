import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart'; // Import WebSocket package
import 'package:go_router/go_router.dart'; // For navigation
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/poll_models.dart' as app_models; // Import app models
import '../../services/api_service.dart'; // To get base URL for WebSocket
import 'package:flutter_riverpod/flutter_riverpod.dart'; // For ref.read
import 'dart:math'; // For max in charts
import '../../providers/poll_provider.dart';

class LiveSessionScreen extends ConsumerStatefulWidget {
  final String pollId;

  const LiveSessionScreen({
    super.key,
    required this.pollId,
  });

  static const routeName = '/live-session';

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  app_models.Poll? _poll;
  Map<int, Map<String, dynamic>> _tallies = {};
  WebSocketChannel? _channel;
  int _totalVotes = 0;
  bool _isManuallyDisconnecting = false; // Flag to prevent navigation on manual refresh

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _isManuallyDisconnecting = false; // Reset flag on new connection
    final websocketBaseUrl = ApiService.websocketBaseUrl;
    final wsUrl = Uri.parse('$websocketBaseUrl/ws/polls/${widget.pollId}/instructor');
    
    _channel = WebSocketChannel.connect(wsUrl);

    _channel?.stream.listen(
      (message) {
        final decodedMessage = jsonDecode(message);
        final type = decodedMessage['type'];
        final data = decodedMessage['data'];

        if (!mounted) return;

        setState(() {
          if (type == 'initial_state') {
            _poll = app_models.Poll.fromJson(data['poll']);
            _tallies = {
              for (var t in data['tallies'])
                t['question_id'] as int: t as Map<String, dynamic>
            };
            _updateTotalVotes();
          } else if (type == 'tally_update') {
            final questionId = data['question_id'] as int;
            _tallies[questionId] = data as Map<String, dynamic>;
            _updateTotalVotes();
          }
        });
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('WebSocket Error: $error')),
          );
          context.go('/dashboard');
        }
        _disconnectWebSocket();
      },
      onDone: () {
        debugPrint('WebSocket connection done. Manual disconnect: $_isManuallyDisconnecting');
        if (mounted && !_isManuallyDisconnecting) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Live session ended unexpectedly.')),
           );
           context.go('/dashboard');
        }
      },
    );
  }

  void _disconnectWebSocket() {
    _isManuallyDisconnecting = true; // Set flag before manually closing
    _channel?.sink.close();
    _channel = null;
  }

  void _updateTotalVotes() {
    int total = 0;
    _tallies.forEach((questionId, tallyData) {
      if (tallyData['results'] is Map) {
        total += (tallyData['results'] as Map).values.fold(0, (sum, count) => sum + (count as int));
      } else if (tallyData['results'] is List) {
        total += (tallyData['results'] as List).length;
      }
    });
    _totalVotes = total;
  }

  @override
  void dispose() {
    _disconnectWebSocket();
    ref.invalidate(pollsProvider); // Invalidate the polls list on dispose
    super.dispose();
  }

  void _showShareDialog() {
    if (_poll == null) return;

    const studentAppBaseUrl = 'http://localhost:3000'; 
    final pollUrl = '$studentAppBaseUrl/join/${_poll!.access_code}';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Share Poll'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: pollUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                const SizedBox(height: 16),
                SelectableText(pollUrl),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pollUrl)).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard!')),
                  );
                });
              },
              child: const Text('Copy Link'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_poll == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Session')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_poll!.title} (Live)'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              avatar: const Icon(Icons.people),
              label: Text('$_totalVotes Votes'),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _poll!.questions.length,
        itemBuilder: (context, index) {
          final question = _poll!.questions[index];
          final tallyData = _tallies[question.id];

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  if (tallyData != null)
                    ResultChartSelector(
                      question: question,
                      tallyData: tallyData,
                    )
                  else
                    const Center(child: Text('No votes yet.')),
                ],
              ),
            ),
          );
        },
      ),
      persistentFooterButtons: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Accepting Votes'),
                Switch(
                  value: _poll!.is_active,
                  onChanged: (value) async {
                    if (_poll == null) return;
                    try {
                      final apiService = ref.read(apiServiceProvider);
                      await apiService.updatePollStatus(int.parse(widget.pollId), value);
                      if (mounted) {
                        setState(() {
                          _poll = _poll!.copyWith(is_active: value);
                        });
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Poll status updated to ${value ? "Active" : "Inactive"}.')),
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update poll status: ${e.toString()}')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              onPressed: _showShareDialog,
            ),
            TextButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Manage'),
              onPressed: () async {
                if (_poll != null) {
                  if (_poll!.is_active) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please stop the live session first before editing questions.')),
                    );
                  } else {
                    final result = await context.push('/poll/${_poll!.id}/manage');
                    if (result == true && mounted) {
                      _disconnectWebSocket();
                      _connectWebSocket();
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Poll data not available to manage.')),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}


// --- Helper Widgets ---

class ResultChartSelector extends StatelessWidget {
  final app_models.Question question;
  final Map<String, dynamic> tallyData;

  const ResultChartSelector({super.key, required this.question, required this.tallyData});

  @override
  Widget build(BuildContext context) {
    final results = tallyData['results']; // Results will be Map<String, int> or List<String>

    switch (question.type) {
      case app_models.QuestionType.multiple_choice:
        if (results is Map<String, dynamic> && results.isNotEmpty) {
          return MultipleChoiceChart(voteCounts: Map<String, int>.from(results));
        }
        return const Center(child: Text('No multiple choice votes yet.'));
      case app_models.QuestionType.rating:
        if (results is Map<String, dynamic> && results.isNotEmpty) {
          return RatingChart(voteCounts: Map<String, int>.from(results));
        }
        return const Center(child: Text('No rating votes yet.'));
      case app_models.QuestionType.open_ended:
        if (results is List<dynamic> && results.isNotEmpty) {
          return OpenEndedResponses(responses: List<String>.from(results));
        }
        return const Center(child: Text('No open-ended responses yet.'));
      default:
        return Center(child: Text('Unsupported question type: ${question.type}'));
    }
  }
}

class MultipleChoiceChart extends StatelessWidget {
  final Map<String, int> voteCounts;

  const MultipleChoiceChart({super.key, required this.voteCounts});

  @override
  Widget build(BuildContext context) {
    final sortedEntries = voteCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)); // Sort options alphabetically for consistent display

    final barGroups = sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final count = entry.value.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: Colors.primaries[index % Colors.primaries.length],
            width: 20,
          ),
        ],
      );
    }).toList();

    double maxY = 0;
    if (voteCounts.isNotEmpty) {
      maxY = (voteCounts.values.reduce((a, b) => a > b ? a : b) * 1.2);
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedEntries.length) {
                    return Text(sortedEntries[index].key); // Display the actual option text
                  }
                  return const Text('');
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RatingChart extends StatelessWidget {
  final Map<String, int> voteCounts;

  const RatingChart({super.key, required this.voteCounts});

  @override
  Widget build(BuildContext context) {
    // Ensure all ratings from 1 to 5 are present, even if count is 0
    final allRatings = { for (var i = 1; i <= 5; i++) i.toString(): voteCounts[i.toString()] ?? 0 };

    final sortedEntries = allRatings.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

    final barGroups = sortedEntries.asMap().entries.map((entry) {
      final index = entry.key; // 0-indexed for chart
      final rating = entry.value.key; // "1", "2", etc.
      final count = entry.value.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: Color.lerp(Colors.red, Colors.green, (int.parse(rating) - 1) / 4), // Color from red to green
            width: 20,
          ),
        ],
      );
    }).toList();

    double maxY = 0;
    if (voteCounts.isNotEmpty) {
      maxY = (voteCounts.values.reduce((a, b) => a > b ? a : b) * 1.2);
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedEntries.length) {
                    return Text(sortedEntries[index].key); // Display the actual rating (1-5)
                  }
                  return const Text('');
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OpenEndedResponses extends StatelessWidget {
  final List<String> responses;

  const OpenEndedResponses({super.key, required this.responses});

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) {
      return const Center(child: Text('No open-ended responses yet.'));
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: responses.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(responses[index]),
            ),
          );
        },
      ),
    );
  }
}
