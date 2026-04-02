// lib/screens/analytics_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../services/analytics_service.dart';
import '../screens/financial_summary_sheet.dart';
import '../main.dart';
import '../data/database/student_dao.dart';

class AnalyticsScreen extends StatefulWidget {
  final String studentId;
  const AnalyticsScreen({super.key, required this.studentId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

// ✅ NEW: RouteAware for auto refresh when user returns from Add Income/Expense
class _AnalyticsScreenState extends State<AnalyticsScreen> with RouteAware {
  final AnalyticsService _analyticsService = AnalyticsService();

  final StudentDAO _studentDAO = StudentDAO();
  String _pdfUserName = "User";
  String _pdfUserEmail = "";

  // ✅ DB loaded data
  double totalIncomeDB = 0;
  double totalExpenseDB = 0;
  Map<String, double> incomeBySourceDB = {};
  Map<String, double> expenseByCategoryDB = {};
  List<double> incomeDailyDB = [];
  List<double> expenseDailyDB = [];

  // ✅ NEW: Expense category-wise transaction counts (for PDF "Transactions" column)
  Map<String, int> expenseTxnCountByCategoryDB = {};

  bool isLoadingAnalytics = false;
  String? analyticsError;

  late DateTime currentMonth;
  late DateTime selectedMonth;

  // ---------------- INCOME ----------------
  final List<String> incomeCategories = const [
    "Parental Fund",
    "Mahapola / Bursary",
    "Part-time Job",
    "Internship",
    "Others",
  ];

  final List<Color> incomeColors = const [
    Color(0xFF9626BB), // Purple
    Color(0xFFA6BB26), // Lime Gold
    Color(0xFF1B8CB6), // Teal Blue
    Color(0xFFE0DD56), // Soft Yellow
    Color(0xFFE056C5), // Pink Violet
  ];

  bool _showIncomeMore = false;

  // Income ring tooltip state
  int? _incomeHoverIndex;
  Offset? _incomeHoverPos;

  // ---------------- EXPENSE ----------------
  final List<String> expenseCategories = const [
    "Leisure",
    "Academic",
    "Essential",
    "Other",
  ];

  final List<IconData> expenseIcons = const [
    Icons.sports_esports_rounded,
    Icons.menu_book_rounded,
    Icons.shopping_bag_rounded,
    Icons.category_rounded,
  ];

  final List<Color> expenseColors = const [
    Color(0xFF7C3AED), // Leisure
    Color(0xFF06B6D4), // Academic
    Color(0xFF2563EB), // Essential
    Color(0xFF64748B), // Other
  ];

  static const Color _trackLightGrey = Color(0xFFE8EAEE);

  // ---------------- Daily tooltip state (Line chart custom overlay) ----------------
  int? _dailyTipDay;
  Offset? _dailyTipPos;

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    selectedMonth = currentMonth;
    _loadMonthlyAnalytics();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final row = await _studentDAO.getStudentById(widget.studentId);
      if (row == null) return;

      final first = (row['First_name'] ?? '').toString().trim();
      final last = (row['Last_name'] ?? '').toString().trim();
      final email = (row['Email'] ?? '').toString().trim();

      setState(() {
        _pdfUserName = ("$first $last").trim();
        _pdfUserEmail = email;
      });
    } catch (_) {
      // ignore - keep defaults
    }
  }

  // ✅ NEW: Subscribe to global RouteObserver<PageRoute>
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  // ✅ NEW: When coming back from another screen -> reload analytics from DB
  @override
  void didPopNext() {
    _loadMonthlyAnalytics();
  }

  // ✅ NEW: Unsubscribe
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadMonthlyAnalytics() async {
    setState(() {
      isLoadingAnalytics = true;
      analyticsError = null;
    });

    try {
      final daysInMonth = DateUtils.getDaysInMonth(
        selectedMonth.year,
        selectedMonth.month,
      );

      final data = await _analyticsService.getMonthlyAnalytics(
        studentId: widget.studentId,
        year: selectedMonth.year,
        month: selectedMonth.month,
        daysInMonth: daysInMonth,
      );

      setState(() {
        totalIncomeDB = (data['totalIncome'] as num).toDouble();
        totalExpenseDB = (data['totalExpense'] as num).toDouble();

        incomeBySourceDB = Map<String, double>.from(data['incomeBySource']);
        expenseByCategoryDB = Map<String, double>.from(
          data['expenseByCategory'],
        );

        // ✅ NEW: store transaction count map safely
        final cnt = data['expenseTxnCountByCategory'];
        if (cnt is Map) {
          expenseTxnCountByCategoryDB = cnt.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          );
        } else {
          expenseTxnCountByCategoryDB = <String, int>{};
        }

        incomeDailyDB = List<double>.from(data['incomeDaily']);
        expenseDailyDB = List<double>.from(data['expenseDaily']);

        isLoadingAnalytics = false;
      });
    } catch (e) {
      setState(() {
        analyticsError = e.toString();
        isLoadingAnalytics = false;
      });
    }
  }

  // ---------------- Month navigation ----------------
  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
      _incomeHoverIndex = null;
      _incomeHoverPos = null;
      _showIncomeMore = false;
      _dailyTipDay = null;
      _dailyTipPos = null;
    });
    _loadMonthlyAnalytics();
  }

  void nextMonth() {
    if (selectedMonth.isBefore(currentMonth)) {
      setState(() {
        selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
        _incomeHoverIndex = null;
        _incomeHoverPos = null;
        _showIncomeMore = false;
        _dailyTipDay = null;
        _dailyTipPos = null;
      });
      _loadMonthlyAnalytics();
    }
  }

  bool get isCurrentMonth =>
      selectedMonth.year == currentMonth.year &&
      selectedMonth.month == currentMonth.month;

  String getMonthName(DateTime date) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return "${months[date.month - 1]} ${date.year}";
  }

  // ---------------- ✅ DB helpers ----------------
  double _incomeAmountFor(String category) => (incomeBySourceDB[category] ?? 0);
  double _expenseAmountFor(String category) =>
      (expenseByCategoryDB[category] ?? 0);

  double _incomePct(String category) {
    final total = totalIncomeDB;
    if (total <= 0) return 0.0;
    return _incomeAmountFor(category) / total;
  }

  double _expensePct(String category) {
    final total = totalExpenseDB;
    if (total <= 0) return 0.0;
    return _expenseAmountFor(category) / total;
  }

  // ---------------- UI helpers ----------------
  Widget _topicHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _monthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black),
            onPressed: previousMonth,
          ),
          Text(
            getMonthName(selectedMonth),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (!isCurrentMonth)
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.black),
              onPressed: nextMonth,
            ),
        ],
      ),
    );
  }

  // ===================== ✅ DETAILS (DB transactions modal) =====================

  void _openIncomeDetails(String sourceType) {
    // ✅ avoid opening when no amount
    if (_incomeAmountFor(sourceType) <= 0) return;

    final monthKey = DateFormat('yyyy-MM').format(selectedMonth);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _buildDetailsSheet(
          title: "$sourceType Income Details",
          future: _analyticsService.getIncomeTransactionsByMonthAndSource(
            studentId: widget.studentId,
            monthKey: monthKey,
            sourceType: sourceType,
          ),
        );
      },
    );
  }

  void _openExpenseDetails(String categoryType) {
    // ✅ avoid opening when no amount
    if (_expenseAmountFor(categoryType) <= 0) return;

    final monthKey = DateFormat('yyyy-MM').format(selectedMonth);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _buildDetailsSheet(
          title: "$categoryType Expense Details",
          future: _analyticsService.getExpenseTransactionsByMonthAndCategory(
            studentId: widget.studentId,
            monthKey: monthKey,
            categoryType: categoryType,
          ),

          // ✅ NEW: expense details la date pakkathula sub-category kaatu
          useSubCategoryForExpense: true,
        );
      },
    );
  }

  Widget _buildDetailsSheet({
    required String title,
    required Future<List<Map<String, dynamic>>> future,

    // ✅ NEW
    bool useSubCategoryForExpense = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 22,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }

                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "No transactions found in ${DateFormat('MMMM yyyy').format(selectedMonth)}.",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 16,
                      color: Colors.black.withOpacity(0.08),
                    ),
                    itemBuilder: (context, i) {
                      final row = list[i];

                      final dateStr = (row['date'] ?? '').toString();
                      final amountNum = (row['amount'] ?? 0);

                      // ✅ Income label (Parental Fund etc.)
                      final label = (row['label'] ?? '').toString();

                      final subCategoryRaw =
                          (row['subCategory'] ??
                                  row['Sub_category'] ??
                                  row['sub_category'] ??
                                  '')
                              .toString()
                              .trim();

                      // "Academics - Study Materials" -> "Study Materials"
                      final subCategory = subCategoryRaw.contains('-')
                          ? subCategoryRaw.split('-').last.trim()
                          : subCategoryRaw;

                      int amount;
                      if (amountNum is num) {
                        amount = amountNum.toInt();
                      } else {
                        amount = int.tryParse(amountNum.toString()) ?? 0;
                      }

                      String niceDate = dateStr;
                      try {
                        final dt = DateTime.parse(dateStr);
                        niceDate = DateFormat('dd MMM yyyy').format(dt);
                      } catch (_) {}

                      // ✅ UPDATED LOGIC:
                      // Expense -> show subCategory (fallback label)
                      // Income  -> show ONLY date (no label)
                      final rightText = useSubCategoryForExpense
                          ? (subCategory.isNotEmpty ? subCategory : label)
                          : "";

                      final subtitleText = rightText.isNotEmpty
                          ? "$niceDate • $rightText"
                          : niceDate;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        title: Text(
                          "Rs $amount",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          subtitleText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.65),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ===================== INCOME (PILL RING + TOOLTIP PERCENTAGE) =====================
  Widget _incomeBreakdownPillRingPro() {
    final totalIncome = totalIncomeDB.toInt();

    const ringSize = 170.0;
    const strokeWidth = 14.0;

    final pcts = incomeCategories.map(_incomePct).toList();
    final segments = List.generate(incomeCategories.length, (i) {
      return RingSegment(
        fraction: pcts[i].clamp(0.0, 1.0),
        color: incomeColors[i],
      );
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Total Income Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Income",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.70),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Rs $totalIncome",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Ring + list card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MouseRegion(
                        onExit: (_) => setState(() {
                          _incomeHoverIndex = null;
                          _incomeHoverPos = null;
                        }),
                        onHover: (event) {
                          final local = event.localPosition;
                          final idx = _hitTestRing(
                            localPos: local,
                            size: ringSize,
                            strokeWidth: strokeWidth,
                            segments: segments,
                          );

                          final prevPos = _incomeHoverPos;
                          final moved = prevPos == null
                              ? true
                              : (local - prevPos).distance > 6;

                          if (idx != _incomeHoverIndex || moved) {
                            setState(() {
                              _incomeHoverIndex = idx;
                              _incomeHoverPos = local;
                            });
                          }
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (d) {
                            final local = d.localPosition;
                            final idx = _hitTestRing(
                              localPos: local,
                              size: ringSize,
                              strokeWidth: strokeWidth,
                              segments: segments,
                            );
                            setState(() {
                              _incomeHoverIndex = idx;
                              _incomeHoverPos = local;
                            });
                          },
                          child: CategoryPillRingMulti(
                            size: ringSize,
                            strokeWidth: strokeWidth,
                            trackColor: _trackLightGrey,
                            segments: segments,
                          ),
                        ),
                      ),

                      // Center
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Income",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Rs $totalIncome",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      // Tooltip: ONLY percentage
                      if (_incomeHoverIndex != null && _incomeHoverPos != null)
                        _incomePercentTooltip(
                          ringSize: ringSize,
                          pos: _incomeHoverPos!,
                          percent: pcts[_incomeHoverIndex!] * 100,
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // list: color dot + name only
                Expanded(
                  child: Column(
                    children: List.generate(incomeCategories.length, (i) {
                      final c = incomeCategories[i];
                      final active = _incomeHoverIndex == i;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primaryBlue.withOpacity(0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active
                                ? AppColors.primaryBlue.withOpacity(0.18)
                                : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: incomeColors[i],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // View More / Show Less (Income)
          GestureDetector(
            onTap: () => setState(() => _showIncomeMore = !_showIncomeMore),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _showIncomeMore ? "Show Less" : "View More",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _showIncomeMore
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF1D4ED8),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (_showIncomeMore) _incomeCategoryCardsFromDB(),
        ],
      ),
    );
  }

  Widget _incomeCategoryCardsFromDB() {
    final total = totalIncomeDB;

    return Column(
      children: List.generate(incomeCategories.length, (i) {
        final cat = incomeCategories[i];
        final amount = _incomeAmountFor(cat);
        final pct = total <= 0 ? 0.0 : (amount / total);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: incomeColors[i].withOpacity(0.18)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CategoryPillRingSingle(
                        percent: pct.clamp(0.0, 1.0),
                        color: incomeColors[i],
                        size: 92,
                        strokeWidth: 12,
                        trackColor: _trackLightGrey,
                      ),
                      Text(
                        "${(pct * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Rs ${amount.toInt()}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (amount <= 0)
                        Text(
                          "No income received in this month",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.55),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // ✅ Real DB details
                IconButton(
                  tooltip: "More details",
                  onPressed: () => _openIncomeDetails(cat),
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: incomeColors[i],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _incomePercentTooltip({
    required double ringSize,
    required Offset pos,
    required double percent,
  }) {
    double left = pos.dx - 46;
    double top = pos.dy - 44;
    left = left.clamp(6.0, ringSize - 92);
    top = top.clamp(6.0, ringSize - 48);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Text(
            "${percent.toStringAsFixed(1)}%",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  int _hitTestRing({
    required Offset localPos,
    required double size,
    required double strokeWidth,
    required List<RingSegment> segments,
  }) {
    final center = Offset(size / 2, size / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    final radius = (size / 2) - (strokeWidth / 2);
    final minR = radius - strokeWidth;
    final maxR = radius + strokeWidth;

    if (dist < minR || dist > maxR) return _incomeHoverIndex ?? 0;

    final angle = math.atan2(dy, dx);
    final normalized =
        ((angle + (math.pi / 2)) % (2 * math.pi)) / (2 * math.pi);

    double acc = 0;
    for (int i = 0; i < segments.length; i++) {
      final frac = segments[i].fraction.clamp(0.0, 1.0);
      final start = acc;
      final end = acc + frac;
      if (frac > 0 && normalized >= start && normalized <= end) return i;
      acc = end;
    }

    return 0;
  }

  // ===================== EXPENSE BREAKDOWN (Quadrant) =====================
  Widget _expenseBreakdownQuadrant() {
    final totalExpense = totalExpenseDB.toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Expense",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.70),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Rs $totalExpense",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
            children: List.generate(expenseCategories.length, (i) {
              final category = expenseCategories[i];
              final amount = _expenseAmountFor(category);
              final pct = _expensePct(category);
              final pctText = (pct * 100).toStringAsFixed(1);
              final hasData = amount > 0;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: expenseColors[i].withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: expenseColors[i].withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(expenseIcons[i], color: expenseColors[i]),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Rs ${amount.toInt()}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: hasData ? Colors.black : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData ? "$pctText% of total" : "No records this month",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withOpacity(0.60),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: _trackLightGrey,
                        valueColor: AlwaysStoppedAnimation(expenseColors[i]),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Center(
                      child: TextButton(
                        onPressed: hasData
                            ? () => _openExpenseDetails(category)
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: hasData
                              ? expenseColors[i]
                              : Colors.grey,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          "More details",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ===================== MONTHLY COMPARISON (DB DAILY) =====================
  Widget _monthlyComparisonDailyScrollableLine() {
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedMonth.year,
      selectedMonth.month,
    );

    final incomeDailyLocal = (incomeDailyDB.length == daysInMonth)
        ? incomeDailyDB
        : List<double>.filled(daysInMonth, 0);

    final expenseDailyLocal = (expenseDailyDB.length == daysInMonth)
        ? expenseDailyDB
        : List<double>.filled(daysInMonth, 0);

    double maxVal = 0;
    for (int i = 0; i < daysInMonth; i++) {
      maxVal = math.max(maxVal, incomeDailyLocal[i]);
      maxVal = math.max(maxVal, expenseDailyLocal[i]);
    }

    double niceMaxY(double v) {
      final target = math.max(v * 1.15, 50000);
      final rounded = ((target / 10000).ceil() * 10000).toDouble();
      return rounded <= 0 ? 50000 : rounded;
    }

    final maxY = niceMaxY(maxVal);
    final yInterval = math.max(10000.0, maxY / 5);

    final incomeSpots = List<FlSpot>.generate(
      daysInMonth,
      (i) => FlSpot((i + 1).toDouble(), incomeDailyLocal[i]),
    );

    final expenseSpots = List<FlSpot>.generate(
      daysInMonth,
      (i) => FlSpot((i + 1).toDouble(), expenseDailyLocal[i]),
    );

    final chartWidth = math.max(360.0, daysInMonth * 24.0);

    String rsLabel(double v) {
      if (v >= 1000) return "Rs ${(v / 1000).toStringAsFixed(0)}k";
      return "Rs ${v.toInt()}";
    }

    final monthTitle = DateFormat('MMMM yyyy').format(selectedMonth);

    void hideDailyTooltip() {
      if (_dailyTipPos != null) {
        setState(() {
          _dailyTipDay = null;
          _dailyTipPos = null;
        });
      }
    }

    void showDailyTooltip(int day, Offset pos) {
      final idx = day - 1;
      if (idx < 0 || idx >= daysInMonth) {
        hideDailyTooltip();
        return;
      }

      final inc = incomeDailyLocal[idx];
      final exp = expenseDailyLocal[idx];

      if (inc <= 0 && exp <= 0) {
        hideDailyTooltip();
        return;
      }

      setState(() {
        _dailyTipDay = day;
        _dailyTipPos = pos;
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.78),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  monthTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                _miniLegendDot(label: "Income", color: AppColors.primaryBlue),
                const SizedBox(width: 10),
                _miniLegendDot(
                  label: "Expense",
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: chartWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 6,
                        right: 10,
                        top: 8,
                        bottom: 6,
                      ),
                      child: Stack(
                        children: [
                          LineChart(
                            LineChartData(
                              minX: 1,
                              maxX: daysInMonth.toDouble(),
                              clipData:
                                  const FlClipData.all(), // ✅ ADD  recent ah add panathu
                              minY: 0,
                              maxY: maxY,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: Colors.black.withOpacity(0.06),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 52,
                                    interval: yInterval,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                        ),
                                        child: Text(
                                          rsLabel(value),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black.withOpacity(
                                              0.55,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final day = value.toInt();
                                      if (day < 1 || day > daysInMonth) {
                                        return const SizedBox.shrink();
                                      }
                                      if (daysInMonth >= 28 && day % 2 != 0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          day.toString(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                handleBuiltInTouches: false,
                                touchCallback: (event, response) {
                                  if (!event.isInterestedForInteractions ||
                                      event.localPosition == null) {
                                    hideDailyTooltip();
                                    return;
                                  }

                                  if (response != null &&
                                      response.lineBarSpots != null &&
                                      response.lineBarSpots!.isNotEmpty) {
                                    final day = response.lineBarSpots!.first.x
                                        .toInt()
                                        .clamp(1, daysInMonth);
                                    showDailyTooltip(day, event.localPosition!);
                                    return;
                                  }

                                  final dx = event.localPosition!.dx;
                                  final ratio = (dx / chartWidth).clamp(
                                    0.0,
                                    1.0,
                                  );
                                  final day =
                                      (ratio * (daysInMonth - 1)).round() + 1;

                                  showDailyTooltip(
                                    day.clamp(1, daysInMonth),
                                    event.localPosition!,
                                  );
                                },
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: incomeSpots,
                                  isCurved: true,
                                  preventCurveOverShooting: true, // ✅ ADD
                                  preventCurveOvershootingThreshold:
                                      0.5, // ✅ TRY 0.5 (or 1.0)
                                  curveSmoothness:
                                      0.28, // ✅ your smoothness  last 3 lines
                                  barWidth: 3,
                                  color: AppColors.primaryBlue,
                                  dotData: FlDotData(
                                    show: true,
                                    checkToShowDot: (spot, barData) =>
                                        spot.y > 0,
                                  ),
                                  belowBarData: BarAreaData(show: false),
                                ),
                                LineChartBarData(
                                  spots: expenseSpots,
                                  isCurved: true,
                                  preventCurveOverShooting: true, // ✅ ADD
                                  preventCurveOvershootingThreshold:
                                      0.5, // ✅ TRY 0.5 (or 1.0)
                                  curveSmoothness:
                                      0.2, // ✅ your smoothness last 3 lines
                                  barWidth: 3,
                                  color: const Color(0xFFEF4444),
                                  dotData: FlDotData(
                                    show: true,
                                    checkToShowDot: (spot, barData) =>
                                        spot.y > 0,
                                  ),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          ),
                          if (_dailyTipPos != null && _dailyTipDay != null)
                            Positioned(
                              left: (_dailyTipPos!.dx - 90).clamp(
                                6.0,
                                chartWidth - 180,
                              ),
                              top: (_dailyTipPos!.dy - 70).clamp(6.0, 200.0),
                              child: IgnorePointer(
                                ignoring: true,
                                child: Container(
                                  width: 180,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.14),
                                        blurRadius: 16,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.06),
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (_) {
                                      final idx = _dailyTipDay! - 1;
                                      final inc = incomeDailyLocal[idx].toInt();
                                      final exp = expenseDailyLocal[idx]
                                          .toInt();
                                      final dateTxt = DateFormat('dd MMM')
                                          .format(
                                            DateTime(
                                              selectedMonth.year,
                                              selectedMonth.month,
                                              _dailyTipDay!,
                                            ),
                                          );

                                      return Text(
                                        "$dateTxt\nIncome: Rs $inc\nExpense: Rs $exp",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniLegendDot({required String label, required Color color}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.black.withOpacity(0.70),
          ),
        ),
      ],
    );
  }

  // ---------------- Screen ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  "assets/Intellects_Logo.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Analytics",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            tooltip: 'View Statement',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FinancialSummarySheet(
                    userName: _pdfUserName.isNotEmpty ? _pdfUserName : "User",
                    userId: _pdfUserEmail.isNotEmpty
                        ? _pdfUserEmail
                        : widget.studentId,
                    periodMonth: selectedMonth,
                    totalIncome: totalIncomeDB,
                    totalExpenses: totalExpenseDB,
                    incomeBySource: incomeBySourceDB,
                    expenseByCategory: expenseByCategoryDB,

                    // ✅ NEW: pass counts to PDF
                    expenseTxnCountByCategory: expenseTxnCountByCategoryDB,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/MainScreens.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _monthSelector(),

                if (isLoadingAnalytics)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),

                if (analyticsError != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      analyticsError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                _topicHeader("Income Breakdown"),
                _incomeBreakdownPillRingPro(),

                _topicHeader("Expense Breakdown"),
                _expenseBreakdownQuadrant(),

                _topicHeader("Monthly Comparison"),
                _monthlyComparisonDailyScrollableLine(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== Ring Widgets =====================
class RingSegment {
  final double fraction;
  final Color color;
  const RingSegment({required this.fraction, required this.color});
}

class CategoryPillRingMulti extends StatelessWidget {
  final List<RingSegment> segments;
  final double size;
  final double strokeWidth;
  final Color trackColor;

  const CategoryPillRingMulti({
    super.key,
    required this.segments,
    this.size = 210,
    this.strokeWidth = 18,
    this.trackColor = const Color(0xFFE8EAEE),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MultiRingPainter(
          segments: segments,
          strokeWidth: strokeWidth,
          trackColor: trackColor,
        ),
      ),
    );
  }
}

class _MultiRingPainter extends CustomPainter {
  final List<RingSegment> segments;
  final double strokeWidth;
  final Color trackColor;

  _MultiRingPainter({
    required this.segments,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - (strokeWidth / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    const startBase = -math.pi / 2;
    double start = startBase;

    for (final s in segments) {
      final frac = s.fraction.clamp(0.0, 1.0);
      if (frac <= 0) continue;

      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweep = 2 * math.pi * frac;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MultiRingPainter oldDelegate) {
    if (oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.segments.length != segments.length) {
      return true;
    }
    for (int i = 0; i < segments.length; i++) {
      if (oldDelegate.segments[i].fraction != segments[i].fraction ||
          oldDelegate.segments[i].color != segments[i].color) {
        return true;
      }
    }
    return false;
  }
}

class CategoryPillRingSingle extends StatelessWidget {
  final double percent; // 0..1
  final Color color;
  final double size;
  final double strokeWidth;
  final Color trackColor;

  const CategoryPillRingSingle({
    super.key,
    required this.percent,
    required this.color,
    this.size = 92,
    this.strokeWidth = 12,
    this.trackColor = const Color(0xFFE8EAEE),
  });

  @override
  Widget build(BuildContext context) {
    final p = percent.clamp(0.0, 1.0);
    return CustomPaint(
      painter: _SingleRingPainter(
        percent: p,
        color: color,
        strokeWidth: strokeWidth,
        trackColor: trackColor,
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

class _SingleRingPainter extends CustomPainter {
  final double percent;
  final Color color;
  final double strokeWidth;
  final Color trackColor;

  _SingleRingPainter({
    required this.percent,
    required this.color,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - (strokeWidth / 2);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * percent, false, fill);
  }

  @override
  bool shouldRepaint(covariant _SingleRingPainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.trackColor != trackColor;
}
