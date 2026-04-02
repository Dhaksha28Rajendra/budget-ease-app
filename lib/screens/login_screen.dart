// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

import '../services/auth_service.dart';
import '../data/models/student_model.dart';

// ✅ additions from profile-related version
import '../services/session_manager.dart';
import '../data/database/student_dao.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool showPassword = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _runRetentionCleanup();
  }

  Future<void> _runRetentionCleanup() async {
    try {
      await StudentDAO().purgeAfter90Days();
    } catch (e) {
      debugPrint('Retention cleanup failed: $e');
    }
  }

  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// =========================
  /// LOGIN FUNCTION
  /// =========================
  Future<void> _login() async {
    final user = userController.text.trim();
    final pass = passwordController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID and Password are required")),
      );
      return;
    }

    setState(() => isLoading = true);

    final StudentModel? student = await _authService.loginStudent(
      email: user,
      password: pass,
    );

    setState(() => isLoading = false);

    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email or password")),
      );
      return;
    }

    // ✅ added: store email for profile/session usage
    SessionManager.currentEmail = student.email;

    // ✅ MAIN CODE LOGIC PRESERVED → DASHBOARD WITH ARGS
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          fullName: '${student.firstName} ${student.lastName}',
          studentId: student.studentId,
          registrationDate: student.registrationDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use SizedBox.expand so Stack covers full screen.
    return Scaffold(
      // keep default resizeToAvoidBottomInset: true to let keyboard inset work
      body: GestureDetector(
        onTap: () =>
            FocusScope.of(context).unfocus(), // dismiss keyboard on tap outside
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Stack(
            children: [
              // FULL-SCREEN BACKGROUND IMAGE
              Positioned.fill(
                child: Image.asset(
                  'assets/Background.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

              // optional subtle overlay to increase contrast
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.03)),
              ),

              // MAIN CONTENT
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      // ensure scroll view knows about keyboard and can scroll above it
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: ConstrainedBox(
                        // force the scroll area to be at least screen height so background shows full
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              // make column fill vertical space (IntrinsicHeight + minHeight do that)
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 40),
                                Image.asset(
                                  'assets/Intellects_Logo.png',
                                  height: 90,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Budget Ease',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Spend Smart Today, Live Easy Tomorrow',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 32),

                                _buildField(
                                  controller: userController,
                                  hint: "User Email",
                                  icon: Icons.person_outline,
                                ),

                                const SizedBox(height: 16),

                                TextField(
                                  controller: passwordController,
                                  obscureText: !showPassword,
                                  decoration: InputDecoration(
                                    hintText: "BE Password",
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        showPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: AppColors.primaryBlue,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          showPassword = !showPassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: AppColors.grey,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Forgot Password?'),
                                ),

                                // Spacer — pushes the signup row to near the bottom
                                const Spacer(),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Don't have an account? "),
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
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
