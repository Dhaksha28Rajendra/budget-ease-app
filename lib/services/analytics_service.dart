import 'package:flutter/foundation.dart';
import '../repositories/analytics_repository.dart';

class AnalyticsService {
  final AnalyticsRepository _repo = AnalyticsRepository();

  Future<Map<String, dynamic>> getMonthlyAnalytics({
    required String studentId,
    required int year,
    required int month,
    required int daysInMonth,
  }) async {
    // ✅ IMPORTANT FIX:
    // Use transaction rows (Income_amount/Income_date, Expense_amount/Expense_date)
    final incomes = await _repo.getIncomeTransactionsByMonth(
      studentId: studentId,
      year: year,
      month: month,
    );

    final expenses = await _repo.getExpenseTransactionsByMonth(
      studentId: studentId,
      year: year,
      month: month,
    );

    debugPrint("DBG: income txns count = ${incomes.length}");
    debugPrint("DBG: expense txns count = ${expenses.length}");

    double totalIncome = 0;
    double totalExpense = 0;

    final Map<String, double> incomeBySource = {};
    final Map<String, double> expenseByCategory = {};

    // ✅ PDF "Transactions" column ku (category-wise count)
    final Map<String, int> expenseTxnCountByCategory = {};

    final List<double> incomeDaily = List<double>.filled(daysInMonth, 0);
    final List<double> expenseDaily = List<double>.filled(daysInMonth, 0);

    // ------------------ INCOME LOOP ------------------
    for (final row in incomes) {
      final raw = (row['Source_type'] ?? 'Others').toString();
      final source = (raw == 'Other') ? 'Others' : raw; // normalize

      final amtRaw = row['Income_amount'] ?? 0;
      final amount = (amtRaw is num)
          ? amtRaw.toDouble()
          : double.tryParse(amtRaw.toString()) ?? 0.0;

      final dateStr = (row['Income_date'] ?? '').toString();

      totalIncome += amount;
      incomeBySource[source] = (incomeBySource[source] ?? 0) + amount;

      final day = _extractDay(dateStr);
      if (day != null && day >= 1 && day <= daysInMonth) {
        incomeDaily[day - 1] += amount;
      }
    }

    // ------------------ EXPENSE LOOP ------------------
    for (final row in expenses) {
      final rawCat = (row['Category_type'] ?? 'Other').toString();
      final category = _normalizeExpenseCategory(rawCat);

      final amtRaw = row['Expense_amount'] ?? 0;
      final amount = (amtRaw is num)
          ? amtRaw.toDouble()
          : double.tryParse(amtRaw.toString()) ?? 0.0;

      final dateStr = (row['Expense_date'] ?? '').toString();

      totalExpense += amount;
      expenseByCategory[category] = (expenseByCategory[category] ?? 0) + amount;

      // ✅ increment transaction count per normalized category
      expenseTxnCountByCategory[category] =
          (expenseTxnCountByCategory[category] ?? 0) + 1;

      final day = _extractDay(dateStr);
      if (day != null && day >= 1 && day <= daysInMonth) {
        expenseDaily[day - 1] += amount;
      }
    }

    debugPrint(
      "📊 AnalyticsService month=$year-$month income=$totalIncome expense=$totalExpense",
    );
    debugPrint("DBG: expenseTxnCountByCategory = $expenseTxnCountByCategory");

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'incomeBySource': incomeBySource,
      'expenseByCategory': expenseByCategory,
      'expenseTxnCountByCategory': expenseTxnCountByCategory,
      'incomeDaily': incomeDaily,
      'expenseDaily': expenseDaily,

      // ✅ keep raw rows for debug/pdf if needed
      'incomeRows': incomes,
      'expenseRows': expenses,
    };
  }

  // ===================== DETAILS (Modal data) =====================

  Future<List<Map<String, dynamic>>> getIncomeTransactionsByMonthAndSource({
    required String studentId,
    required String monthKey, // "yyyy-MM"
    required String sourceType,
  }) async {
    final rows = await _repo.getIncomeTransactionsByMonthAndSource(
      studentId: studentId,
      monthKey: monthKey,
      sourceType: sourceType,
    );

    return rows.map((r) {
      final raw = (r['Source_type'] ?? sourceType).toString();
      final src = (raw == 'Other') ? 'Others' : raw;

      final amtRaw = r['Income_amount'] ?? r['amount'] ?? 0;
      final amt = (amtRaw is num)
          ? amtRaw.toDouble()
          : double.tryParse(amtRaw.toString()) ?? 0.0;

      final date = (r['Income_date'] ?? r['date'] ?? '').toString();

      return {'date': date, 'amount': amt, 'label': src};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getExpenseTransactionsByMonthAndCategory({
    required String studentId,
    required String monthKey, // "yyyy-MM"
    required String categoryType,
  }) async {
    final rows = await _repo.getExpenseTransactionsByMonthAndCategory(
      studentId: studentId,
      monthKey: monthKey,
      categoryType: categoryType,
    );

    return rows.map((r) {
      final amtRaw = r['amount'] ?? r['Expense_amount'] ?? 0;
      final amt = (amtRaw is num)
          ? amtRaw.toDouble()
          : double.tryParse(amtRaw.toString()) ?? 0.0;

      final date = (r['date'] ?? r['Expense_date'] ?? '').toString();

      final sub =
          (r['subCategory'] ?? r['Sub_category'] ?? r['sub_category'] ?? '')
              .toString();

      final rawCat = (r['label'] ?? r['Category_type'] ?? categoryType)
          .toString();
      final cat = _normalizeExpenseCategory(rawCat);

      return {'date': date, 'amount': amt, 'label': cat, 'subCategory': sub};
    }).toList();
  }

  // ===================== HELPERS =====================

  int? _extractDay(String dateStr) {
    if (dateStr.length < 10) return null;
    final dayPart = dateStr.substring(8, 10);
    return int.tryParse(dayPart);
  }

  // ✅ Essential/Academic/Leisure/Other normalize
  String _normalizeExpenseCategory(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.startsWith('essential') || v.startsWith('essentials')) {
      return 'Essential';
    }
    if (v.startsWith('academic') || v.startsWith('academics')) {
      return 'Academic';
    }
    if (v.startsWith('leisure')) return 'Leisure';
    return 'Other';
  }
}
