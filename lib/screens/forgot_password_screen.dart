// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendCode() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showError('Email is required');
      return;
    }

    if (!isValidEmail(email)) {
      _showError('Enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _authService.sendResetOtp(email);

      if (!mounted) return;

      if (!success) {
        _showError('Email not registered');
        return;
      }

      // navigate to verify code screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyCodeScreen(email: email)),
      );
    } catch (e) {
      // show friendly error
      _showError('Failed to send code. Try again later.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use GestureDetector to dismiss keyboard when tapping outside
    return Scaffold(
      // keep background transparent if you want AppBar blending; here just use image
      body: Stack(
        children: [
          // Background image full screen
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Slight overlay if needed for contrast
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.02)),
          ),

          // Main content
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                // bottom padding ensures content scrolls above keyboard
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    // keeps layout comfortable on wide screens
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 40),
                        Image.asset('assets/Intellects_Logo.png', height: 80),
                        const SizedBox(height: 24),
                        const Text(
                          'Forgot Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Enter your email address.\nWe will send you a reset code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 32),

                        // Email field
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _sendCode(),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: AppColors.grey,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Send Code button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Send Code',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),

                        // give some bottom spacing so scroll shows nicely
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
