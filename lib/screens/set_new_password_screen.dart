// lib/screens/set_new_password_screen.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SetNewPasswordScreen extends StatefulWidget {
  final String email; // ✅ REQUIRED

  const SetNewPasswordScreen({super.key, required this.email});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool showNew = false;
  bool showConfirm = false;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showError('All fields are required');
      return;
    }

    if (newPass != confirmPass) {
      _showError('Passwords do not match');
      return;
    }

    if (newPass.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    // 🔐 BACKEND CALL
    await _authService.resetPassword(email: widget.email, newPassword: newPass);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed successfully')),
    );

    // ✅ Go back to Login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // Background image fills the whole screen via decoration + BoxFit.cover
    return Scaffold(
      body: Stack(
        children: [
          // full-screen background
          Positioned.fill(
            child: Image.asset('assets/Background.png', fit: BoxFit.cover),
          ),

          // Foreground: safe area + scrollable content (avoids keyboard overflow)
          SafeArea(
            child: GestureDetector(
              // Dismiss keyboard when tapping outside fields
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                // add bottom padding equal to keyboard inset so content can scroll above keyboard
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    // keep column compact so it doesn't force full height
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),

                      Image.asset('assets/Intellects_Logo.png', height: 80),

                      const SizedBox(height: 24),

                      const Text(
                        'Set New Password',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Enter and confirm your new password',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.black),
                      ),

                      const SizedBox(height: 32),

                      _passwordField(
                        controller: newPasswordController,
                        hint: 'New Password',
                        show: showNew,
                        onToggle: () => setState(() => showNew = !showNew),
                      ),

                      const SizedBox(height: 16),

                      _passwordField(
                        controller: confirmPasswordController,
                        hint: 'Confirm Password',
                        show: showConfirm,
                        onToggle: () =>
                            setState(() => showConfirm = !showConfirm),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _savePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Save Password',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Add some spacing to allow comfortable scrolling above keyboard
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility : Icons.visibility_off,
            color: AppColors.primaryBlue,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.grey,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
