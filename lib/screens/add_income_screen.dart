import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../data/database/income_dao.dart';
import '../data/models/income_model.dart';
import '../data/database/notification_dao.dart';

class AddIncomeScreen extends StatefulWidget {
  final String studentId;

  const AddIncomeScreen({super.key, required this.studentId});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final IncomeDao _incomeDao = IncomeDao();
  final NotificationDao _notificationDao = NotificationDao();
  DateTime currentMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();
  bool showFullMonth = false;

  final List<String> incomeCategories = [
    'Parental Fund',
    "Mahapola / Bursary",
    'Part-time Job',
    'Internship',
    'Other',
  ];

  final List<_IncomeEntry> incomeEntries = [_IncomeEntry()];
  final List<IncomeModel> _monthlyIncome = [];

  double totalIncome = 0;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadMonthlyIncome();
  }

  // ================= LOAD MONTHLY INCOME =================
  Future<void> _loadMonthlyIncome() async {
    final allIncome = await _incomeDao.getIncomeByStudent(widget.studentId);

    _monthlyIncome.clear();
    totalIncome = 0;

    for (final income in allIncome) {
      final date = DateTime.parse(income.incomeDate);
      if (date.year == currentMonth.year && date.month == currentMonth.month) {
        _monthlyIncome.add(income);
        totalIncome += income.incomeAmount;
      }
    }

    _monthlyIncome.sort((a, b) => b.incomeDate.compareTo(a.incomeDate));

    setState(() {});
  }

  // ================= SAVE =================
  Future<void> _saveIncome() async {
    for (final entry in incomeEntries) {
      final amount = double.tryParse(entry.amountController.text);

      if (entry.category != null && amount != null && amount > 0) {
        // Save income
        await _incomeDao.insertIncome(
          IncomeModel(
            studentId: widget.studentId,
            sourceType: entry.category!,
            incomeAmount: amount,
            incomeDate: _dateOnly(
              selectedDate,
            ).toIso8601String().substring(0, 10),
          ),
        );

        // 🔔 Insert notification immediately after saving
        await _notificationDao.insertNotification(
          studentId: widget.studentId,
          title: "Income Added 💰",
          message: "",
          type: "income",
          income_source: entry.category,
          amount: amount,
        );
      }
    }

    // Reset form after everything is saved
    incomeEntries
      ..clear()
      ..add(_IncomeEntry());

    await _loadMonthlyIncome();
  }

  // ================= EDIT / DELETE =================
  void _openEditDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit / Delete Income"),
        content: SizedBox(
          width: double.maxFinite,
          child: _monthlyIncome.isEmpty
              ? const Text("No income recorded for this month.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _monthlyIncome.length,
                  itemBuilder: (_, i) {
                    final income = _monthlyIncome[i];
                    return ListTile(
                      title: Text(income.sourceType),
                      subtitle: Text(
                        "Rs. ${income.incomeAmount.toStringAsFixed(2)}",
                      ),
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
                                    "Do you want to edit this income entry?",
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
                                Navigator.pop(
                                  context,
                                ); // close main list dialog
                                _editIncome(income);
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
                                    "Are you sure you want to delete this income entry?",
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
                                await _incomeDao.deleteIncome(income.incomeId!);
                                Navigator.pop(context); // close main dialog
                                await _loadMonthlyIncome();
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

  void _editIncome(IncomeModel income) {
    final controller = TextEditingController(
      text: income.incomeAmount.toString(),
    );
    String category = income.sourceType;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Income"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: category,
              items: incomeCategories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
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
                await _incomeDao.deleteIncome(income.incomeId!);
                await _incomeDao.insertIncome(
                  IncomeModel(
                    studentId: widget.studentId,
                    sourceType: category,
                    incomeAmount: amount,
                    incomeDate: income.incomeDate,
                  ),
                );
                Navigator.pop(context);
                await _loadMonthlyIncome();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
                _incomeForm(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveIncome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: const Text(
                      "Save Income",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _openEditDeleteDialog,
                  child: const Text("Edit / Delete Income"),
                ),
                const SizedBox(height: 20),
                _totalIncome(),
                const SizedBox(height: 20),
                _recentIncome(),
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
            "Add Income",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ],
      ),
    );
  }

  // ================= CALENDAR =================
  // ================= CALENDAR HELPERS =================
  void _changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + offset);
    });
    _loadMonthlyIncome();
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return now.year == currentMonth.year && now.month == currentMonth.month;
  }

  void _onDateTap(DateTime date) {
    setState(() {
      selectedDate = date;
    });

    final incomesForDay = _monthlyIncome.where((income) {
      final d = DateTime.parse(income.incomeDate);
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();

    if (incomesForDay.isEmpty) {
      _showNoIncomeDialog(date);
    } else {
      _showIncomeDialog(incomesForDay);
    }
  }

  void _showNoIncomeDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${date.day}/${date.month}/${date.year}"),
        content: const Text("You did not receive any income on this date."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showIncomeDialog(List<IncomeModel> items) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Income Received"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: items
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.sourceType)),
                      Text("Rs. ${e.incomeAmount.toStringAsFixed(2)}"),
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
  Widget _incomeForm() {
    return Column(children: incomeEntries.map(_incomeRow).toList());
  }

  Widget _incomeRow(_IncomeEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // -------- CATEGORY --------
          DropdownButtonFormField<String>(
            value: entry.category,
            hint: const Text("Category"),
            items: incomeCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => entry.category = v,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // -------- AMOUNT --------
          TextField(
            controller: entry.amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              hintText: "Amount",
              prefixText: "Rs. ",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalIncome() {
    return Text(
      "Total Income  Rs. ${totalIncome.toStringAsFixed(2)}",
      style: const TextStyle(
        color: AppColors.primaryBlue,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _recentIncome() {
    final recent = _monthlyIncome.take(5).toList();
    if (recent.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Income",
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
                    e.sourceType,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  "Rs. ${e.incomeAmount.toStringAsFixed(2)}",
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

// ================= MODEL =================
class _IncomeEntry {
  String? category;
  final TextEditingController amountController = TextEditingController();
}
