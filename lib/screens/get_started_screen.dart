import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'questionnaire_screen_1.dart';

class GetStartedScreen extends StatelessWidget {
  final String fullName;
  final String studentId;
  final DateTime registrationDate; // ✅ ADD THIS

  const GetStartedScreen({
    super.key,
    required this.fullName,
    required this.studentId,
    required this.registrationDate, // ✅ REQUIRED
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset('assets/GetStarted.jpeg', fit: BoxFit.cover),
          ),

          /// CONTENT
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                /// TEXT CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Spend Smart Today, Live Easy Tomorrow',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Treat your budget not as a restriction, but as a roadmap. Each planned expense is an investment in a future where your dreams don’t have to wait for your bank account to catch up.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// GET STARTED BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuestionnaireScreen1(
                              fullName: fullName,
                              studentId: studentId,
                              registrationDate:
                                  registrationDate, // ✅ PASS FORWARD
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
