import 'db_helper.dart';

class MonthEndPlanDao {
  // ✅ Creates row if not exists, otherwise UPDATES totals
  Future<void> createLastMonthPlan(String studentId) async {
    final db = await DBHelper.instance.database;

    final now = DateTime.now();

    // ✅ TEST MODE: CURRENT MONTH
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Total income
    final incomeRes = await db.rawQuery(
      '''
      SELECT SUM(Income_amount) as total
      FROM Income
      WHERE Student_id = ?
      AND strftime('%Y-%m', Income_date) = ?
    ''',
      [studentId, monthKey],
    );

    final totalIncome = (incomeRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // Total expense
    final expenseRes = await db.rawQuery(
      '''
      SELECT SUM(Expense_amount) as total
      FROM Expense
      WHERE Student_id = ?
      AND strftime('%Y-%m', Expense_date) = ?
    ''',
      [studentId, monthKey],
    );

    final totalExpense = (expenseRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // Category totals
    Future<double> sumCategory(String prefix) async {
      final res = await db.rawQuery(
        '''
        SELECT SUM(Expense_amount) as total
        FROM Expense
        WHERE Student_id = ?
        AND strftime('%Y-%m', Expense_date) = ?
        AND Category_type LIKE ?
      ''',
        [studentId, monthKey, '$prefix%'],
      );

      return (res.first['total'] as num?)?.toDouble() ?? 0.0;
    }

    final essentials = await sumCategory('Essentials');
    final academic = await sumCategory('Academics');
    final leisure = await sumCategory('Leisure');
    final other = await sumCategory('Others');

    // ✅ Check if already exists
    final existing = await db.query(
      'Month_End_Plan',
      where: 'student_id = ? AND month_key = ?',
      whereArgs: [studentId, monthKey],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // ✅ UPDATE totals
      await db.update(
        'Month_End_Plan',
        {
          'last_month_total_income': totalIncome,
          'last_month_total_expense': totalExpense,
          'last_month_essentials_total': essentials,
          'last_month_academic_total': academic,
          'last_month_leisure_total': leisure,
          'last_month_other_total': other,
        },
        where: 'student_id = ? AND month_key = ?',
        whereArgs: [studentId, monthKey],
      );

      print("✅ Month_End_Plan totals UPDATED for $monthKey");
      return;
    }

    // ✅ INSERT totals
    await db.insert('Month_End_Plan', {
      'student_id': studentId,
      'month_key': monthKey,
      'last_month_total_income': totalIncome,
      'last_month_total_expense': totalExpense,
      'last_month_essentials_total': essentials,
      'last_month_academic_total': academic,
      'last_month_leisure_total': leisure,
      'last_month_other_total': other,
      'created_at': DateTime.now().toIso8601String(),
    });

    print("✅ Month_End_Plan row CREATED for $monthKey");
  }

  // ✅ Must use SAME monthKey rule as createLastMonthPlan()
  Future<Map<String, dynamic>?> getLastMonthRow(String studentId) async {
    final db = await DBHelper.instance.database;

    final now = DateTime.now();

    // ✅ TEST MODE: CURRENT MONTH
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final rows = await db.query(
      'Month_End_Plan',
      where: 'student_id = ? AND month_key = ?',
      whereArgs: [studentId, monthKey],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first;
  }

  // ✅ Update predicted percentages (model output)
  Future<void> updatePercentages({
    required String studentId,
    required String monthKey,
    required double essentials,
    required double academic,
    required double leisure,
    required double other,
  }) async {
    final db = await DBHelper.instance.database;

    await db.update(
      'Month_End_Plan',
      {
        'Spending_Essentials_Perc': essentials,
        'Spending_Academic_Perc': academic,
        'Spending_Leisure_Perc': leisure,
        'Spending_Other_Perc': other,
      },
      where: 'student_id = ? AND month_key = ?',
      whereArgs: [studentId, monthKey],
    );

    print("✅ Month_End_Plan percentages UPDATED for $monthKey");
  }

  Future<Map<String, double>?> getCurrentMonthPredictedPerc(
    String studentId,
  ) async {
    final db = await DBHelper.instance.database;

    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final rows = await db.query(
      'Month_End_Plan',
      where: 'student_id = ? AND month_key = ?',
      whereArgs: [studentId, monthKey],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final r = rows.first;

    double toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

    return {
      "Essentials": toDouble(r["Spending_Essentials_Perc"]),
      "Academics": toDouble(r["Spending_Academic_Perc"]),
      "Leisure": toDouble(r["Spending_Leisure_Perc"]),
      "Others": toDouble(r["Spending_Other_Perc"]),
    };
  }
} // ← MAKE SURE THIS IS THE LAST BRACE
