import 'db_helper.dart';

class BudgetPlanDao {
  // ================= GET CURRENT PLAN =================
  Future<Map<String, dynamic>?> getCurrentPlan(
    String studentId,
    String date,
  ) async {
    final db = await DBHelper.instance.database;

    final result = await db.query(
      'Budget_Plan',
      where: 'Student_id = ? AND Plan_date = ?',
      whereArgs: [studentId, date],
    );

    return result.isNotEmpty ? result.first : null;
  }

  // ================= INSERT OR UPDATE EXPENSE =================
  Future<void> insertOrUpdateExpense({
    required String studentId,
    required String date,
    required double expenseAmount,
  }) async {
    final db = await DBHelper.instance.database;

    final existingPlan = await getCurrentPlan(studentId, date);

    if (existingPlan == null) {
      // ✅ INSERT
      await db.insert('Budget_Plan', {
        'Student_id': studentId,
        'Plan_date': date,
        'Total_expense': expenseAmount, // ✅ FIXED COLUMN NAME
      });
    } else {
      // ✅ UPDATE
      await db.update(
        'Budget_Plan',
        {
          'Total_expense': expenseAmount, // ✅ FIXED COLUMN NAME
        },
        where: 'Student_id = ? AND Plan_date = ?',
        whereArgs: [studentId, date],
      );
    }
  }
}
