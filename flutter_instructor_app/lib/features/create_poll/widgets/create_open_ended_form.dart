import 'package:flutter/material.dart';
import '../../../models/poll_models.dart' as app_models;

class CreateOpenEndedForm extends StatefulWidget {
  final ValueChanged<({String questionText, int? wordLimit})> onSave;
  final app_models.Question? initialQuestion;

  const CreateOpenEndedForm({
    super.key,
    required this.onSave,
    this.initialQuestion,
  });

  @override
  State<CreateOpenEndedForm> createState() => _CreateOpenEndedFormState();
}

class _CreateOpenEndedFormState extends State<CreateOpenEndedForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  final _wordLimitController = TextEditingController(); // This can be kept as it is local state

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.initialQuestion?.text ?? '');
    // Word limit is not stored in the backend model, so we don't pre-fill it.
  }

  @override
  void dispose() {
    _questionController.dispose();
    _wordLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.2,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  TextFormField(
                    controller: _questionController,
                    decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()),
                    validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a question.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _wordLimitController,
                    decoration: const InputDecoration(labelText: 'Word Count Limit (Optional)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final int? wordLimit = int.tryParse(_wordLimitController.text);
                    widget.onSave((
                      questionText: _questionController.text,
                      wordLimit: wordLimit,
                    ));
                  }
                },
                child: Text(widget.initialQuestion == null ? 'Add Question' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
