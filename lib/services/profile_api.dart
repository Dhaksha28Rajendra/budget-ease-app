import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileApi {
  // Android Emulator -> your PC localhost
  static const String baseUrl = "http://192.168.8.101:5000";

  static Future<Map<String, dynamic>> predictProfile({
    required int ageChoice,
    required List<int> incomeSources,
    required int avgIncomeChoice,
    required List<int> expenseCategories,
    required int trackingChoice,
    required int approxSpendingChoice,
    required double essentialsPct,
    required double academicPct,
    required double leisurePct,
    required double otherPct,
  }) async {
    final url = Uri.parse("$baseUrl/predict_profile");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "age_choice": ageChoice,
        "income_sources": incomeSources,
        "avg_income_choice": avgIncomeChoice,
        "expense_categories": expenseCategories,
        "tracking_choice": trackingChoice,
        "approx_spending_choice": approxSpendingChoice,
        "essentials_pct": essentialsPct,
        "academic_pct": academicPct,
        "leisure_pct": leisurePct,
        "other_pct": otherPct,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("API error ${res.statusCode}: ${res.body}");
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
