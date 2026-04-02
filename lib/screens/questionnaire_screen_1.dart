import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'questionnaire_screen_2.dart';
import 'get_started_screen.dart';

class QuestionnaireScreen1 extends StatefulWidget {
  final String fullName;
  final String studentId;
  final DateTime registrationDate; // ✅ REQUIRED

  const QuestionnaireScreen1({
    super.key,
    required this.fullName,
    required this.studentId,
    required this.registrationDate,
  });

  @override
  State<QuestionnaireScreen1> createState() => _QuestionnaireScreen1State();
}

class _QuestionnaireScreen1State extends State<QuestionnaireScreen1> {
  String? selectedAge;
  String? incomeRange;

  final Map<String, bool> incomeSources = {
    'Family support': false,
    'Mahapola / Bursary': false,
    'Part-time job': false,
    'Internship allowance': false,
    'Other': false,
  };

  bool get hasIncomeSourceSelected =>
      incomeSources.values.any((v) => v == true);

  void _validateAndProceed() {
    if (selectedAge == null) {
      _showError('Please select your age range');
      return;
    }

    if (!hasIncomeSourceSelected) {
      _showError('Please select at least one income source');
      return;
    }

    if (incomeRange == null) {
      _showError('Please select your income range');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionnaireScreen2(
          fullName: widget.fullName,
          studentId: widget.studentId,
          registrationDate: widget.registrationDate, // ✅ PASS FORWARD
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                  value: 0.33,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _card(
                          title: 'Q1: Age',
                          child: Column(
                            children: [
                              _ageRadio('18–20'),
                              _ageRadio('21–23'),
                              _ageRadio('24–25'),
                              _ageRadio('Above 25'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _card(
                          title: 'Q2: Main Source of Monthly Income',
                          child: Column(
                            children: incomeSources.keys.map((key) {
                              return CheckboxListTile(
                                value: incomeSources[key],
                                title: Text(key),
                                activeColor: AppColors.primaryBlue,
                                onChanged: (v) =>
                                    setState(() => incomeSources[key] = v!),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _card(
                          title: 'Q3: Average Monthly Income (LKR)',
                          child: Column(
                            children: [
                              _incomeRadio('Below 10,000'),
                              _incomeRadio('10,000 – 20,000'),
                              _incomeRadio('20,000 – 30,000'),
                              _incomeRadio('Above 30,000'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _bottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ageRadio(String value) => RadioListTile(
    title: Text(value),
    value: value,
    groupValue: selectedAge,
    activeColor: AppColors.primaryBlue,
    onChanged: (v) => setState(() => selectedAge = v.toString()),
  );

  Widget _incomeRadio(String value) => RadioListTile(
    title: Text(value),
    value: value,
    groupValue: incomeRange,
    activeColor: AppColors.primaryBlue,
    onChanged: (v) => setState(() => incomeRange = v.toString()),
  );

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
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

  Widget _bottomNav() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _validateAndProceed,
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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => GetStartedScreen(
                    fullName: widget.fullName,
                    studentId: widget.studentId,
                    registrationDate: widget.registrationDate, // ✅ FIXED HERE
                  ),
                ),
              );
            },
            child: const Text('Go Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
