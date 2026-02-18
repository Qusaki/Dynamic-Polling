import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../providers/poll_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final apiService = ref.read(apiServiceProvider);
    bool isLoggedIn = false;

    try {
      if (_isRegistering) {
        bool registered = await apiService.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (registered) {
          isLoggedIn = await apiService.login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        }
      } else {
        isLoggedIn = await apiService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (mounted) {
      if (isLoggedIn == true) {
        ref.invalidate(pollsProvider);
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Failed. Please check your credentials.")), // Updated message
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Register' : 'Instructor Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _submit,
                        child: Text(_isRegistering ? 'Register' : 'Login'),
                      ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegistering = !_isRegistering;
                    });
                  },
                  child: Text(_isRegistering
                      ? 'Already have an account? Login'
                      : 'Create an account'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
