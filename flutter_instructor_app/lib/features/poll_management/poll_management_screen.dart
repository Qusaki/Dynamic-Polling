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

  bool _hasMadeChanges = false;



  @override

  void initState() {

    super.initState();

    _fetchPollDetails();

  }



  Future<void> _fetchPollDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      // Now using the dedicated API endpoint to fetch a single poll by ID.
      final poll = await apiService.getPoll(int.parse(widget.pollId));
      if (mounted) {
        setState(() {
          _poll = poll;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load poll details: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }











  



    Future<void> _showEditPollDialog() async {



      if (_poll == null) return;



  



      final formKey = GlobalKey<FormState>();



      final titleController = TextEditingController(text: _poll!.title);



      final descriptionController = TextEditingController(text: _poll!.description);



  



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



  



      if (saved == true) {



        try {



          final apiService = ref.read(apiServiceProvider);



          final updatedPoll = await apiService.updatePollDetails(



            _poll!.id,



            titleController.text,



            descriptionController.text,



          );



          setState(() {



            _poll = updatedPoll;



            _hasMadeChanges = true;



          });



          if (mounted) {



            ScaffoldMessenger.of(context).showSnackBar(



              const SnackBar(content: Text('Poll details updated successfully!')),



            );



          }



        } catch (e) {



          if (mounted) {



            ScaffoldMessenger.of(context).showSnackBar(



              SnackBar(content: Text('Failed to update poll details: $e')),



            );



          }



        }



      }



    }



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



          body: Center(child: Text(_errorMessage!)),



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



          actions: [



            IconButton(



              icon: const Icon(Icons.edit),



              tooltip: 'Edit Poll Details',



              onPressed: _showEditPollDialog,



            ),



          ],



        ),



        body: _buildBody(),







      );



    }



  



    Widget _buildBody() {



      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),



        child: Column(



          crossAxisAlignment: CrossAxisAlignment.start,



          children: [



            Text('Poll ID: ${_poll!.id}', style: Theme.of(context).textTheme.bodySmall),



            Text('Access Code: ${_poll!.access_code}', style: Theme.of(context).textTheme.bodySmall),



            const SizedBox(height: 16),



            Text('Questions', style: Theme.of(context).textTheme.titleLarge),



            const Divider(),



            Expanded(



              child: ListView.builder(



                itemCount: _poll!.questions.length,



                itemBuilder: (context, index) {



                  final question = _poll!.questions[index];



                  return Card(



                    margin: const EdgeInsets.symmetric(vertical: 8.0),



                    child: ListTile(



                      leading: Icon(_getIconForType(question.type)),



                      title: Text(question.text),



                      subtitle: Text('Type: ${question.type.name.replaceAll('_', ' ').toUpperCase()}'),







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



                  context.pop(_hasMadeChanges);



                },



                icon: const Icon(Icons.arrow_back),



                label: const Text('Back to Live Session'),



                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),



              ),



            ),



            const SizedBox(height: 80),



          ],



        ),



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
