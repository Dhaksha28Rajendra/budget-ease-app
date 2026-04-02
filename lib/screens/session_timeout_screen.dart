import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'login_screen.dart';

class SessionTimeoutScreen extends StatelessWidget {
  const SessionTimeoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND IMAGE
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// FOREGROUND CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// INTELLECTS LOGO
                  Image.asset('assets/Intellects_Logo.png', height: 100),

                  const SizedBox(height: 24),

                  /// TITLE
                  const Text(
                    'Session Time Out',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// DESCRIPTION
                  const Text(
                    'Your session has expired.\nTo protect your information, please log in again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.black),
                  ),

                  const SizedBox(height: 32),

                  /// LOG BACK IN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Log Back In',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// END SESSION BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // Exit app (will close browser tab in web)
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'End Session',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
