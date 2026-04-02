import 'dart:convert';
import 'package:http/http.dart' as http;

class RecommendationApi {
  // ✅ IMPORTANT:
  // - Android emulator: http://10.0.2.2:5000
  // - Real phone (same Wi-Fi): http://YOUR_PC_IP:5000  (ex: 192.168.1.5)
  // - Windows desktop app / web: http://127.0.0.1:5000
  static const String baseUrl = "http://192.168.8.101:5000";

  static Future<Map<String, dynamic>> recommendBudget({
    required double monthlyIncome,
    required double essentialsAmount,
    required double academicAmount,
    required double leisureAmount,
    required double otherAmount,
    required String incomeType,
    required String spenderType,
  }) async {
    final uri = Uri.parse("$baseUrl/recommend_budget");

    final body = {
      "monthly_income": monthlyIncome,
      "essentials_amount": essentialsAmount,
      "academic_amount": academicAmount,
      "leisure_amount": leisureAmount,
      "other_amount": otherAmount,
      "income_type": incomeType,
      "spender_type": spenderType,
    };

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("API Error ${res.statusCode}: ${res.body}");
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
