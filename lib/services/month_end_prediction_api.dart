import 'dart:convert';
import 'package:http/http.dart' as http;

class MonthEndPredictionApi {
  final String baseUrl; // ex: http://127.0.0.1:5000

  MonthEndPredictionApi({required this.baseUrl});

  Future<Map<String, double>> predictFromMonthEnd({
    required double totalIncome,
    required double totalExpense,
    required double essentialsTotal,
    required double academicTotal,
    required double leisureTotal,
    required double otherTotal,
  }) async {
    final expenseRatio = totalIncome <= 0 ? 0.0 : (totalExpense / totalIncome);

    final url = Uri.parse('$baseUrl/predict_expense');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "income_mean": totalIncome,
        "expense_mean": totalExpense,
        "essentials_expense": essentialsTotal,
        "academic_expense": academicTotal,
        "leisure_expense": leisureTotal,
        "other_expense": otherTotal,
        "expense_ratio": expenseRatio,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Prediction API error: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body);

    // Your Flask returns PERCENTAGES as 0-100
    return {
      "essentials_pct": (data["essentials_pct"] as num).toDouble(),
      "academic_pct": (data["academic_pct"] as num).toDouble(),
      "leisure_pct": (data["leisure_pct"] as num).toDouble(),
      "other_pct": (data["other_pct"] as num).toDouble(),
    };
  }
}