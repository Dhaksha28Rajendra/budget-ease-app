import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/app_colors.dart';
import 'screens/login_screen.dart';
import 'data/database/db_helper.dart';

/// 🔔 Global Route Observer (USED BY DASHBOARD)
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  // 🔴 REQUIRED before any async or DB work
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ REQUIRED for SQLite on Windows / Desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ✅ Initialize database & create tables
  debugPrint("Checking database status...");
  await DBHelper.instance.database;

  runApp(const BudgetEaseApp());
}

class BudgetEaseApp extends StatelessWidget {
  const BudgetEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Ease',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.white,
      ),

      /// 👇 VERY IMPORTANT (for dashboard auto-refresh)
      navigatorObservers: [routeObserver],

      home: const LoginScreen(),
    );
  }
}
