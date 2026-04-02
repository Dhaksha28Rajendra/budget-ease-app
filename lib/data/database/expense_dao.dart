import 'package:budget_ease/data/database/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class ExpenseDAO {
  static const String _retentionStatus = 'ACCOUNT_DELETED_RETENTION';

  // =====================================
  // INTERNAL GUARD
  // Prevent inserts for deleted/inactive users
  // =====================================
  Future<bool> _isStudentActiveAndNotDeleted(String studentId) async {
    final db = await DBHelper.instance.database;

    final res = await db.query(
      'Student',
      columns: ['Student_id'],
      where: '''
        Student_id = ?
        AND Activation_status = ?
        AND IFNULL(is_deleted, 0) = 0
      ''',
      whereArgs: [studentId, 'ACTIVE'],
      limit: 1,
    );

    return res.isNotEmpty;
  }
  

  // =============================
  // INSERT EXPENSE
  // =============================
  Future<int> insertExpense({
    required String studentId,
    required String category,
    required double amount,
    required String date, // YYYY-MM-DD
  }) async {
    final Database db = await DBHelper.instance.database;

    // ✅ Guard (deleted/inactive account cannot add expense)
    if (!await _isStudentActiveAndNotDeleted(studentId)) {
      throw Exception('Account is deleted/inactive. Cannot add expense.');
    }

    return await db.insert('Expense', {
      'Student_id': studentId,
      'Category_type': category,
      'Expense_amount': amount,
      'Expense_date': date,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ==========================================================
  // ✅ GET EXPENSE BY MONTH (Analytics & Donut Chart)
  // FIXED: Group by MAIN CATEGORY (Essentials/Academics/Leisure/Others)
  // Because DB stores: "Essentials - Food", etc.
  // ==========================================================
  Future<List<Map<String, dynamic>>> getExpenseByMonth({
    required String studentId,
    required int year,
    required int month,
  }) async {
    final db = await DBHelper.instance.database;

    // Extract main category part before " - "
    // If no hyphen exists, it uses full Category_type
    const mainCategoryExpr = """
      TRIM(
        CASE
          WHEN INSTR(Category_type, '-') > 0
          THEN SUBSTR(Category_type, 1, INSTR(Category_type, '-') - 1)
          ELSE Category_type
        END
      )
    """;

    return await db.rawQuery(
      '''
      SELECT $mainCategoryExpr AS Category_type, SUM(Expense_amount) as total
      FROM Expense
      WHERE Student_id = ?
        AND (status IS NULL OR status != ?)
        AND strftime('%Y', Expense_date) = ?
        AND strftime('%m', Expense_date) = ?
      GROUP BY $mainCategoryExpr
      ''',
      [
        studentId,
        _retentionStatus,
        year.toString(),
        month.toString().padLeft(2, '0'),
      ],
    );
  }

  // =====================================
  // ✅ EXPENSE DETAILS BY CATEGORY (Modal + PDF)
  // FIXED: Use LIKE 'Academics%' instead of '='
  // Because DB stores: "Academics - Study Materials"
  // =====================================
  Future<List<Map<String, dynamic>>> getExpenseTransactionsByMonthAndCategory({
    required String studentId,
    required String monthKey, // yyyy-MM
    required String
    categoryType, // main category: Essentials/Academics/Leisure/Others
  }) async {
    final db = await DBHelper.instance.database;

    return await db.rawQuery(
      '''
      SELECT
        Expense_date AS date,
        Expense_amount AS amount,
        Category_type AS subCategory
      FROM Expense
      WHERE Student_id = ?
        AND (status IS NULL OR status != ?)
        AND Category_type LIKE ?
        AND strftime('%Y-%m', Expense_date) = ?
      ORDER BY Expense_date DESC
      ''',
      [
        studentId,
        _retentionStatus,
        '$categoryType%', // ✅ IMPORTANT FIX
        monthKey,
      ],
    );
  }

  // ==========================================================
  // ✅ GET EXPENSE TRANSACTIONS BY MONTH (NOT GROUPED)
  // Needed for Analytics daily chart + accurate totals
  // ==========================================================
  Future<List<Map<String, dynamic>>> getExpenseTransactionsByMonth({
    required String studentId,
    required int year,
    required int month,
  }) async {
    final db = await DBHelper.instance.database;
    final String monthStr = month.toString().padLeft(2, '0');

    return await db.rawQuery(
      '''
      SELECT Expense_amount, Category_type, Expense_date
      FROM Expense
      WHERE Student_id = ?
        AND (status IS NULL OR status != ?)
        AND strftime('%Y', Expense_date) = ?
        AND strftime('%m', Expense_date) = ?
      ORDER BY Expense_date ASC
      ''',
      [studentId, _retentionStatus, year.toString(), monthStr],
    );
  }

  // ==========================================================
  // GET CURRENT MONTH TOTAL EXPENSE
  // ==========================================================
  Future<double> getCurrentMonthTotalExpense(String studentId) async {
    final db = await DBHelper.instance.database;
    final now = DateTime.now();
    final String currentMonth =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final result = await db.rawQuery(
      '''
      SELECT SUM(Expense_amount) as total 
      FROM Expense 
      WHERE Student_id = ? 
        AND (status IS NULL OR status != ?)
        AND strftime('%Y-%m', Expense_date) = ?
      ''',
      [studentId, _retentionStatus, currentMonth],
    );

    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  // =====================================
  // ✅ FIXED: CURRENT MONTH EXPENSE BY MAIN CATEGORY
  // Because DB values are "Essentials - Food" etc.
  // =====================================
  Future<Map<String, double>> getCurrentMonthExpenseByCategory(
    String studentId,
  ) async {
    final db = await DBHelper.instance.database;
    final now = DateTime.now();
    final String currentMonth =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";

    // Summarize by main category using the same mainCategoryExpr
    const mainCategoryExpr = """
      TRIM(
        CASE
          WHEN INSTR(Category_type, '-') > 0
          THEN SUBSTR(Category_type, 1, INSTR(Category_type, '-') - 1)
          ELSE Category_type
        END
      )
    """;

    final result = await db.rawQuery(
      '''
      SELECT $mainCategoryExpr AS mainCategory, SUM(Expense_amount) as total
      FROM Expense
      WHERE Student_id = ?
        AND (status IS NULL OR status != ?)
        AND strftime('%Y-%m', Expense_date) = ?
      GROUP BY $mainCategoryExpr
      ''',
      [studentId, _retentionStatus, currentMonth],
    );

    final Map<String, double> data = {
      'Essentials': 0,
      'Leisure': 0,
      'Academics': 0,
      'Others': 0,
    };

    for (final row in result) {
      final category = (row['mainCategory'] as String).trim();
      final amount = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (data.containsKey(category)) data[category] = amount;
    }

    return data;
  }

  // =====================================
  // ✅ FIXED: CURRENT MONTH TOTALS BY MAIN CATEGORY
  // =====================================
  Future<Map<String, double>> getCurrentMonthCategoryTotals(
    String studentId,
  ) async {
    final db = await DBHelper.instance.database;
    final now = DateTime.now();
    final String currentMonth =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";

    const mainCategoryExpr = """
      TRIM(
        CASE
          WHEN INSTR(Category_type, '-') > 0
          THEN SUBSTR(Category_type, 1, INSTR(Category_type, '-') - 1)
          ELSE Category_type
        END
      )
    """;

    final result = await db.rawQuery(
      '''
      SELECT $mainCategoryExpr AS mainCategory, SUM(Expense_amount) as total
      FROM Expense
      WHERE Student_id = ?
        AND (status IS NULL OR status != ?)
        AND strftime('%Y-%m', Expense_date) = ?
      GROUP BY $mainCategoryExpr
      ''',
      [studentId, _retentionStatus, currentMonth],
    );

    final map = {
      'Essentials': 0.0,
      'Leisure': 0.0,
      'Academics': 0.0,
      'Others': 0.0,
    };

    for (final row in result) {
      final key = (row['mainCategory'] as String).trim();
      final value = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (map.containsKey(key)) map[key] = value;
    }

    return map;
  }

  // =====================================
  // REMAINING HELPER METHODS
  // (Added retention filter for extra safety)
  // =====================================
  Future<List<Map<String, dynamic>>> getExpensesByDate(
    String studentId,
    String date,
  ) async {
    final Database db = await DBHelper.instance.database;
    return await db.query(
      'Expense',
      where: '''
        Student_id = ?
        AND Expense_date = ?
        AND (status IS NULL OR status != ?)
      ''',
      whereArgs: [studentId, date, _retentionStatus],
      orderBy: 'Expense_id DESC',
    );
  }

  Future<bool> hasAnyExpense(String studentId) async {
    final db = await DBHelper.instance.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM Expense
      WHERE Student_id = ?
        AND (status IS NULL OR status != ?)
      ''',
      [studentId, _retentionStatus],
    );

    return ((result.first['count'] as num?)?.toInt() ?? 0) > 0;
  }

  Future<List<Map<String, dynamic>>> getAllExpensesByStudent(
    String studentId,
  ) async {
    final Database db = await DBHelper.instance.database;
    return await db.query(
      'Expense',
      where: '''
        Student_id = ?
        AND (status IS NULL OR status != ?)
      ''',
      whereArgs: [studentId, _retentionStatus],
      orderBy: 'Expense_date DESC',
    );
  }

  // =============================
  // DELETE EXPENSE
  // =============================
  Future<int> deleteExpense(int expenseId) async {
    final Database db = await DBHelper.instance.database;
    return await db.delete(
      'Expense',
      where: 'Expense_id = ?',
      whereArgs: [expenseId],
    );
  }
}
