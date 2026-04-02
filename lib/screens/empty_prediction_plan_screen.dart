import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../data/database/student_dao.dart';

class EmptyPredictionPlanScreen extends StatefulWidget {
  final String studentId;

  const EmptyPredictionPlanScreen({super.key, required this.studentId});

  @override
  State<EmptyPredictionPlanScreen> createState() =>
      _EmptyPredictionPlanScreenState();
}

class _EmptyPredictionPlanScreenState extends State<EmptyPredictionPlanScreen> {
  DateTime? registrationDate;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRegistrationDate();
  }

  Future<void> _loadRegistrationDate() async {
    try {
      final dao = StudentDAO();
      final dt = await dao.getRegistrationDate(widget.studentId);

      if (!mounted) return;

      if (dt == null) {
        setState(() {
          error = "Registration date not found (Created_at is empty).";
          loading = false;
        });
        return;
      }

      setState(() {
        registrationDate = dt;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day); // New

  int _getDaysRemaining() {
    if (registrationDate == null) return 30;

    final today = _dateOnly(DateTime.now());
    final regDay = _dateOnly(registrationDate!);

    final daysSinceRegistration = today.difference(regDay).inDays;
    final daysRemaining = 30 - daysSinceRegistration;

    if (daysRemaining < 0) return 0;
    if (daysRemaining > 30) return 30;
    return daysRemaining;
  } //New

  bool _isPredictionAvailable() {
    if (registrationDate == null) return false;

    final today = _dateOnly(DateTime.now());
    final regDay = _dateOnly(registrationDate!);

    final daysSinceRegistration = today.difference(regDay).inDays;
    return daysSinceRegistration >= 30;
  } //new

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _header(context),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text("Error:\n$error", textAlign: TextAlign.center),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final daysRemaining = _getDaysRemaining();
    const primaryBlue700 = Color(0xFF1D4ED8);
    const primaryBlue500 = Color(0xFF3B82F6);
    const primaryBlue600 = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _header(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildIllustrationContainer(primaryBlue700, primaryBlue500),
                    const SizedBox(height: 32),
                    _buildMainMessage(daysRemaining, primaryBlue700),
                    const SizedBox(height: 24),

                    if (!_isPredictionAvailable())
                      _buildDaysRemainingCard(
                        daysRemaining,
                        primaryBlue700,
                        primaryBlue500,
                      ),

                    const SizedBox(height: 32),

                    _buildInfoCard(
                      icon: Icons.calendar_today_outlined,
                      title: "30-Day Analysis",
                      description:
                          "We need at least 30 days of spending data to create accurate predictions.",
                      color: primaryBlue600,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.trending_up,
                      title: "Smart Predictions",
                      description:
                          "Our AI analyzes your spending patterns to suggest optimal budget allocations.",
                      color: primaryBlue600,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.layers_outlined,
                      title: "Category Breakdown",
                      description:
                          "You'll see predicted percentages for Essentials, Academics, Leisure & Other.",
                      color: primaryBlue600,
                    ),

                    const SizedBox(height: 24),
                    _buildEncouragementCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: AssetImage('assets/Intellects_Logo.png'),
          ),
          const SizedBox(width: 12),
          const Text(
            "Prediction Plan",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDEEBFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncouragementCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFFD97706),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Start Tracking Today!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Add your expenses regularly to get the most accurate predictions.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustrationContainer(Color blue700, Color blue500) {
    return SizedBox(
      width: 192,
      height: 192,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 192,
            height: 192,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDEEBFF), Color(0xFFEFF6FF)],
              ),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [blue700, blue500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: blue700.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.bar_chart, size: 56, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMessage(int daysRemaining, Color blue700) {
    return Column(
      children: [
        Text(
          _isPredictionAvailable()
              ? "Prediction Ready Soon!"
              : "Building Your Prediction Plan",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: blue700,
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "We're learning your spending habits to create a personalized budget prediction for you.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysRemainingCard(
    int daysRemaining,
    Color blue700,
    Color blue500,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [blue700, blue500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: blue700.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                daysRemaining.toString(),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  "days",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "until your prediction plan is ready",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFFE5E7EB)),
          ),
        ],
      ),
    );
  }
}
