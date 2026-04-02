import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../screens/login_screen.dart';

import '../data/database/student_dao.dart';
import '../services/session_manager.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StudentDAO dao = StudentDAO();

    return Scaffold(
      body: Stack(
        children: [
          /// Background
          Positioned.fill(
            child: Image.asset('assets/MainScreens.jpeg', fit: BoxFit.cover),
          ),

          /// Soft overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.15)),
          ),

          SafeArea(
            child: Column(
              children: [
                /// Back button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.arrow_back,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                /// White card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// Text
                        const Text(
                          "Once you delete your account,\nit cannot be undone. All your\ndata will be permanently\nerased from this app.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),

                        const SizedBox(height: 28),

                        /// DELETE — BACKEND CONNECTED
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () async {
                              final email = SessionManager.currentEmail;

                              if (email == null || email.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("No logged user found."),
                                  ),
                                );
                                return;
                              }

                              try {
                                await dao.softDeleteAccountKeepRecords90Days(
                                  email,
                                );

                                if (!context.mounted) return;

                                // clear session
                                SessionManager.clear();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Account deleted. Income/Expense will be kept for 90 days.",
                                    ),
                                  ),
                                );

                                // go to login and remove previous screens
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Delete failed: $e")),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 10,
                              shadowColor: AppColors.primaryBlue.withOpacity(
                                0.45,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                            child: const Text(
                              "Delete",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// CANCEL
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.primaryBlue.withOpacity(0.35),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              backgroundColor: AppColors.primaryBlue
                                  .withOpacity(0.05),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
