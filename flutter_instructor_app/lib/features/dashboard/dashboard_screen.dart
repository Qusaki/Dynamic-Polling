import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import '../../models/poll_models.dart';
import '../../providers/poll_provider.dart';
import 'widgets/poll_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _showEditPollDialog(BuildContext context, WidgetRef ref, Poll poll) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: poll.title);
    final descriptionController = TextEditingController(text: poll.description);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Poll Details'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Poll Title', border: OutlineInputBorder()),
                validator: (value) => (value?.isEmpty ?? true) ? 'Title cannot be empty.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.updatePollDetails(
          poll.id,
          titleController.text,
          descriptionController.text,
        );
        await ref.refresh(pollsProvider); // More direct way to refetch
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poll details updated successfully!'))
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update poll details: $e'))
          );
        }
      }
    }
  }

  Future<void> _togglePollStatus(BuildContext context, WidgetRef ref, int pollId, bool isActive) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.updatePollStatus(pollId, isActive);
      ref.invalidate(pollsProvider); 
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollsAsyncValue = ref.watch(pollsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Polls'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final apiService = ref.read(apiServiceProvider);
              await apiService.logout();
              ref.invalidate(pollsProvider);
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: pollsAsyncValue.when(
          data: (polls) {
            // Sort polls by created_at in descending order (newest first)
            final sortedPolls = List<Poll>.from(polls)
              ..sort((a, b) => b.created_at.compareTo(a.created_at));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 24.0),
            itemCount: sortedPolls.length,
            itemBuilder: (context, index) {
              final poll = sortedPolls[index];
              return PollCard(
                title: poll.title,
                description: poll.description,
                status: poll.is_active ? 'Active' : 'Closed',
                date: DateFormat('yyyy-MM-dd HH:mm').format(poll.created_at),
                onTap: () async {
                  await context.push('/poll/${poll.id}');
                  ref.invalidate(pollsProvider);
                },
                onToggleStatus: (value) => _togglePollStatus(context, ref, poll.id, value),
                onViewResults: () => context.push('/poll/${poll.id}/results'),
                onEdit: () => _showEditPollDialog(context, ref, poll),
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: Text('Are you sure you want to delete the poll "${poll.title}"? This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                     try {
                      final apiService = ref.read(apiServiceProvider);
                      await apiService.deletePoll(poll.id);
                      await ref.refresh(pollsProvider); // Refresh the list
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Poll deleted successfully.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete poll: $e')),
                        );
                      }
                    }
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          if (err.toString().contains('Token expired or invalid')) {
            Future.microtask(() async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session expired. Please log in again.')),
              );
              final apiService = ref.read(apiServiceProvider);
              await apiService.logout();
              ref.invalidate(pollsProvider);
              if (context.mounted) {
                context.go('/login');
              }
            });
            return const Center(child: CircularProgressIndicator());
          }
          return Center(child: Text('Error: $err'));
        },
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-poll'),
        label: const Text('Create Poll'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}