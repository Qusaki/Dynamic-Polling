import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/poll_provider.dart';
import 'widgets/poll_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
      body: pollsAsyncValue.when(
        data: (polls) => ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: polls.length,
          itemBuilder: (context, index) {
            final poll = polls[index];
            return PollCard(
              title: poll.title,
              status: poll.is_active ? 'Active' : 'Closed',
              date: 'N/A', // You might want to add a date to your poll model
              onTap: () => context.push('/poll/${poll.id}'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          // Check for the specific authentication error message.
          if (err.toString().contains('Token expired or invalid')) {
            // Schedule the logout and redirection logic to run after the build.
            Future.microtask(() async {
              // Show a snackbar message to the user.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session expired. Please log in again.')),
              );
              // Perform logout
              final apiService = ref.read(apiServiceProvider);
              await apiService.logout();
              ref.invalidate(pollsProvider);
              // Navigate to the login screen.
              if (context.mounted) {
                context.go('/login');
              }
            });
            // Show a loading indicator while redirecting.
            return const Center(child: CircularProgressIndicator());
          }
          // For any other errors, display the error message.
          return Center(child: Text('Error: $err'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-poll'),
        label: const Text('Create Poll'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}