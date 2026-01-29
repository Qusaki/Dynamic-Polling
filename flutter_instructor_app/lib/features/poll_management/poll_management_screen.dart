import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/poll_models.dart' as app_models;
import '../../providers/poll_provider.dart';
import '../../services/api_service.dart';

// Import form widgets used for editing questions
import '../create_poll/widgets/create_multiple_choice_form.dart';
import '../create_poll/widgets/create_rating_poll_form.dart';
import '../create_poll/widgets/create_open_ended_form.dart';


class PollManagementScreen extends ConsumerStatefulWidget {
  final String pollId;

  const PollManagementScreen({super.key, required this.pollId});

  @override
  ConsumerState<PollManagementScreen> createState() => _PollManagementScreenState();
}

class _PollManagementScreenState extends ConsumerState<PollManagementScreen> {
  app_models.Poll? _poll;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPollDetails();
  }

  Future<void> _fetchPollDetails() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      // We need an API endpoint to fetch a single poll by ID.
      // Current API has fetchMyPolls() which gets all, but not a single one.
      // For now, we'll fetch all and filter. This is inefficient but works.
      final allPolls = await apiService.fetchMyPolls();
      setState(() {
        _poll = allPolls.firstWhere((p) => p.id == int.parse(widget.pollId), orElse: () => throw Exception('Poll not found'));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load poll details: $_errorMessage')),
        );
      }
    }
  }

  // --- Question Editing Logic ---
  Future<void> _showQuestionFormDialog({required app_models.QuestionType type, app_models.Question? questionToEdit}) async {
    final isEditing = questionToEdit != null;
    app_models.Question? savedQuestionData; // This will hold the data from the form

    await showDialog(
      context: context,
      builder: (ctx) {
        Widget form;
        String title;

        switch (type) {
          case app_models.QuestionType.multiple_choice:
            title = isEditing ? 'Edit Multiple Choice' : 'Add Multiple Choice';
            form = CreateMultipleChoiceForm(
              initialQuestion: questionToEdit,
              onSave: (data) {
                savedQuestionData = app_models.Question(
                  id: isEditing ? questionToEdit!.id : 0, // Keep ID for update, 0 for new
                  order: isEditing ? questionToEdit!.order : (_poll?.questions.length ?? 0), // Keep existing order or assign new
                  type: app_models.QuestionType.multiple_choice,
                  text: data.questionText,
                  options: data.options.map((o) => app_models.Option(id: 0, text: o)).toList(),
                );
                Navigator.pop(ctx);
              },
            );
            break;
          case app_models.QuestionType.rating:
            title = isEditing ? 'Edit Rating Question' : 'Add Rating Question';
            form = CreateRatingPollForm(
              initialQuestion: questionToEdit,
              onSave: (data) {
                savedQuestionData = app_models.Question(
                  id: isEditing ? questionToEdit!.id : 0,
                  order: isEditing ? questionToEdit!.order : (_poll?.questions.length ?? 0),
                  type: app_models.QuestionType.rating,
                  text: data.questionText,
                  options: [],
                );
                Navigator.pop(ctx);
              },
            );
            break;
          case app_models.QuestionType.open_ended:
            title = isEditing ? 'Edit Open-Ended' : 'Add Open-Ended';
            form = CreateOpenEndedForm(
              initialQuestion: questionToEdit,
              onSave: (data) {
                savedQuestionData = app_models.Question(
                  id: isEditing ? questionToEdit!.id : 0,
                  order: isEditing ? questionToEdit!.order : (_poll?.questions.length ?? 0),
                  type: app_models.QuestionType.open_ended,
                  text: data.questionText,
                  options: [],
                );
                Navigator.pop(ctx);
              },
            );
            break;
        }

        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: form,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        );
      },
    );

    // After the dialog closes, check if data was saved
    if (savedQuestionData != null && _poll != null) {
      try {
        final apiService = ref.read(apiServiceProvider);
        if (isEditing) {
          await apiService.updateQuestion(int.parse(widget.pollId), questionToEdit!.id, savedQuestionData!); // Assert non-nullability
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Question updated successfully!')),
            );
          }
        } else {
          // New question being added
          await apiService.addQuestionToPoll(int.parse(widget.pollId), savedQuestionData!); // Assert non-nullability
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Question added successfully!')),
            );
          }
        }
        await _fetchPollDetails(); // Refresh the poll details after update/add
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save question: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deleteQuestion(int questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.deleteQuestion(int.parse(widget.pollId), questionId);
        await _fetchPollDetails(); // Refresh the poll details after deletion
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete question: $e')),
          );
        }
      }
    }
  }
  // --- UI ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Poll')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Poll')),
        body: Center(child: Text('Error: $_errorMessage')),
      );
    }

    if (_poll == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Poll')),
        body: const Center(child: Text('Poll not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage: ${_poll!.title}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Poll ID: ${_poll!.id}', style: Theme.of(context).textTheme.bodySmall),
            Text('Access Code: ${_poll!.access_code}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Text('Questions', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Expanded(
              child: _poll!.questions.isEmpty
                  ? const Center(child: Text('No questions in this poll.'))
                  : ListView.builder(
                      itemCount: _poll!.questions.length,
                      itemBuilder: (context, index) {
                        final question = _poll!.questions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: Icon(_getIconForType(question.type)),
                            title: Text(question.text),
                            subtitle: Text('Type: ${question.type.name.replaceAll('_', ' ').toUpperCase()}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showQuestionFormDialog(
                                    type: question.type,
                                    questionToEdit: question,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteQuestion(question.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate back to the live session screen
                  context.pop(); 
                  // Or, if live session is a separate flow, navigate there directly.
                  // context.go('/poll/${widget.pollId}'); // Go to live session
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Live Session'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuestionFormDialog(type: app_models.QuestionType.multiple_choice), // Default to MC for now
        label: const Text('Add Question'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForType(app_models.QuestionType type) {
    switch (type) {
      case app_models.QuestionType.multiple_choice:
        return Icons.list_alt_rounded;
      case app_models.QuestionType.rating:
        return Icons.star_border_rounded;
      case app_models.QuestionType.open_ended:
        return Icons.short_text_rounded;
    }
  }
}