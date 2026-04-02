import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';

class NotificationDao {
  Future<Database> get _db async => await DBHelper.instance.database;

  // ================= INSERT NOTIFICATION =================
  Future<void> insertNotification({
    required String studentId,
    required String title,
    required String message,
    required String type,
    String? income_source,
    String? category,
    required double amount,
  }) async {
    final db = await _db;

    await db.insert('notifications', {
      'student_id': studentId,
      'title': title,
      'message': message,
      'type': type,
      'income_source': income_source,
      'category': category,
      'amount': amount,
      'is_read': 0,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ================= GET NOTIFICATIONS =================
  Future<List<Map<String, dynamic>>> getNotificationsByStudent(
    String studentId,
  ) async {
    final db = await _db;

    return await db.query(
      'notifications',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'created_at DESC',
    );
  }

  // ================= UNREAD COUNT =================
  Future<int> getUnreadCount(String studentId) async {
    final db = await _db;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM notifications WHERE student_id = ? AND is_read = 0',
      [studentId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ================= MARK ALL READ =================
  Future<void> markAllRead(String studentId) async {
    final db = await _db;

    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
  }

  Future<void> markTypeRead(String studentId, String type) async {
    final db = await _db;

    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'student_id = ? AND type = ?',
      whereArgs: [studentId, type],
    );
  }

  // ================= DELETE ALL (OPTIONAL CLEANUP) =================
  Future<void> deleteAllNotifications(String studentId) async {
    final db = await _db;

    await db.delete(
      'notifications',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
  }
}
