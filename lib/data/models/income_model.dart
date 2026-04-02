class IncomeModel {
  final int? incomeId;
  final double incomeAmount;
  final String sourceType;
  final String incomeDate;
  final String studentId;

  IncomeModel({
    this.incomeId,
    required this.incomeAmount,
    required this.sourceType,
    required this.incomeDate,
    required this.studentId,
  });

  /// Convert object → Map (for SQLite insert/update)
  Map<String, dynamic> toMap() {
    return {
      'Income_id': incomeId,
      'Income_amount': incomeAmount,
      'Source_type': sourceType,
      'Income_date': incomeDate,
      'Student_id': studentId,
    };
  }

  /// Convert Map → object (from SQLite query)
  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      incomeId: map['Income_id'] as int?,
      incomeAmount: (map['Income_amount'] as num).toDouble(),
      sourceType: map['Source_type'] as String,
      incomeDate: map['Income_date'] as String,
      studentId: map['Student_id'] as String,
    );
  }
}
