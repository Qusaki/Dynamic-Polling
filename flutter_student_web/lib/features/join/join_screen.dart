import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class JoinScreen extends ConsumerStatefulWidget {
  final String? initialCode;
  
  const JoinScreen({super.key, this.initialCode});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  late final TextEditingController _codeController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode);
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      // Auto-join if code is provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _joinPoll();
      });
    }
  }

  Future<void> _joinPoll() async {
    // We only validate if the form is actually visible/built, or just check the value directly for auto-join
    final code = _codeController.text.trim().toUpperCase();
    if (code.length < 4) {
       setState(() => _errorMessage = 'Code is too short');
       return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiService = ref.read(apiServiceProvider);

    try {
      // Validate code by fetching the poll first
      await apiService.getPollByAccessCode(code);
      
      if (mounted) {
        context.go('/vote/$code');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6750A4), Color(0xFFD0BCFF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.poll,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Dynamic Polling',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                         Text(
                          'Enter your access code to join.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                             color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'ACCESS CODE',
                            hintText: 'ABCD12',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a code';
                            }
                            if (value.length < 4) {
                              return 'Code is too short';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _joinPoll(),
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        FilledButton(
                          onPressed: _isLoading ? null : _joinPoll,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('JOIN SESSION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
