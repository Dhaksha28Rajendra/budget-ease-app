import 'db_helper.dart';

class DashboardDao {
  String _ym(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}";

  // ✅ Total income for current month (Dashboard Total Budget)
  Future<double> getTotalIncomeForMonth(String studentId, DateTime month) async {
    final db = await DBHelper.instance.database;
    final ym = _ym(month);

    final res = await db.rawQuery('''
      SELECT IFNULL(SUM(Income_amount), 0) AS total
      FROM Income
      WHERE Student_id = ?
        AND substr(Income_date, 1, 7) = ?
    ''', [studentId, ym]);

    return (res.first['total'] as num).toDouble();
  }

  // ✅ Total expense for current month (Dashboard Total Spent)
  Future<double> getTotalExpenseForMonth(String studentId, DateTime month) async {
    final db = await DBHelper.instance.database;
    final ym = _ym(month);

    final res = await db.rawQuery('''
      SELECT IFNULL(SUM(Expense_amount), 0) AS total
      FROM Expense
      WHERE Student_id = ?
        AND substr(Expense_date, 1, 7) = ?
    ''', [studentId, ym]);

    return (res.first['total'] as num).toDouble();
  }

  // ✅ Category totals (Essentials/Academics/Leisure/Others) for current month
  Future<Map<String, double>> getExpenseTotalsByCategoryForMonth(
      String studentId, DateTime month) async {
    final db = await DBHelper.instance.database;
    final ym = _ym(month);

    final res = await db.rawQuery('''
      SELECT Category_type, IFNULL(SUM(Expense_amount), 0) AS total
      FROM Expense
      WHERE Student_id = ?
        AND substr(Expense_date, 1, 7) = ?
      GROUP BY Category_type
    ''', [studentId, ym]);

    double essentials = 0, academics = 0, leisure = 0, others = 0;

    for (final row in res) {
      final cat = (row['Category_type'] ?? '').toString().toLowerCase().trim();
      final val = (row['total'] as num).toDouble();

      if (cat.startsWith('essential')) {
        essentials += val;
      } else if (cat.startsWith('academic')) {
        academics += val;
      } else if (cat.startsWith('leisure')) {
        leisure += val;
      } else {
        others += val;
      }
    }

    return {
      "essentials": essentials,
      "academics": academics,
      "leisure": leisure,
      "others": others,
    };
  }

  // ✅ Remaining percent for Dashboard circle (remaining of income)
  Future<double> getRemainingPercentForMonth(String studentId, DateTime month) async {
    final income = await getTotalIncomeForMonth(studentId, month);
    final expense = await getTotalExpenseForMonth(studentId, month);

    if (income <= 0) return 0;

    final remaining = (income - expense);
    final safeRemaining = remaining < 0 ? 0 : remaining;

    return (safeRemaining / income) * 100.0;
  }
}