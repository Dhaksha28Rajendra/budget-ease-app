import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../data/database/expense_dao.dart';
import '../data/database/income_dao.dart';

class HistoryScreen extends StatefulWidget {
  final String studentId;

  const HistoryScreen({super.key, required this.studentId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _HistoryType { income, expense }

class _HistoryItem {
  final String title;
  final double amount;
  final DateTime date;
  final _HistoryType type;

  _HistoryItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ExpenseDAO _expenseDao = ExpenseDAO();
  final IncomeDao _incomeDao = IncomeDao();

  DateTime _currentMonth = DateTime.now();

  final List<_HistoryItem> _incomeItems = [];
  final List<_HistoryItem> _expenseItems = [];

  int _currentExpensePage = 0;
  static const int _pageSize = 6;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadHistoryForMonth();
  }

  // ================= LOAD DATA =================
  Future<void> _loadHistoryForMonth() async {
    _incomeItems.clear();
    _expenseItems.clear();
    _currentExpensePage = 0;

    final expenses = await _expenseDao.getAllExpensesByStudent(
      widget.studentId,
    );
    final incomes = await _incomeDao.getIncomeByStudent(widget.studentId);

    for (final e in expenses) {
      final date = DateTime.parse(e['Expense_date']);
      if (_isSameMonth(date)) {
        _expenseItems.add(
          _HistoryItem(
            title: e['Category_type'],
            amount: (e['Expense_amount'] as num).toDouble(),
            date: date,
            type: _HistoryType.expense,
          ),
        );
      }
    }

    for (final i in incomes) {
      final date = DateTime.parse(i.incomeDate);
      if (_isSameMonth(date)) {
        _incomeItems.add(
          _HistoryItem(
            title: i.sourceType,
            amount: i.incomeAmount,
            date: date,
            type: _HistoryType.income,
          ),
        );
      }
    }

    _incomeItems.sort((a, b) => b.date.compareTo(a.date));
    _expenseItems.sort((a, b) => b.date.compareTo(a.date));

    setState(() {});
  }

  bool _isSameMonth(DateTime date) {
    return date.year == _currentMonth.year && date.month == _currentMonth.month;
  }

  // ================= PAGINATION =================
  List<_HistoryItem> get _pagedExpenses {
    final start = _currentExpensePage * _pageSize;
    final end = start + _pageSize;

    if (start >= _expenseItems.length) return [];

    return _expenseItems.sublist(
      start,
      end > _expenseItems.length ? _expenseItems.length : end,
    );
  }

  int get _totalExpensePages => (_expenseItems.length / _pageSize).ceil();

  // ================= MONTH NAV =================
  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + offset,
      );
    });
    _loadHistoryForMonth();
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

  // ================= COLORS =================
  Color _bulletColor(_HistoryItem item) {
    if (item.type == _HistoryType.income) return Colors.green;
    if (item.title.startsWith('Essentials')) return Colors.red;
    if (item.title.startsWith('Leisure')) return Colors.orange;
    if (item.title.startsWith('Academics')) return Colors.blue;
    return Colors.purple;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/MainScreens.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              _calendar(),
              const SizedBox(height: 10),
              _legend(),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _sectionTitle("Income for the Month"),
                      _incomeList(),
                      const SizedBox(height: 20),
                      _sectionTitle("Expenses for the Month"),
                      _expenseList(),
                      _expensePagination(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const CircleAvatar(
            backgroundImage: AssetImage('assets/Intellects_Logo.png'),
          ),
          const SizedBox(width: 10),
          const Text(
            "History",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  // ================= CALENDAR =================
  Widget _calendar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          "${_monthName(_currentMonth.month)} ${_currentMonth.year}",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  // ================= LEGEND =================
  Widget _legend() {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      children: [
        _Legend(color: Colors.green, label: "Income"),
        _Legend(color: Colors.red, label: "Essentials"),
        _Legend(color: Colors.orange, label: "Leisure"),
        _Legend(color: Colors.blue, label: "Academics"),
        _Legend(color: Colors.purple, label: "Others"),
      ],
    );
  }

  // ================= SECTION TITLE =================
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  // ================= LISTS =================
  Widget _incomeList() {
    if (_incomeItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("No income transactions for this month."),
      );
    }

    return Column(children: _incomeItems.map(_historyTile).toList());
  }

  Widget _expenseList() {
    if (_pagedExpenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("No expense transactions for this month."),
      );
    }

    return Column(children: _pagedExpenses.map(_historyTile).toList());
  }

  Widget _historyTile(_HistoryItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _bulletColor(item),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Rs. ${item.amount.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "${item.date.day}/${item.date.month}/${item.date.year}",
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= PAGINATION =================
  Widget _expensePagination() {
    if (_totalExpensePages <= 1) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _currentExpensePage > 0
                ? () => setState(() => _currentExpensePage--)
                : null,
            child: const Text("Previous"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "Page ${_currentExpensePage + 1} of $_totalExpensePages",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: (_currentExpensePage + 1) < _totalExpensePages
                ? () => setState(() => _currentExpensePage++)
                : null,
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }
}

// ================= LEGEND WIDGET =================
class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
