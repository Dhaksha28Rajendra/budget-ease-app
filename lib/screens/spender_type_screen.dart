import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'dashboard_screen.dart';
import '../data/database/profile_update_dao.dart';

class SpenderTypeScreen extends StatelessWidget {
  final String spenderType; // impulsive | balanced | saver
  final String incomeType; // low | medium | high
  final String fullName;
  final String studentId;
  final DateTime registrationDate;

  const SpenderTypeScreen({
    super.key,
    required this.spenderType,
    required this.incomeType,
    required this.fullName,
    required this.studentId,
    required this.registrationDate,
  });

  @override
  Widget build(BuildContext context) {
    final data = _getSpenderData(spenderType);
    final incomeLabel = _getIncomeLabel(incomeType);

    return Scaffold(
      body: Stack(
        children: [
          /// FULL SCREEN IMAGE
          Positioned.fill(
            child: Image.asset(data.imagePath, fit: BoxFit.cover),
          ),

          /// Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                /// Title
                const Text(
                  "Your Financial Profile",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const Spacer(),

                /// RESULT CARD
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        data.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Income Type: $incomeLabel",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// GO TO DASHBOARD BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                     onPressed: () async {
  // ✅ 1) Save prediction to SQLite (Profile_Update table)
  await ProfileUpdateDAO().insertProfileUpdate(
    studentId: studentId,
    incomeType: incomeType,
    spenderType: spenderType,
    checkedAt: DateTime.now(),
  );

  print("✅ Profile saved to Profile_Update");

  // ✅ 2) Then go to Dashboard
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => DashboardScreen(
        fullName: fullName,
        studentId: studentId,
        registrationDate: registrationDate,
      ),
    ),
    (route) => false,
  );
},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        "Go to the Dashboard",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Spender Type → Image + Message
  _SpenderData _getSpenderData(String type) {
    switch (type) {
      case "impulsive":
        return _SpenderData(
          imagePath: "assets/ImpulsiveSpender.jpeg",
          message: "You are an Impulsive Spender",
        );
      case "balanced":
        return _SpenderData(
          imagePath: "assets/BalancedSpender.png",
          message: "You are a Balanced Spender",
        );
      case "saver":
      default:
        return _SpenderData(
          imagePath: "assets/MoneySavers.png",
          message: "You are a Saver",
        );
    }
  }

  /// Income Type Label
  String _getIncomeLabel(String type) {
    switch (type) {
      case "low":
        return "Low Income Person";
      case "medium":
        return "Medium Income Person";
      case "high":
      default:
        return "High Income Person";
    }
  }
}

class _SpenderData {
  final String imagePath;
  final String message;

  _SpenderData({required this.imagePath, required this.message});
}
