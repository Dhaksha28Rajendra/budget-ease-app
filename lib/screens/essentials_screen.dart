import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../data/database/expense_dao.dart';
import '../data/database/notification_dao.dart';

class EssentialsScreen extends StatefulWidget {
  final String studentId;

  const EssentialsScreen({super.key, required this.studentId});

  @override
  State<EssentialsScreen> createState() => _EssentialsScreenState();
}

class _EssentialsScreenState extends State<EssentialsScreen> {
  final ExpenseDAO _expenseDAO = ExpenseDAO();

  DateTime currentMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();
  bool showFullMonth = false;

  final List<String> subCategories = [
    'Food',
    'Hostel Fees',
    'Transport',
    'Mobile Bill',
    'Healthcare',
    'Self Care',
  ];

  final List<_EssentialEntry> entries = [_EssentialEntry()];
  final List<_RecentEssential> _monthlyEssentials = [];

  double totalEssentials = 0;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadMonthlyEssentials();
  }

  // ================= LOAD MONTHLY ESSENTIALS =================
  Future<void> _loadMonthlyEssentials() async {
    final allExpenses = await _expenseDAO.getAllExpensesByStudent(
      widget.studentId,
    );

    _monthlyEssentials.clear();
    totalEssentials = 0;

    for (final e in allExpenses) {
      if (!(e['Category_type'] as String).startsWith('Essentials')) continue;

      final date = DateTime.parse(e['Expense_date']);

      if (date.year == currentMonth.year && date.month == currentMonth.month) {
        _monthlyEssentials.add(
          _RecentEssential(
            id: e['Expense_id'],
            date: date,
            category: (e['Category_type'] as String).replaceFirst(
              'Essentials - ',
              '',
            ),
            amount: (e['Expense_amount'] as num).toDouble(),
          ),
        );

        totalEssentials += (e['Expense_amount'] as num).toDouble();
      }
    }

    _monthlyEssentials.sort((a, b) => b.date.compareTo(a.date));
    setState(() {});
  }

  // ================= SAVE =================
  Future<void> _saveEssentials() async {
    for (final e in entries) {
      final amount = double.tryParse(e.amountController.text);

      if (e.category != null && amount != null && amount > 0) {
        await _expenseDAO.insertExpense(
          studentId: widget.studentId,
          category: 'Essentials - ${e.category}',
          amount: amount,
          date: _dateOnly(selectedDate).toIso8601String().substring(0, 10),
        );

        await NotificationDao().insertNotification(
          studentId: widget.studentId,
          title: "Expense Added 💸",
          message: "Your expense has been added successfully.",
          type: "expense",
          category: "Essentials - ${e.category}",
          amount: amount,
        );
      }
    }

    entries
      ..clear()
      ..add(_EssentialEntry());

    await _loadMonthlyEssentials();
  }

  // ================= EDIT / DELETE =================
  void _openEditDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit / Delete Essentials"),
        content: SizedBox(
          width: double.maxFinite,
          child: _monthlyEssentials.isEmpty
              ? const Text("No essentials recorded for this month.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _monthlyEssentials.length,
                  itemBuilder: (_, i) {
                    final e = _monthlyEssentials[i];
                    return ListTile(
                      title: Text(e.category),
                      subtitle: Text("Rs. ${e.amount.toStringAsFixed(2)}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.primaryBlue,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Confirm Edit"),
                                  content: const Text(
                                    "Do you want to edit this expense?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Edit"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                Navigator.pop(context);
                                _editEssential(e);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Confirm Delete"),
                                  content: const Text(
                                    "Are you sure you want to delete this expense?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _expenseDAO.deleteExpense(e.id);
                                Navigator.pop(context);
                                await _loadMonthlyEssentials();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _editEssential(_RecentEssential e) {
    final controller = TextEditingController(text: e.amount.toString());
    String category = e.category;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Essential"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: category,
              items: subCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => category = v!,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: "Rs. "),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                await _expenseDAO.deleteExpense(e.id);
                await _expenseDAO.insertExpense(
                  studentId: widget.studentId,
                  category: 'Essentials - $category',
                  amount: amount,
                  date: e.date.toIso8601String().substring(0, 10),
                );
                Navigator.pop(context);
                await _loadMonthlyEssentials();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ================= CALENDAR HELPERS =================
  void _changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + offset);
    });
    _loadMonthlyEssentials();
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return now.year == currentMonth.year && now.month == currentMonth.month;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _onDateTap(DateTime date) {
    setState(() {
      selectedDate = date;
    });

    final list = _monthlyEssentials.where((e) {
      return _dateOnly(e.date) == _dateOnly(date);
    }).toList();

    if (list.isEmpty) {
      _showNoEssentialsDialog(date);
    } else {
      _showEssentialsDialog(list);
    }
  }

  void _showNoEssentialsDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${date.day}/${date.month}/${date.year}"),
        content: const Text("No essential expenses recorded on this date."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showEssentialsDialog(List<_RecentEssential> items) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Essential Expenses"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: items
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.category)),
                      Text("Rs. ${e.amount.toStringAsFixed(2)}"),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _header(),
                const SizedBox(height: 20),
                _calendar(),
                const SizedBox(height: 24),
                _essentialsForm(),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _saveEssentials,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: const Text(
                    "Save Expense",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: _openEditDeleteDialog,
                  child: const Text("Edit / Delete Essentials"),
                ),
                const SizedBox(height: 20),
                _totalEssentials(),
                const SizedBox(height: 20),
                _recentEssentials(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
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
            "Essentials",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ],
      ),
    );
  }

  // ================= CALENDAR =================
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
              onTap: () => _onDateTap(date),
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

  // ================= FORM =================
  Widget _essentialsForm() {
    return Column(children: entries.map(_essentialRow).toList());
  }

  Widget _essentialRow(_EssentialEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: entry.category,
              hint: const Text("Category"),
              items: subCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => entry.category = v,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextField(
              controller: entry.amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Amount",
                prefixText: "Rs. ",
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalEssentials() {
    return Text(
      "Total Essentials  Rs. ${totalEssentials.toStringAsFixed(2)}",
      style: const TextStyle(
        color: AppColors.primaryBlue,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _recentEssentials() {
    final recent = _monthlyEssentials.take(5).toList();
    if (recent.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Essentials",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        ...recent.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.category,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  "Rs. ${e.amount.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
}

// ================= MODELS =================
class _EssentialEntry {
  String? category;
  final TextEditingController amountController = TextEditingController();
}

class _RecentEssential {
  final int id;
  final DateTime date;
  final String category;
  final double amount;

  _RecentEssential({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
  });
}
