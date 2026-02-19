
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/poll_models.dart';
import '../../core/api_service.dart'; // Import ApiService if strictly needed, mostly used via provider
import 'package:shared_preferences/shared_preferences.dart'; // Added for local storage
// import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Removed to avoid dependency issue

// Simple custom rating widget to avoid extra dependency for now
class RatingWidget extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  
  const RatingWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < value ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () => onChanged(index + 1),
        );
      }),
    );
  }
}

class VoteScreen extends ConsumerStatefulWidget {
  final String accessCode;

  const VoteScreen({super.key, required this.accessCode});

  @override
  ConsumerState<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends ConsumerState<VoteScreen> {
  // Store answers: QuestionID -> Answer Value
  final Map<int, dynamic> _answers = {};
  // Track submission status per question
  final Map<int, bool> _submitted = {}; 
  bool _isSubmitting = false;
  bool _hasSubmittedPoll = false; // New flag

  @override
  void initState() {
    super.initState();
    _checkIfAlreadySubmitted();
  }

  Future<void> _checkIfAlreadySubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSubmitted = prefs.getBool('submitted_${widget.accessCode}') ?? false;
    
    if (hasSubmitted && mounted) {
      setState(() {
        _hasSubmittedPoll = true;
      });
      _showAlreadySubmittedDialog();
    }
  }

  void _showAlreadySubmittedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Already Submitted'),
        content: const Text('You have already submitted your response for this poll.'),
        actions: [
          // Optional: Check results? Or just Close? 
          // If close, maybe navigate away or just stay blocked? 
          // User said "popup messgae"
          // Let's just have a disabled "OK" that stays or navigates home?
          // For now, allow viewing but disable interactions?
          // Or just block.
        ],
      ),
    );
  }

  void _submitAnswer(int questionId) async {
    final answer = _answers[questionId];
    if (answer == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.submitVote(widget.accessCode, questionId, answer.toString());
      
      setState(() {
        _submitted[questionId] = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vote submitted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pollAsync = ref.watch(pollProvider(widget.accessCode));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Polling'),
        centerTitle: true,
      ),
      body: pollAsync.when(
        data: (poll) => _buildPollBody(poll),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: (_submitted.isNotEmpty && _submitted.values.first == true) || _hasSubmittedPoll // Hide if already submitted (simple logic)
          ? null 
          : Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _isSubmitting || _hasSubmittedPoll ? null : _submitAll,
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Poll', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
    );
  }

  void _submitAll() async {
    // Collect all answers
    final votes = <Map<String, dynamic>>[];
    _answers.forEach((qId, val) {
      votes.add({
        'question_id': qId,
        'response_value': val.toString(),
      });
    });

    if (votes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer at least one question.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.submitBatchVotes(widget.accessCode, votes);
      
      setState(() {
        // Mark all questions as submitted
        for (var v in votes) {
          _submitted[v['question_id'] as int] = true;
        }
      });

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('submitted_${widget.accessCode}', true);

      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Your responses have been submitted!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildPollBody(PollPublic poll) {
    return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800), // Limit width for large screens
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          // Poll Header Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.poll, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          poll.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (poll.description != null && poll.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      poll.description!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Questions
          ...poll.questions.map((q) => _buildQuestionCard(q)),
          const SizedBox(height: 80), // Space for bottom bar
        ],
      ),
    ));
  }

  Widget _buildQuestionCard(Question question) {
    final isSubmitted = _submitted[question.id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Q${question.order + 1}. ${question.text}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (isSubmitted)
               const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Submitted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              )
            else
              _buildInputForType(question),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForType(Question question) {
    switch (question.type) {
      case 'MULTIPLE_CHOICE':
        return Column(
          children: question.options.map((opt) {
            return RadioListTile<String>(
              title: Text(opt.text),
              value: opt.text, // Backend expects value string for now? Or Option ID? 
                               // Backend logic: models.Vote stores 'response_value'. 
                               // For MC, usually the option text or ID. Let's send text as per other logic.
              groupValue: _answers[question.id],
              onChanged: (val) {
                setState(() {
                  _answers[question.id] = val;
                });
              },
            );
          }).toList(),
        );
      
      case 'RATING':
        // Custom 5 star rating
        return Center(
          child: RatingWidget(
            value: _answers[question.id] != null ? int.tryParse(_answers[question.id].toString()) ?? 0 : 0,
            onChanged: (val) {
              setState(() {
                _answers[question.id] = val.toString();
              });
            },
          ),
        );

      case 'OPEN_ENDED':
          return _OpenEndedInput(
          questionId: question.id,
          wordLimit: question.wordLimit,
          onChanged: (val) {
             setState(() {
              _answers[question.id] = val;
            });
          },
        );
        
      default:
        return const Text('Unknown question type');
    }
  }
}

class _OpenEndedInput extends StatefulWidget {
  final int questionId;
  final int? wordLimit;
  final ValueChanged<String> onChanged;

  const _OpenEndedInput({
    required this.questionId,
    this.wordLimit,
    required this.onChanged,
  });

  @override
  State<_OpenEndedInput> createState() => _OpenEndedInputState();
}

class _OpenEndedInputState extends State<_OpenEndedInput> {
  final _controller = TextEditingController();
  int _currentWordCount = 0;
  String _lastValidValue = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    final text = _controller.text;
    
    // Calculate word count
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final count = text.isEmpty ? 0 : words.length;

    if (widget.wordLimit == null) {
      _updateWordCount(count);
      widget.onChanged(text);
      return;
    }

    if (count > widget.wordLimit!) {
      // Revert to last valid value immediately
      // This is the "Blocking" behavior
      _controller.value = TextEditingValue(
        text: _lastValidValue,
        selection: TextSelection.collapsed(offset: _lastValidValue.length),
      );
      
      // Optional: Show visual feedback or simple shake could go here, 
      // but strict blocking is sufficient as requested.
    } else {
      _lastValidValue = text;
      _updateWordCount(count);
      widget.onChanged(text);
    }
  }

  void _updateWordCount(int count) {
    if (_currentWordCount != count) {
      setState(() {
        _currentWordCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(),
          ),
          minLines: 2,
          maxLines: 4,
        ),
        if (widget.wordLimit != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '$_currentWordCount / ${widget.wordLimit} words (${widget.wordLimit! - _currentWordCount} remaining)',
              style: TextStyle(
                color: _currentWordCount >= widget.wordLimit! ? Colors.orange : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
