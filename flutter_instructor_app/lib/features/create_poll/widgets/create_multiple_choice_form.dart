import 'package:flutter/material.dart';
import '../../../models/poll_models.dart' as app_models;

class CreateMultipleChoiceForm extends StatefulWidget {
  final ValueChanged<({String questionText, List<String> options})> onSave;
  final app_models.Question? initialQuestion;

  const CreateMultipleChoiceForm({
    super.key,
    required this.onSave,
    this.initialQuestion,
  });

  @override
  State<CreateMultipleChoiceForm> createState() => _CreateMultipleChoiceFormState();
}

class _CreateMultipleChoiceFormState extends State<CreateMultipleChoiceForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  final List<TextEditingController> _optionControllers = [];

  @override
  void initState() {
    super.initState();
    // --- DEBUGGING ---
    print('--- CreateMultipleChoiceForm initState ---');
    print('Initial question text: ${widget.initialQuestion?.text}');
    print('Initial options count: ${widget.initialQuestion?.options.length}');
    print('Initial options: ${widget.initialQuestion?.options.map((o) => o.text).toList()}');
    print('------------------------------------');
    // --- END DEBUGGING ---
    
    _questionController = TextEditingController(text: widget.initialQuestion?.text ?? '');
    
    if (widget.initialQuestion != null && widget.initialQuestion!.options.isNotEmpty) {
      for (var option in widget.initialQuestion!.options) {
        _optionControllers.add(TextEditingController(text: option.text));
      }
    } else {
      // Start with at least one empty option for new questions
      _addOption();
    }
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    // Prevent removing the last option
    if (_optionControllers.length > 1) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make column shrink to its content
        children: [
          // The form fields are now direct children of the Column.
          // The parent SingleChildScrollView in the dialog will handle scrolling.
          TextFormField(
            controller: _questionController,
            decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()),
            validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a question.' : null,
          ),
          const SizedBox(height: 16),
          Text('Answer Choices', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._optionControllers.asMap().entries.map((entry) {
            int idx = entry.key;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(labelText: 'Option ${idx + 1}', border: const OutlineInputBorder()),
                      validator: (value) => (value?.isEmpty ?? true) ? 'Option cannot be empty.' : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeOption(idx),
                    color: Colors.red,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Option'),
            onPressed: _addOption,
          ),
          const SizedBox(height: 16), // Add some space
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSave((
                    questionText: _questionController.text,
                    options: _optionControllers.map((c) => c.text).where((s) => s.isNotEmpty).toList(),
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
