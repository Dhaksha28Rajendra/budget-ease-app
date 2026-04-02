import '../data/database/income_dao.dart';
import '../data/database/expense_dao.dart';

class AnalyticsRepository {
  final IncomeDao _incomeDAO = IncomeDao();
  final ExpenseDAO _expenseDAO = ExpenseDAO();

  // ================================
  // GROUPED MONTH DATA (for charts)
  // ================================
  Future<List<Map<String, dynamic>>> getIncomeByMonth({
    required String studentId,
    required int year,
    required int month,
  }) {
    return _incomeDAO.getIncomeByMonth(
      studentId: studentId,
      year: year,
      month: month,
    );
  }

  Future<List<Map<String, dynamic>>> getExpenseByMonth({
    required String studentId,
    required int year,
    required int month,
  }) {
    return _expenseDAO.getExpenseByMonth(
      studentId: studentId,
      year: year,
      month: month,
    );
  }

  // ==========================================
  // ✅ NEW: TRANSACTIONS BY MONTH (NOT GROUPED)
  // Needed for daily line chart + accurate totals
  // ==========================================
  Future<List<Map<String, dynamic>>> getIncomeTransactionsByMonth({
    required String studentId,
    required int year,
    required int month,
  }) {
    return _incomeDAO.getIncomeTransactionsByMonth(
      studentId: studentId,
      year: year,
      month: month,
    );
  }

  Future<List<Map<String, dynamic>>> getExpenseTransactionsByMonth({
    required String studentId,
    required int year,
    required int month,
  }) {
    return _expenseDAO.getExpenseTransactionsByMonth(
      studentId: studentId,
      year: year,
      month: month,
    );
  }

  // ================================
  // DETAILS (Modal / PDF lists)
  // ================================
  Future<List<Map<String, dynamic>>> getIncomeTransactionsByMonthAndSource({
    required String studentId,
    required String monthKey,
    required String sourceType,
  }) {
    return _incomeDAO.getIncomeTransactionsByMonthAndSource(
      studentId: studentId,
      monthKey: monthKey,
      sourceType: sourceType,
    );
  }

  Future<List<Map<String, dynamic>>> getExpenseTransactionsByMonthAndCategory({
    required String studentId,
    required String monthKey,
    required String categoryType,
  }) {
    return _expenseDAO.getExpenseTransactionsByMonthAndCategory(
      studentId: studentId,
      monthKey: monthKey,
      categoryType: categoryType,
    );
  }
}
