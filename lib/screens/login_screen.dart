import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:relativeasy/services/auth_service.dart';
import 'package:relativeasy/utils/colors.dart';
import 'package:relativeasy/widgets/text_widget.dart';
import 'package:relativeasy/widgets/button_widget.dart';
import 'package:relativeasy/widgets/app_text_form_field.dart';
import 'package:relativeasy/screens/signup_screen.dart';
import 'package:relativeasy/screens/main_screen.dart';
import 'package:relativeasy/widgets/forgot_password_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.instance.login(
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
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
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
              const SizedBox(height: 80),
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
                text: 'Relativeasy',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Master Special Relativity',
                fontSize: 14,
                color: textSecondary,
                align: TextAlign.center,
              ),
              const SizedBox(height: 60),
              // Login form
              Form(
                key: _formKey,
                child: Column(
                  children: [
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
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    // Forgot Password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                showForgotPasswordDialog(context);
                              },
                        child: TextWidget(
                          text: 'Forgot Password?',
                          fontSize: 14,
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                      label: 'Login',
                      onPressed: _isLoading ? () {} : _login,
                      color: accent,
                      textColor: textOnAccent,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextWidget(
                    text: "Don't have an account?",
                    fontSize: 14,
                    color: textSecondary,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: TextWidget(
                      text: 'Sign up',
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
