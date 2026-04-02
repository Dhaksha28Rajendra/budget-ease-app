import 'package:bcrypt/bcrypt.dart';
import 'db_helper.dart';

class StudentDAO {
  /* ===============================
   REGISTER
  =============================== */

  Future<int> insertStudentWithOtp({
    required String studentId,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String gender,
    required String otp,
  }) async {
    final db = await DBHelper.instance.database;

    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    return db.insert('Student', {
      'Student_id': studentId,
      'First_name': firstName,
      'Last_name': lastName,
      'Email': email.toLowerCase(),
      'Password': hashedPassword,
      'Gender': gender,
      'Activation_status': 'INACTIVE',
      'Verification_code': otp,

      // ✅ SAVE ACCOUNT CREATION DATE
      'Created_at': DateTime.now().toIso8601String(),
    });
  }

  /* ===============================
   CHECK EMAIL
  =============================== */

  Future<bool> isEmailExists(String email) async {
    final db = await DBHelper.instance.database;

    final res = await db.query(
      'Student',
      columns: ['Student_id'],
      where: 'Email = ?',
      whereArgs: [email.toLowerCase()],
    );

    return res.isNotEmpty;
  }

  /* ===============================
   GET STUDENT
  =============================== */

  Future<Map<String, dynamic>?> getStudentByEmail(String email) async {
    final db = await DBHelper.instance.database;

    final res = await db.query(
      'Student',
      where: 'Email = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );

    return res.isEmpty ? null : res.first;
  }

  /* ===============================
   GET STUDENT BY ID
  =============================== */

  Future<Map<String, dynamic>?> getStudentById(String studentId) async {
    final db = await DBHelper.instance.database;

    final res = await db.query(
      'Student',
      where: 'Student_id = ?',
      whereArgs: [studentId],
      limit: 1,
    );

    return res.isEmpty ? null : res.first;
  }

  // ✅ NEW: Get Created_at as DateTime (used by EmptyPredictionPlanScreen)
  Future<DateTime?> getRegistrationDate(String studentId) async {
    final data = await getStudentById(studentId);
    if (data == null) return null;

    final raw = (data['Created_at'] ?? '').toString().trim();
    if (raw.isEmpty) return null;

    // Handles both:
    // "2026-02-09T11:15:35.123" (ISO)
    // "2026-02-09 11:15:35"     (sqlite datetime)
    final iso = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');

    return DateTime.tryParse(iso);
  }

  /* ===============================
   ACTIVATE ACCOUNT
  =============================== */

  Future<void> activateStudent(String studentId) async {
    final db = await DBHelper.instance.database;

    await db.update(
      'Student',
      {'Activation_status': 'ACTIVE', 'Verification_code': null},
      where: 'Student_id = ?',
      whereArgs: [studentId],
    );
  }

  /* ===============================
   LOGIN
  =============================== */

  Future<Map<String, dynamic>?> loginStudent(
    String email,
    String password,
  ) async {
    final db = await DBHelper.instance.database;

    final res = await db.query(
      'Student',
      where: '''
      Email = ?
      AND Activation_status = ?
      AND IFNULL(is_deleted, 0) = 0
    ''',
      whereArgs: [email.toLowerCase(), 'ACTIVE'],
      limit: 1,
    );

    if (res.isEmpty) return null;

    final student = res.first;
    final storedHash = student['Password']?.toString() ?? '';

    final isPasswordCorrect = BCrypt.checkpw(password, storedHash);

    return isPasswordCorrect ? student : null;
  }

  Future<bool> isActiveNonDeletedEmail(String email) async {
    final db = await DBHelper.instance.database;

    final res = await db.query(
      'Student',
      columns: ['Student_id'],
      where: '''
      Email = ?
      AND Activation_status = ?
      AND IFNULL(is_deleted, 0) = 0
    ''',
      whereArgs: [email.toLowerCase(), 'ACTIVE'],
      limit: 1,
    );

    return res.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getActiveNonDeletedStudentByEmail(
    String email,
  ) async {
    final db = await DBHelper.instance.database;

    final res = await db.query(
      'Student',
      where: '''
      Email = ?
      AND Activation_status = ?
      AND IFNULL(is_deleted, 0) = 0
    ''',
      whereArgs: [email.toLowerCase(), 'ACTIVE'],
      limit: 1,
    );

    return res.isEmpty ? null : res.first;
  }

  /* ===============================
   OTP MANAGEMENT
  =============================== */

  Future<void> updateOtpByEmail(String email, String otp) async {
    final db = await DBHelper.instance.database;

    await db.update(
      'Student',
      {'Verification_code': otp},
      where: 'Email = ? AND IFNULL(is_deleted, 0) = 0',
      whereArgs: [email.toLowerCase()],
    );
  }

  Future<void> clearOtpByEmail(String email) async {
    final db = await DBHelper.instance.database;

    await db.update(
      'Student',
      {'Verification_code': null},
      where: 'Email = ? AND IFNULL(is_deleted, 0) = 0',
      whereArgs: [email.toLowerCase()],
    );
  }

  /* ===============================
   PASSWORD RESET
  =============================== */

  Future<void> updatePasswordByEmail(String email, String newPassword) async {
    final db = await DBHelper.instance.database;

    final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

    await db.update(
      'Student',
      {'Password': hashedPassword, 'Verification_code': null},
      where: 'Email = ? AND IFNULL(is_deleted, 0) = 0',
      whereArgs: [email.toLowerCase()],
    );
  }

  /* ===============================
   PROFILE
  =============================== */

  Future<Map<String, dynamic>?> getProfileByEmail(String email) async {
    return getStudentByEmail(email);
  }

  Future<int> updateProfileByEmail({
    required String email,
    required String firstName,
    required String lastName,
    required String academicYear,
    String? profileImagePath,
  }) async {
    final db = await DBHelper.instance.database;

    return db.update(
      'Student',
      {
        'First_name': firstName,
        'Last_name': lastName,
        'Academic_year': academicYear,
        'Profile_image': profileImagePath,
      },
      where: 'Email = ?',
      whereArgs: [email.toLowerCase()],
    );
  }

  Future<void> clearProfileImageByEmail(String email) async {
    final db = await DBHelper.instance.database;

    await db.update(
      'Student',
      {'Profile_image': null},
      where: 'Email = ?',
      whereArgs: [email.toLowerCase()],
    );
  }

  /* ===============================
   INTERNAL HELPERS
  =============================== */

  // ✅ Safe table existence check (works with db / txn)
  Future<bool> _tableExists(dynamic dbOrTxn, String tableName) async {
    final result = await dbOrTxn.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name = ? LIMIT 1",
      [tableName],
    );
    return result.isNotEmpty;
  }

  /* ===============================
   DELETE / RETENTION
  =============================== */

  Future<void> purgeAfter90Days() async {
    final db = await DBHelper.instance.database;
    final cutoffIso = DateTime.now()
        .subtract(const Duration(days: 90))
        .toIso8601String();

    await db.transaction((txn) async {
      // 1) Purge detached retention transactions
      await txn.delete(
        'Income',
        where: '''
        status = ?
        AND marked_at IS NOT NULL
        AND marked_at < ?
      ''',
        whereArgs: ['ACCOUNT_DELETED_RETENTION', cutoffIso],
      );

      await txn.delete(
        'Expense',
        where: '''
        status = ?
        AND marked_at IS NOT NULL
        AND marked_at < ?
      ''',
        whereArgs: ['ACCOUNT_DELETED_RETENTION', cutoffIso],
      );

      // 2) Purge deleted student accounts after 90 days
      await txn.delete(
        'Student',
        where: '''
        IFNULL(is_deleted, 0) = 1
        AND deleted_at IS NOT NULL
        AND deleted_at < ?
      ''',
        whereArgs: [cutoffIso],
      );
    });
  }

  Future<void> softDeleteAccountKeepRecords90Days(String email) async {
    final db = await DBHelper.instance.database;
    final nowIso = DateTime.now().toIso8601String();
    final emailLower = email.toLowerCase().trim();

    await db.transaction((txn) async {
      // 1) Get student row first
      final studentRows = await txn.query(
        'Student',
        columns: ['Student_id', 'is_deleted'],
        where: 'Email = ?',
        whereArgs: [emailLower],
        limit: 1,
      );

      if (studentRows.isEmpty) {
        throw Exception('User not found');
      }

      final studentId = studentRows.first['Student_id'] as String;
      final alreadyDeleted =
          (studentRows.first['is_deleted'] as int? ?? 0) == 1;

      if (alreadyDeleted) {
        return; // idempotent (safe if delete pressed twice)
      }

      // 2) Mark student deleted + block auth immediately
      await txn.update(
        'Student',
        {
          'is_deleted': 1,
          'deleted_at': nowIso,
          'Activation_status': 'DELETED',
          'Verification_code': null,
        },
        where: 'Email = ?',
        whereArgs: [emailLower],
      );

      // 3) Keep Income/Expense for 90 days BUT hide immediately everywhere
      //    (detach from Student_id + mark for retention purge)
      await txn.update(
        'Income',
        {
          'status': 'ACCOUNT_DELETED_RETENTION',
          'marked_at': nowIso,
          'Student_id': null, // <- important for "not shown anywhere"
        },
        where: 'Student_id = ?',
        whereArgs: [studentId],
      );

      await txn.update(
        'Expense',
        {
          'status': 'ACCOUNT_DELETED_RETENTION',
          'marked_at': nowIso,
          'Student_id': null, // <- important for "not shown anywhere"
        },
        where: 'Student_id = ?',
        whereArgs: [studentId],
      );

      // 4) Optional but recommended: remove other linked data immediately
      await txn.delete(
        'Budget_Plan',
        where: 'Student_id = ?',
        whereArgs: [studentId],
      );

      await txn.delete(
        'DailyExpenseSummary',
        where: 'Student_id = ?',
        whereArgs: [studentId],
      );

      // ✅ FIX: support BOTH old and new notification table schemas
      if (await _tableExists(txn, 'notifications')) {
        await txn.delete(
          'notifications',
          where: 'student_id = ?',
          whereArgs: [studentId],
        );
      } else if (await _tableExists(txn, 'Notification')) {
        await txn.delete(
          'Notification',
          where: 'Student_id = ?',
          whereArgs: [studentId],
        );
      }

      await txn.delete(
        'Profile_Update',
        where: 'Student_id = ?',
        whereArgs: [studentId],
      );
    });
  }

  Future<int> deleteStudentByEmail(String email) async {
    final db = await DBHelper.instance.database;

    return db.delete(
      'Student',
      where: 'Email = ?',
      whereArgs: [email.toLowerCase()],
    );
  }
}