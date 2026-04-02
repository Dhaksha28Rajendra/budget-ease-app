import 'package:flutter/material.dart';
import '../core/app_colors.dart';

import '../data/database/expense_dao.dart';
import '../data/database/budget_plan_dao.dart';

import 'essentials_screen.dart';
import 'leisure_screen.dart';
import 'academics_screen.dart';
import 'others_screen.dart';
import '../data/database/notification_dao.dart';

class AddExpenseScreen extends StatefulWidget {
  final String studentId;

  const AddExpenseScreen({super.key, required this.studentId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final ExpenseDAO _expenseDao = ExpenseDAO();
  final BudgetPlanDao _budgetPlanDao = BudgetPlanDao();
  final NotificationDao _notificationDao = NotificationDao();

  // ================= AMOUNTS =================
  double essentialsAmount = 0;
  double leisureAmount = 0;
  double academicsAmount = 0;
  double otherAmount = 0;

  double get totalExpense =>
      essentialsAmount + leisureAmount + academicsAmount + otherAmount;

  // ================= CALENDAR STATE =================
  DateTime currentMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();
  bool showFullMonth = false;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadExpensesFromDb();
  }

  // ================= LOAD EXPENSES =================
  Future<void> _loadExpensesFromDb() async {
    essentialsAmount = 0;
    leisureAmount = 0;
    academicsAmount = 0;
    otherAmount = 0;

    final rows = await _expenseDao.getAllExpensesByStudent(widget.studentId);

    for (final row in rows) {
      final date = DateTime.parse(row['Expense_date']);
      if (_dateOnly(date) != _dateOnly(selectedDate)) continue;

      final amount = (row['Expense_amount'] as num).toDouble();
      final category = row['Category_type'] as String;

      if (category.startsWith('Essentials')) {
        essentialsAmount += amount;
      } else if (category.startsWith('Leisure')) {
        leisureAmount += amount;
      } else if (category.startsWith('Academics')) {
        academicsAmount += amount;
      } else if (category.startsWith('Others')) {
        otherAmount += amount;
      }
    }

    setState(() {});
  }

  // ================= SAVE (FIXED) =================
  Future<void> _saveExpenses() async {
    await _loadExpensesFromDb();

    await _budgetPlanDao.insertOrUpdateExpense(
      studentId: widget.studentId,
      date: _dateOnly(selectedDate).toIso8601String().substring(0, 10),
      expenseAmount: totalExpense,
    );
    // 🔔 ADD NOTIFICATION
    await _notificationDao.insertNotification(
      studentId: widget.studentId,
      title: "Expense Added 💸",
      message: "",
      type: "expense",
      amount: totalExpense,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Expense saved: Rs. ${totalExpense.toStringAsFixed(2)}"),
      ),
    );
  }

  // ================= HELPERS =================
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + offset);
    });
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return now.year == currentMonth.year && now.month == currentMonth.month;
  }

  String _monthName(int month) => const [
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
  ][month - 1];

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/MainScreens.jpeg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _calendar(),
                  const SizedBox(height: 22),
                  _categoryGrid(),
                  const SizedBox(height: 24),
                  _totalExpenseSection(),
                  const SizedBox(height: 20),
                  _saveExpenseButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            "Add Expense",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ],
      ),
    );
  }

  // ================= CALENDAR (UNCHANGED) =================
  Widget _calendar() {
    final today = DateTime.now();
    final sunday = today.subtract(Duration(days: today.weekday % 7));

    final days = List.generate(
      showFullMonth
          ? DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month)
          : 7,
      (i) => showFullMonth
          ? DateTime(currentMonth.year, currentMonth.month, i + 1)
          : sunday.add(Duration(days: i)),
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Text("${_monthName(currentMonth.month)} ${currentMonth.year}"),
            if (!isCurrentMonth)
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text("SUN"),
            Text("MON"),
            Text("TUE"),
            Text("WED"),
            Text("THU"),
            Text("FRI"),
            Text("SAT"),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          children: days.map((date) {
            final isSelected = _dateOnly(date) == _dateOnly(selectedDate);
            return GestureDetector(
              onTap: () async {
                selectedDate = date;
                await _loadExpensesFromDb();
              },
              child: Container(
                margin: const EdgeInsets.all(6),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  "${date.day}",
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        IconButton(
          icon: Icon(
            showFullMonth ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
          onPressed: () => setState(() => showFullMonth = !showFullMonth),
        ),
      ],
    );
  }

  // ================= CATEGORY GRID =================
  Widget _categoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _categoryCard(
                title: "Essentials",
                image: "assets/Essentials.png",
                amount: essentialsAmount,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EssentialsScreen(studentId: widget.studentId),
                    ),
                  );
                  await _loadExpensesFromDb(); // ✅ FIX
                },
              ),
              _categoryCard(
                title: "Leisure",
                image: "assets/Leisure.png",
                amount: leisureAmount,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LeisureScreen(studentId: widget.studentId),
                    ),
                  );
                  await _loadExpensesFromDb(); // ✅ FIX
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _categoryCard(
                title: "Academics",
                image: "assets/Academics.png",
                amount: academicsAmount,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AcademicsScreen(studentId: widget.studentId),
                    ),
                  );
                  await _loadExpensesFromDb(); // ✅ FIX
                },
              ),
              _categoryCard(
                title: "Others",
                image: "assets/Others.png",
                amount: otherAmount,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OthersScreen(studentId: widget.studentId),
                    ),
                  );
                  await _loadExpensesFromDb(); // ✅ FIX
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryCard({
    required String title,
    required String image,
    required double amount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Image.asset(image, height: 70),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              "Rs. ${amount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalExpenseSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          const Text(
            "Total Expense",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            "Rs. ${totalExpense.toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveExpenseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ElevatedButton(
        onPressed: _saveExpenses,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "Save Expense",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
