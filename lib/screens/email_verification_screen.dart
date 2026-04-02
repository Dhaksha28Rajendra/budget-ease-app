import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import 'get_started_screen.dart';
import 'register_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();

  final List<TextEditingController> controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    // ❌ Do NOT show OTP inside app anymore
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _resendCode() async {
    final success = await _authService.resendRegisterOtp(widget.email);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code sent to your email')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to resend code')));
    }
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  String get otp => controllers.map((c) => c.text.trim()).join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/Background.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mark_email_read,
                    size: 80,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Email Verification',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter the 4-digit verification code sent to your email',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (i) {
                      return SizedBox(
                        width: 60,
                        height: 60,
                        child: TextField(
                          controller: controllers[i],
                          focusNode: focusNodes[i],
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _onChanged(v, i),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        if (otp.length != 4) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter all 4 digits'),
                            ),
                          );
                          return;
                        }

                        final success = await _authService.verifyOtp(
                          email: widget.email,
                          enteredOtp: otp,
                        );

                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid verification code'),
                            ),
                          );
                          return;
                        }

                        final student = await _authService.getStudentByEmail(
                          widget.email,
                        );
                        if (student == null) return;

                        final fullName =
                            '${student.firstName} ${student.lastName}';
                        final studentId = student.studentId;
                        final DateTime registrationDate =
                            student.registrationDate;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GetStartedScreen(
                              fullName: fullName,
                              studentId: studentId,
                              registrationDate: registrationDate,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Verify Email',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _resendCode,
                        child: const Text(
                          'Resend Code',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
