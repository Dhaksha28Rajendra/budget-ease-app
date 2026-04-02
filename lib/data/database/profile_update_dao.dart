//import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';

class ProfileUpdateDAO {
  // ✅ INSERT PROFILE UPDATE
  Future<int> insertProfileUpdate({
    required String studentId,
    required String incomeType,
    required String spenderType,
    DateTime? checkedAt,
  }) async {
    final db = await DBHelper.instance.database;

    final String dateTimeStr = (checkedAt ?? DateTime.now()).toIso8601String();

    return await db.insert("Profile_Update", {
      "Student_id": studentId,
      "Income_type": incomeType,
      "Spender_type": spenderType,
      "Profile_date": dateTimeStr,
    });
  }

  // ✅ EMAIL → STUDENT ID
  Future<String?> getStudentIdByEmail(String email) async {
    final db = await DBHelper.instance.database;

    final rows = await db.query(
      "Student",
      columns: ["Student_id"],
      where: "Email = ?",
      whereArgs: [email.trim()],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first["Student_id"]?.toString();
  }

  // ✅ GET ALL UPDATES
  Future<List<Map<String, dynamic>>> getUpdates(String studentId) async {
    final db = await DBHelper.instance.database;

    return await db.query(
      "Profile_Update",
      where: "Student_id = ?",
      whereArgs: [studentId],
      orderBy: "Profile_date DESC",
    );
  }

  // ✅ GET LATEST UPDATE ROW
  Future<Map<String, dynamic>?> getLatestUpdate(String studentId) async {
    final db = await DBHelper.instance.database;

    final rows = await db.query(
      "Profile_Update",
      where: "Student_id = ?",
      whereArgs: [studentId],
      orderBy: "Profile_date DESC",
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  // ✅ GET LATEST TYPES (income_type + spender_type)
  Future<Map<String, String>> getLatestTypesByStudentId(
    String studentId,
  ) async {
    final db = await DBHelper.instance.database;

    final rows = await db.query(
      "Profile_Update",
      where: "Student_id = ?",
      whereArgs: [studentId],
      orderBy: "Profile_date DESC",
      limit: 1,
    );

    if (rows.isEmpty) {
      return {"income_type": "", "spender_type": ""};
    }

    return {
      "income_type": (rows.first["Income_type"] ?? "").toString(),
      "spender_type": (rows.first["Spender_type"] ?? "").toString(),
    };
  }
}
