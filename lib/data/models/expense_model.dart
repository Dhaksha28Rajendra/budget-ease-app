class ExpenseModel {
  final int? expenseId;
  final String studentId;
  final String category;
  final String subCategory;
  final double amount;
  final String expenseDate; // YYYY-MM-DD

  ExpenseModel({
    this.expenseId,
    required this.studentId,
    required this.category,
    required this.subCategory,
    required this.amount,
    required this.expenseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'Expense_id': expenseId,
      'Student_id': studentId,
      'Category': category,
      'Sub_category': subCategory,
      'Amount': amount,
      'Expense_date': expenseDate,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      expenseId: map['Expense_id'],
      studentId: map['Student_id'],
      category: map['Category'],
      subCategory: map['Sub_category'],
      amount: (map['Amount'] as num).toDouble(),
      expenseDate: map['Expense_date'],
    );
  }
}
