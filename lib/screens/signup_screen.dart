import 'package:flutter/material.dart';
import 'package:relativeasy/services/auth_service.dart';
import 'package:relativeasy/utils/colors.dart';
import 'package:relativeasy/widgets/text_widget.dart';
import 'package:relativeasy/widgets/button_widget.dart';
import 'package:relativeasy/widgets/app_text_form_field.dart';
import 'package:relativeasy/screens/login_screen.dart';
import 'package:relativeasy/screens/main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.instance.signup(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        // Navigate to main screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to create account. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primary, background],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // App logo and title
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_fix_high,
                    size: 50,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextWidget(
                text: 'Create Account',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Join the relativity learning community',
                fontSize: 14,
                color: textSecondary,
                align: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Signup form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextFormField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    AppTextFormField(
                      controller: _emailController,
                      labelText: 'Email',
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    AppTextFormField(
                      controller: _passwordController,
                      labelText: 'Password',
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.text,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    AppTextFormField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      onEditingComplete: _signup,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      TextWidget(
                        text: _errorMessage!,
                        fontSize: 14,
                        color: errorRed,
                        align: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ButtonWidget(
                      label: 'Sign Up',
                      onPressed: _isLoading ? () {} : _signup,
                      color: accent,
                      textColor: textOnAccent,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextWidget(
                    text: 'Already have an account?',
                    fontSize: 14,
                    color: textSecondary,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: TextWidget(
                      text: 'Login',
                      fontSize: 14,
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
