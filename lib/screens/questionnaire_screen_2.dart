import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'questionnaire_screen_3.dart';

class QuestionnaireScreen2 extends StatefulWidget {
  final String fullName;
  final String studentId;
  final DateTime registrationDate; // ✅ ADD THIS

  const QuestionnaireScreen2({
    super.key,
    required this.fullName,
    required this.studentId,
    required this.registrationDate, // ✅ REQUIRED
  });

  @override
  State<QuestionnaireScreen2> createState() => _QuestionnaireScreen2State();
}

class _QuestionnaireScreen2State extends State<QuestionnaireScreen2> {
  final Map<String, bool> expenseCategories = {
    'Essentials': false,
    'Leisure': false,
    'Academic': false,
    'Other': false,
  };

  String? trackingHabit;

  bool get hasCategorySelected {
    return expenseCategories.values.any((v) => v == true);
  }

  void _validateAndProceed() {
    if (!hasCategorySelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one expense category'),
        ),
      );
      return;
    }

    if (trackingHabit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your expense tracking habit'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionnaireScreen3(
          fullName: widget.fullName,
          studentId: widget.studentId,
          registrationDate: widget.registrationDate, // ✅ FIXED
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/Questionnaire.jpeg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                const LinearProgressIndicator(
                  value: 0.66,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _card(
                          title: 'Q4: Main Monthly Expense Categories',
                          child: Column(
                            children: expenseCategories.keys.map((key) {
                              return CheckboxListTile(
                                value: expenseCategories[key],
                                title: Text(key),
                                activeColor: AppColors.primaryBlue,
                                onChanged: (v) {
                                  setState(() {
                                    expenseCategories[key] = v!;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _card(
                          title: 'Q5: Do you usually track your expenses?',
                          child: Column(
                            children: [
                              _radio('Yes, regularly'),
                              _radio('Sometimes'),
                              _radio('Rarely'),
                              _radio('Never'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _bottomNav(
                  onNext: _validateAndProceed,
                  onBack: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _radio(String value) {
    return RadioListTile(
      title: Text(value),
      value: value,
      groupValue: trackingHabit,
      activeColor: AppColors.primaryBlue,
      onChanged: (v) {
        setState(() {
          trackingHabit = v.toString();
        });
      },
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _bottomNav({
    required VoidCallback onNext,
    required VoidCallback onBack,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Next Step',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          TextButton(
            onPressed: onBack,
            child: const Text('Go Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
