import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('budget_ease.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    debugPrint("🔥 DB PATH USED BY APP => $path");

    return await openDatabase(
      path,
      version: 9, // ✅ bump version so rebuild runs
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1) STUDENT
    await db.execute('''
      CREATE TABLE Student (
        Student_id TEXT PRIMARY KEY,
        First_name TEXT NOT NULL,
        Last_name TEXT NOT NULL,
        Email TEXT NOT NULL UNIQUE,
        Password TEXT NOT NULL,
        Gender TEXT NOT NULL,
        Age INTEGER,
        Academic_year TEXT,
        Profile_image TEXT,
        Activation_status TEXT NOT NULL,
        Verification_code TEXT,
        is_deleted INTEGER DEFAULT 0,
        deleted_at TEXT,
        Created_at TEXT NOT NULL
      )
    ''');

    // 2) PROFILE_UPDATE
    await db.execute('''
      CREATE TABLE Profile_Update (
        Student_id TEXT NOT NULL,
        Income_type TEXT NOT NULL,
        Spender_type TEXT NOT NULL,
        Profile_date TEXT NOT NULL,
        PRIMARY KEY (Student_id, Spender_type, Profile_date),
        FOREIGN KEY (Student_id) REFERENCES Student (Student_id) ON DELETE CASCADE
      )
    ''');

    // 3) EXPENSE
    await db.execute('''
      CREATE TABLE Expense (
        Expense_id INTEGER PRIMARY KEY AUTOINCREMENT,
        Expense_date TEXT NOT NULL,
        Category_type TEXT NOT NULL,
        Expense_amount REAL NOT NULL,
        Student_id TEXT,
        status TEXT,
        marked_at TEXT,
        FOREIGN KEY (Student_id) REFERENCES Student (Student_id)
      )
    ''');

    // 4) INCOME
    await db.execute('''
      CREATE TABLE Income (
        Income_id INTEGER PRIMARY KEY AUTOINCREMENT,
        Income_amount REAL NOT NULL,
        Source_type TEXT NOT NULL,
        Income_date TEXT NOT NULL,
        Student_id TEXT,
        status TEXT,
        marked_at TEXT,
        FOREIGN KEY (Student_id) REFERENCES Student (Student_id)
      )
    ''');

    // 5) BUDGET_PLAN (✅ cleaned schema)
    await db.execute('''
      CREATE TABLE Budget_Plan (
        Budget_id INTEGER PRIMARY KEY AUTOINCREMENT,
        Total_Expense REAL,
        Student_id TEXT,
        Plan_date TEXT,
        FOREIGN KEY (Student_id) REFERENCES Student (Student_id)
      )
    ''');

    // 6) NOTIFICATIONS
    // 6) NOTIFICATIONS (create with the full new schema)
    await db.execute('''
  CREATE TABLE notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT,
    income_source TEXT,
    category TEXT,
    amount REAL,
    is_read INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES Student (Student_id) ON DELETE CASCADE
  )
''');

    // 7) MONTH_END_PLAN (same as your current schema)
    await db.execute('''
      CREATE TABLE Month_End_Plan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        month_key TEXT NOT NULL, -- YYYY-MM

        last_month_total_income REAL NOT NULL DEFAULT 0,
        last_month_total_expense REAL NOT NULL DEFAULT 0,

        last_month_essentials_total REAL NOT NULL DEFAULT 0,
        last_month_academic_total REAL NOT NULL DEFAULT 0,
        last_month_leisure_total REAL NOT NULL DEFAULT 0,
        last_month_other_total REAL NOT NULL DEFAULT 0,

        Spending_Essentials_Perc REAL,
        Spending_Academic_Perc REAL,
        Spending_Leisure_Perc REAL,
        Spending_Other_Perc REAL,

        Essentials_Amount REAL,
        Academic_Amount REAL,
        Leisure_Amount REAL,
        Other_Amount REAL,
        Budget_Total_Used REAL,

        created_at TEXT NOT NULL,
        UNIQUE(student_id, month_key),
        FOREIGN KEY (student_id) REFERENCES Student (Student_id) ON DELETE CASCADE
      )
    ''');

    debugPrint("✅ SQLITE SETUP: All tables created (v$version)");
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint("⬆️ Upgrading DB: $oldVersion -> $newVersion");

    // ✅ Ensure Student columns exist
    await _ensureColumn(db, 'Student', 'Age', 'INTEGER');
    await _ensureColumn(db, 'Student', 'Academic_year', 'TEXT');
    await _ensureColumn(db, 'Student', 'Profile_image', 'TEXT');
    await _ensureColumn(db, 'Student', 'is_deleted', 'INTEGER DEFAULT 0');
    await _ensureColumn(db, 'Student', 'deleted_at', 'TEXT');
    await _ensureColumn(db, 'Student', 'Created_at', 'TEXT');

    // ✅ Ensure Expense/Income tracking columns exist
    await _ensureColumn(db, 'Expense', 'status', 'TEXT');
    await _ensureColumn(db, 'Expense', 'marked_at', 'TEXT');
    await _ensureColumn(db, 'Income', 'status', 'TEXT');
    await _ensureColumn(db, 'Income', 'marked_at', 'TEXT');

    // ✅ notifications table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES Student (Student_id) ON DELETE CASCADE
      )
    ''');

    // ✅ Month_End_Plan exists (keep as-is)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Month_End_Plan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        month_key TEXT NOT NULL,

        last_month_total_income REAL NOT NULL DEFAULT 0,
        last_month_total_expense REAL NOT NULL DEFAULT 0,

        last_month_essentials_total REAL NOT NULL DEFAULT 0,
        last_month_academic_total REAL NOT NULL DEFAULT 0,
        last_month_leisure_total REAL NOT NULL DEFAULT 0,
        last_month_other_total REAL NOT NULL DEFAULT 0,

        Spending_Essentials_Perc REAL,
        Spending_Academic_Perc REAL,
        Spending_Leisure_Perc REAL,
        Spending_Other_Perc REAL,

        Essentials_Amount REAL,
        Academic_Amount REAL,
        Leisure_Amount REAL,
        Other_Amount REAL,
        Budget_Total_Used REAL,

        created_at TEXT NOT NULL,
        UNIQUE(student_id, month_key),
        FOREIGN KEY (student_id) REFERENCES Student (Student_id) ON DELETE CASCADE
      )
    ''');

    await _ensureColumn(db, 'Month_End_Plan', 'Essentials_Amount', 'REAL');
    await _ensureColumn(db, 'Month_End_Plan', 'Academic_Amount', 'REAL');
    await _ensureColumn(db, 'Month_End_Plan', 'Leisure_Amount', 'REAL');
    await _ensureColumn(db, 'Month_End_Plan', 'Other_Amount', 'REAL');
    await _ensureColumn(db, 'Month_End_Plan', 'Budget_Total_Used', 'REAL');

    // ensure notifications has the new columns
    await _ensureColumn(db, 'notifications', 'type', 'TEXT');
    await _ensureColumn(db, 'notifications', 'income_source', 'TEXT');
    await _ensureColumn(db, 'notifications', 'category', 'TEXT');
    await _ensureColumn(db, 'notifications', 'amount', 'REAL');

    // ✅ v9: remove Budget_Plan unwanted columns by rebuild
    if (oldVersion < 9) {
      await _rebuildBudgetPlan_v9(db);
    }

    debugPrint("✅ SQLITE UPGRADE COMPLETE");
  }

  Future<void> _rebuildBudgetPlan_v9(Database db) async {
    if (!await _tableExists(db, 'Budget_Plan')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Budget_Plan (
          Budget_id INTEGER PRIMARY KEY AUTOINCREMENT,
          Total_Expense REAL,
          Student_id TEXT,
          Plan_date TEXT,
          FOREIGN KEY (Student_id) REFERENCES Student (Student_id)
        )
      ''');
      return;
    }

    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');

      await txn.execute('DROP TABLE IF EXISTS Budget_Plan_new');
      await txn.execute('''
        CREATE TABLE Budget_Plan_new (
          Budget_id INTEGER PRIMARY KEY AUTOINCREMENT,
          Total_Expense REAL,
          Student_id TEXT,
          Plan_date TEXT,
          FOREIGN KEY (Student_id) REFERENCES Student (Student_id)
        )
      ''');

      final cols = await _getColumns(txn, 'Budget_Plan');

      // Old table might have either "Budget_id" or "id"
      final hasBudgetId = cols.contains('Budget_id');
      final hasId = cols.contains('id');

      final hasTotalExpense = cols.contains('Total_Expense');
      final hasStudentId = cols.contains('Student_id');
      final hasPlanDate = cols.contains('Plan_date');

      final insertCols = <String>[];
      final selectCols = <String>[];

      if (hasBudgetId) {
        insertCols.add('Budget_id');
        selectCols.add('Budget_id');
      } else if (hasId) {
        insertCols.add('Budget_id');
        selectCols.add('id');
      }

      if (hasTotalExpense) {
        insertCols.add('Total_Expense');
        selectCols.add('Total_Expense');
      }

      if (hasStudentId) {
        insertCols.add('Student_id');
        selectCols.add('Student_id');
      }

      if (hasPlanDate) {
        insertCols.add('Plan_date');
        selectCols.add('Plan_date');
      }

      if (insertCols.isNotEmpty) {
        await txn.execute('''
          INSERT INTO Budget_Plan_new (${insertCols.join(', ')})
          SELECT ${selectCols.join(', ')} FROM Budget_Plan
        ''');
      }

      await txn.execute('DROP TABLE Budget_Plan');
      await txn.execute('ALTER TABLE Budget_Plan_new RENAME TO Budget_Plan');

      await txn.execute('PRAGMA foreign_keys = ON');
    });

    debugPrint("✅ Budget_Plan rebuilt (v9) - removed unwanted columns");
  }

  Future<void> _ensureColumn(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    if (!await _tableExists(db, table)) return;

    final cols = await db.rawQuery("PRAGMA table_info($table)");
    final exists = cols.any((row) => (row['name']?.toString() ?? '') == column);

    if (!exists) {
      debugPrint("➕ Adding column: $table.$column");
      await db.execute("ALTER TABLE $table ADD COLUMN $column $definition");
    }
  }

  Future<bool> _tableExists(DatabaseExecutor db, String table) async {
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    return res.isNotEmpty;
  }

  Future<Set<String>> _getColumns(DatabaseExecutor db, String table) async {
    final res = await db.rawQuery("PRAGMA table_info($table)");
    return res.map((r) => (r['name']?.toString() ?? '')).toSet();
  }

  Future<void> debugStudentSchema() async {
    final db = await database;
    final result = await db.rawQuery("PRAGMA table_info(Student)");
    debugPrint("🧪 Student Table Schema:");
    for (final row in result) {
      debugPrint(row.toString());
    }
  }
}
