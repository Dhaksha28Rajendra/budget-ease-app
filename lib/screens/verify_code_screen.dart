import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import 'set_new_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController codeController = TextEditingController();

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _verifyCode() async {
    final code = codeController.text.trim();

    if (code.length != 4) {
      _showError('Please enter the full 4-digit code');
      return;
    }

    final isValid = await _authService.verifyResetOtp(
      email: widget.email,
      enteredOtp: code,
    );

    if (!mounted) return;

    if (!isValid) {
      _showError('Invalid or expired verification code');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SetNewPasswordScreen(email: widget.email),
      ),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Image.asset('assets/Intellects_Logo.png', height: 80),

                  const SizedBox(height: 24),

                  const Text(
                    'Verify Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Enter the 4-digit code sent to your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),

                  const SizedBox(height: 32),

                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      filled: true,
                      fillColor: AppColors.grey,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                      letterSpacing: 8,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Verify',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
