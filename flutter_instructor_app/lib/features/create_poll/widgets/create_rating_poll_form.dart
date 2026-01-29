import 'package:flutter/material.dart';
import '../../../models/poll_models.dart' as app_models;

class CreateRatingPollForm extends StatefulWidget {
  final ValueChanged<({String questionText})> onSave;
  final app_models.Question? initialQuestion;

  const CreateRatingPollForm({
    super.key,
    required this.onSave,
    this.initialQuestion,
  });

  @override
  State<CreateRatingPollForm> createState() => _CreateRatingPollFormState();
}

class _CreateRatingPollFormState extends State<CreateRatingPollForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;

  // Using a Map for labels makes the structure clean and easy to maintain.
  static const Map<int, String> _ratingLabels = {
    1: "Not Satisfied",
    2: "Somewhat Dissatisfied",
    3: "Neutral",
    4: "Satisfied",
    5: "Very Satisfied",
  };

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.initialQuestion?.text ?? '');
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Poll Title Input
          TextFormField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: 'Rating Question',
              hintText: 'e.g., "How was the activity?"',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a question for the poll.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // 2. Rating Preview Section
          Text(
            "Rating Preview",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              // Using a Column of ListTiles for a clean vertical layout
              children: _ratingLabels.entries.map((entry) {
                return ListTile(
                  leading: Chip(
                    label: Text(
                      entry.key.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  title: Text(entry.value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16), 

          // 3. Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSave((
                    questionText: _questionController.text,
                  ));
                }
              },
              child: Text(widget.initialQuestion == null ? 'Add Question' : 'Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
