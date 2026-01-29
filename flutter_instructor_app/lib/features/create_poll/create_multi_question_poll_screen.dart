import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import the correct models and providers
import '../../models/poll_models.dart' as app_models;
import '../../providers/poll_provider.dart';
import '../../services/api_service.dart';

// Import the sub-widgets
import 'widgets/create_multiple_choice_form.dart';
import 'widgets/create_rating_poll_form.dart';
import 'widgets/create_open_ended_form.dart';
import 'poll_success_screen.dart';


// --- 1. State Management ---
// The StateNotifier will now manage our list of app_models.Question
class PollBuilderNotifier extends StateNotifier<List<app_models.Question>> {
  PollBuilderNotifier() : super([]);

  void addQuestion(app_models.Question question) {
    // Re-assign order to ensure it's always sequential
    final orderedQuestion = app_models.Question(
      id: 0, // ID is 0 as it's not yet created in the backend
      text: question.text,
      type: question.type,
      options: question.options,
      order: state.length, // Assign order based on current list length
    );
    state = [...state, orderedQuestion];
  }

  void removeQuestion(int order) {
    state = state.where((q) => q.order != order).toList();
    // After removing, re-order the remaining questions to maintain sequential order.
    final reorderedState = <app_models.Question>[];
    for (var i = 0; i < state.length; i++) {
        final q = state[i];
        reorderedState.add(app_models.Question(
            id: q.id,
            text: q.text,
            type: q.type,
            options: q.options,
            order: i, // Re-assign order
        ));
    }
    state = reorderedState;
  }

  void updateQuestion(int order, app_models.Question updatedQuestion) {
    state = [
      for (final question in state)
        if (question.order == order)
          app_models.Question(
            id: updatedQuestion.id, // ID will be 0 for now
            text: updatedQuestion.text,
            type: updatedQuestion.type,
            options: updatedQuestion.options,
            order: order, // Ensure order is maintained
          )
        else
          question,
    ];
  }
}

// The Riverpod provider for our StateNotifier
final pollBuilderProvider = StateNotifierProvider<PollBuilderNotifier, List<app_models.Question>>((ref) {
  return PollBuilderNotifier();
});


// --- 2. Main Screen UI ---
class CreateMultiQuestionPollScreen extends ConsumerStatefulWidget {
  const CreateMultiQuestionPollScreen({super.key});

  @override
  ConsumerState<CreateMultiQuestionPollScreen> createState() => _CreateMultiQuestionPollScreenState();
}

class _CreateMultiQuestionPollScreenState extends ConsumerState<CreateMultiQuestionPollScreen> {

  final _titleController = TextEditingController();

  final _descriptionController = TextEditingController();

  bool _isSaving = false;



  @override

  void dispose() {

    _titleController.dispose();

    _descriptionController.dispose();

    super.dispose();

  }



  // --- 3. "Add Question" Actions ---

  void _showAddQuestionSheet() {

    showModalBottomSheet(

      context: context,

      builder: (ctx) {

        return Wrap(

          children: <Widget>[

            ListTile(

              leading: const Icon(Icons.list_alt_rounded),

              title: const Text('Add Multiple Choice'),

              onTap: () {

                Navigator.pop(ctx);

                _showQuestionFormDialog(type: app_models.QuestionType.multiple_choice);

              },

            ),

            ListTile(

              leading: const Icon(Icons.star_border_rounded),

              title: const Text('Add Rating (1-5)'),

              onTap: () {

                Navigator.pop(ctx);

                _showQuestionFormDialog(type: app_models.QuestionType.rating);

              },

            ),

            ListTile(

              leading: const Icon(Icons.short_text_rounded),

              title: const Text('Add Open-Ended'),

              onTap: () {

                Navigator.pop(ctx);

                _showQuestionFormDialog(type: app_models.QuestionType.open_ended);

              },

            ),

          ],

        );

      },

    );

  }



  // --- 4. Dynamic Question Forms (in Dialogs) ---

  void _showQuestionFormDialog({required app_models.QuestionType type, app_models.Question? questionToEdit}) {

    final isEditing = questionToEdit != null;



    showDialog(

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

                final newQuestion = app_models.Question(

                  id: 0,

                  order: isEditing ? questionToEdit.order : ref.read(pollBuilderProvider).length,

                  type: app_models.QuestionType.multiple_choice,

                  text: data.questionText,

                  options: data.options.map((o) => app_models.Option(id: 0, text: o)).toList(),

                );

                if (isEditing) {

                  ref.read(pollBuilderProvider.notifier).updateQuestion(questionToEdit.order, newQuestion);

                } else {

                  ref.read(pollBuilderProvider.notifier).addQuestion(newQuestion);

                }

                Navigator.pop(ctx);

              },

            );

            break;

          case app_models.QuestionType.rating:

             title = isEditing ? 'Edit Rating Question' : 'Add Rating Question';

            form = CreateRatingPollForm(

              initialQuestion: questionToEdit,

              onSave: (data) {

                final newQuestion = app_models.Question(

                  id: 0,

                  order: isEditing ? questionToEdit.order : ref.read(pollBuilderProvider).length,

                  type: app_models.QuestionType.rating,

                  text: data.questionText,

                  options: [],

                );

                if (isEditing) {

                  ref.read(pollBuilderProvider.notifier).updateQuestion(questionToEdit.order, newQuestion);

                } else {

                  ref.read(pollBuilderProvider.notifier).addQuestion(newQuestion);

                }

                Navigator.pop(ctx);

              },

            );

            break;

          case app_models.QuestionType.open_ended:

            title = isEditing ? 'Edit Open-Ended' : 'Add Open-Ended';

            form = CreateOpenEndedForm(

              initialQuestion: questionToEdit,

              onSave: (data) {

                final newQuestion = app_models.Question(

                  id: 0,

                  order: isEditing ? questionToEdit.order : ref.read(pollBuilderProvider).length,

                  type: app_models.QuestionType.open_ended,

                  text: data.questionText,

                  options: [],

                );

                if (isEditing) {

                  ref.read(pollBuilderProvider.notifier).updateQuestion(questionToEdit.order, newQuestion);

                } else {

                  ref.read(pollBuilderProvider.notifier).addQuestion(newQuestion);

                }

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

  }

  

  // --- 5. Save Poll Logic (Connected to Backend) ---

  void _savePoll() async {

    final title = _titleController.text;

    final description = _descriptionController.text;

    final questions = ref.read(pollBuilderProvider);



    if (title.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Please enter a poll title.')),

      );

      return;

    }

    if (questions.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Please add at least one question.')),

      );

      return;

    }



    setState(() => _isSaving = true);



    try {

      final apiService = ref.read(apiServiceProvider);

      final response = await apiService.createPoll(

        title,

        description.isNotEmpty ? description : null,

        questions,

      );



      // Invalidate the polls provider so the dashboard list is updated

      ref.invalidate(pollsProvider);



      final pollId = response['poll_id'].toString();

      final accessCode = response['access_code'];

      const studentAppBaseUrl = 'http://localhost:3000'; 

      final pollUrl = '$studentAppBaseUrl/join/$accessCode';



      if (mounted) {

        Navigator.of(context).pushReplacement(

          MaterialPageRoute(

            builder: (context) => PollSuccessScreen(

              pollUrl: pollUrl,

              pollId: pollId,

            ),

          ),

        );

      }



    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Error saving poll: ${e.toString()}')),

        );

      }

    } finally {

      if (mounted) {

        setState(() => _isSaving = false);

      }

    }

  }



  // --- 6. Build Method ---

  @override

  Widget build(BuildContext context) {

    final questions = ref.watch(pollBuilderProvider);



    return Scaffold(

      appBar: AppBar(

        title: const Text('Create New Poll'),

        actions: [

          if (_isSaving)

            const Padding(

              padding: EdgeInsets.all(16.0),

              child: SizedBox(

                height: 24,

                width: 24,

                child: CircularProgressIndicator(color: Colors.white),

              ),

            )

          else

            IconButton(

              onPressed: _savePoll,

              icon: const Icon(Icons.save),

              tooltip: 'Save Poll',

            ),

        ],

      ),

      body: Padding(

        padding: const EdgeInsets.all(16.0),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            // Header Section

            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Poll Title', border: OutlineInputBorder())),

            const SizedBox(height: 12),

            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder())),

            const Divider(height: 32),

            

            // Questions List

            Text('Questions', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 8),

            Expanded(

              child: questions.isEmpty

                  ? const Center(child: Text('No questions added yet.'))

                  : ListView.builder(

                      itemCount: questions.length,

                      itemBuilder: (context, index) {

                        final question = questions[index];

                        return Card(

                          margin: const EdgeInsets.symmetric(vertical: 6.0),

                          child: ListTile(

                            leading: Icon(_getIconForType(question.type)),

                            title: Text(question.text),

                            trailing: Row(

                              mainAxisSize: MainAxisSize.min,

                              children: [

                                IconButton(

                                  icon: const Icon(Icons.edit_outlined),

                                  tooltip: 'Edit Question',

                                  onPressed: () => _showQuestionFormDialog(type: question.type, questionToEdit: question),

                                ),

                                IconButton(

                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),

                                  tooltip: 'Remove Question',

                                  onPressed: () => ref.read(pollBuilderProvider.notifier).removeQuestion(question.order),

                                ),

                              ],

                            ),

                          ),

                        );

                      },

                    ),

            ),

            

            // "Add Question" Button

            const SizedBox(height: 16),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton.icon(

                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),

                onPressed: _showAddQuestionSheet,

                icon: const Icon(Icons.add),

                label: const Text('Add Question'),

              ),

            ),

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
