import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../core/app_colors.dart';
import '../data/database/income_dao.dart';
import '../data/database/notification_dao.dart';
import '../data/database/month_end_plan_dao.dart';

class PredictionPlanScreen extends StatefulWidget {
  final String studentId;
  const PredictionPlanScreen({super.key, required this.studentId});

  @override
  State<PredictionPlanScreen> createState() => _PredictionPlanScreenState();
}

class _PredictionPlanScreenState extends State<PredictionPlanScreen> {
  final IncomeDao _incomeDao = IncomeDao();
  final NotificationDao _notificationDao = NotificationDao();
  final MonthEndPlanDao _monthDao = MonthEndPlanDao();

  bool _notificationSent = false;

  /// Loads:
  /// 1) current month total income
  /// 2) current month predicted percentages from Month_End_Plan
  Future<Map<String, dynamic>> _loadPredictionData() async {
    final total = await _incomeDao.getCurrentMonthTotalIncome(widget.studentId);

    // predicted % values saved in DB (Month_End_Plan)
    final perc = await _monthDao.getCurrentMonthPredictedPerc(widget.studentId);

    return {
      "total": total,
      "perc": perc, // Map<String,double>?
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadPredictionData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _buildNoDataState(context);
          }

          final data = snapshot.data!;
          final perc = data["perc"] as Map<String, double>?;
          final double total = (data["total"] as num?)?.toDouble() ?? 0.0;

          if (perc == null || total <= 0) {
            return _buildNoDataState(context);
          }

          // Raw predicted percentages
          double e = perc["Essentials"] ?? 0;
          double a = perc["Academics"] ?? 0;
          double l = perc["Leisure"] ?? 0;
          double o = perc["Others"] ?? 0;

          // Normalize to 100%
          final sum = e + a + l + o;
          if (sum <= 0) return _buildNoDataState(context);

          final factor = 100.0 / sum;
          e *= factor;
          a *= factor;
          l *= factor;
          o *= factor;

          // Progress values (0..1)
          final eP = e / 100.0;
          final aP = a / 100.0;
          final lP = l / 100.0;
          final oP = o / 100.0;

          // Amounts
          final essentialAmt = total * eP;
          final academicAmt = total * aP;
          final leisureAmt = total * lP;
          final otherAmt = total * oP;

          // 🔔 Notify once when plan is ready
          if (!_notificationSent) {
            _notificationSent = true;
            _notificationDao.insertNotification(
              studentId: widget.studentId,
              title: "Prediction Plan Ready 📊",
              message:
                  "Your personalized budget plan is now available. Start planning smartly!",
              type: "system",
              amount: 0,
            );
          }

          return Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildPieChartCard(total, e, a, l, o),
                      const SizedBox(height: 30),

                      _buildCategoryItem(
                        "Essentials (${e.toStringAsFixed(0)}%)",
                        eP,
                        essentialAmt,
                        const Color(0xFF6366F1),
                        Icons.shopping_bag,
                      ),

                      _buildCategoryItem(
                        "Academics (${a.toStringAsFixed(0)}%)",
                        aP,
                        academicAmt,
                        const Color(0xFF8B5CF6),
                        Icons.school,
                      ),

                      _buildCategoryItem(
                        "Leisure (${l.toStringAsFixed(0)}%)",
                        lP,
                        leisureAmt,
                        const Color(0xFFEC4899),
                        Icons.coffee,
                      ),

                      _buildCategoryItem(
                        "Other (${o.toStringAsFixed(0)}%)",
                        oP,
                        otherAmt,
                        const Color(0xFFF59E0B),
                        Icons.more_horiz,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= PIE CHART =================

  Widget _buildPieChartCard(
    double total,
    double e,
    double a,
    double l,
    double o,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text(
            "Allocation Overview",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 55,
                    sections: [
                      PieChartSectionData(
                        value: e, // ✅ percentage value
                        color: const Color(0xFF6366F1),
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: a,
                        color: const Color(0xFF8B5CF6),
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: l,
                        color: const Color(0xFFEC4899),
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: o,
                        color: const Color(0xFFF59E0B),
                        radius: 20,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      "Rs. ${total.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _legendItem("Essentials", const Color(0xFF6366F1)),
              _legendItem("Academics", const Color(0xFF8B5CF6)),
              _legendItem("Leisure", const Color(0xFFEC4899)),
              _legendItem("Other", const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ================= CATEGORY CARD =================

  Widget _buildCategoryItem(
    String title,
    double percent,
    double amt,
    Color color,
    IconData icon,
  ) {
    // Safety clamp (PercentIndicator requires 0..1)
    final p = percent.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
              Text("Rs. ${amt.toStringAsFixed(0)}"),
            ],
          ),
          const SizedBox(height: 10),
          LinearPercentIndicator(
            percent: p,
            progressColor: color,
            backgroundColor: Colors.grey[200]!,
            lineHeight: 8,
            barRadius: const Radius.circular(10),
            animation: true,
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.primaryBlue,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const Text(
              "Prediction Plan",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ================= NO DATA =================

  Widget _buildNoDataState(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const Expanded(
          child: Center(
            child: Text(
              "Add income / Run prediction to see plan",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
