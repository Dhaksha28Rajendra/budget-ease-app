// notifications_screen.dart
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/database/notification_dao.dart';

class NotificationsScreen extends StatefulWidget {
  final String studentId;
  const NotificationsScreen({super.key, required this.studentId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationDao _dao = NotificationDao();

  // raw parsed notifications enriched with DateTime and message
  List<Map<String, dynamic>> _all = [];

  // grouped lists
  List<Map<String, dynamic>> _recent = [];
  List<Map<String, dynamic>> _yesterday = [];
  List<Map<String, dynamic>> _last7 = [];
  List<Map<String, dynamic>> _last30 = [];
  List<Map<String, dynamic>> _older = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------- Utilities ----------
  DateTime? _tryParseCreatedAt(dynamic v) {
    if (v == null) return null;
    try {
      final s = v.toString().trim();
      // Try direct parse first
      var dt = DateTime.tryParse(s);
      if (dt != null) return dt;
      // Try replacing space with T: "2023-05-05 12:34:56" -> "2023-05-05T12:34:56"
      dt = DateTime.tryParse(s.replaceFirst(' ', 'T'));
      if (dt != null) return dt;
      // Try common SQL-like "yyyy-MM-dd HH:mm:ss" with no timezone by manual parsing
      final parts = s.split(' ');
      if (parts.isNotEmpty) {
        final dateParts = parts[0].split('-');
        int y = int.parse(dateParts[0]);
        int m = dateParts.length > 1 ? int.parse(dateParts[1]) : 1;
        int d = dateParts.length > 2 ? int.parse(dateParts[2]) : 1;
        int hh = 0, mm = 0, ss = 0;
        if (parts.length > 1) {
          final timeParts = parts[1].split(':');
          if (timeParts.isNotEmpty) hh = int.parse(timeParts[0]);
          if (timeParts.length > 1) mm = int.parse(timeParts[1]);
          if (timeParts.length > 2) ss = int.parse(timeParts[2]);
        }
        return DateTime(y, m, d, hh, mm, ss);
      }
    } catch (_) {}
    return null;
  }

  String _formatShortDateTime(DateTime dt) {
    // simple format: "YYYY-MM-DD HH:MM"
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  // Build a human message from notification fields (robust)
  String _buildMessage(Map<String, dynamic> n) {
    // prefer explicit message if already provided and non-empty
    final rawMsg = (n['message'] ?? '').toString().trim();
    if (rawMsg.isNotEmpty && rawMsg.length > 6) {
      // but we still prefer to generate clearer messages for income/expense
      // if we detect type info we will produce our own message below
    }

    final type = (n['type'] ?? n['notification_type'] ?? '')
        .toString()
        .toLowerCase();
    // possible keys for source / income source
    final sourceCandidates = [
      'income_source',
      'source',
      'from_source',
      'payment_source',
    ];
    String? source;
    for (final k in sourceCandidates) {
      if (n.containsKey(k) &&
          n[k] != null &&
          n[k].toString().trim().isNotEmpty) {
        source = n[k].toString().trim();
        break;
      }
    }

    // possible keys for amount
    double? amount;
    final amountCandidates = [
      'amount',
      'income_amount',
      'Expense_amount',
      'Income_amount',
    ];
    for (final k in amountCandidates) {
      if (n.containsKey(k) && n[k] != null) {
        try {
          amount =
              double.tryParse(n[k].toString()) ??
              (n[k] is num ? (n[k] as num).toDouble() : null);
          if (amount != null) break;
        } catch (_) {}
      }
    }

    // possible keys for category / categories
    String? category;
    final catCandidates = [
      'category',
      'Category_type',
      'spender_category',
      'sub_category',
      'categories',
      'category_type',
    ];
    for (final k in catCandidates) {
      if (n.containsKey(k) &&
          n[k] != null &&
          n[k].toString().trim().isNotEmpty) {
        final v = n[k];
        if (v is String) {
          category = v.trim();
        } else if (v is List) {
          category = v.map((e) => e.toString()).join(', ');
        } else {
          category = v.toString();
        }
        break;
      }
    }

    // If explicit type contains income
    if (type.contains('income') ||
        (n['title'] ?? '').toString().toLowerCase().contains('income')) {
      final amtText = amount != null ? ' of Rs. ${amount.toInt()}' : '';
      final srcText = source != null ? ' from $source' : '';
      return 'Your income$amtText$srcText has been added successfully.';
    }

    // Expense detection
    if (type.contains('expense') ||
        (n['title'] ?? '').toString().toLowerCase().contains('expense')) {
      final amtText = amount != null ? ' of Rs. ${amount.toInt()}' : '';
      final catText = category != null ? ' for $category' : '';
      return 'Your expense$amtText$catText has been added successfully.';
    }

    // If payload contains "income_source" specifically
    if (source != null && (category == null)) {
      return 'Your income${amount != null ? ' of Rs. ${amount.toInt()}' : ''} from $source has been added successfully.';
    }

    if (category != null && (source == null)) {
      return 'Your expense${amount != null ? ' of Rs. ${amount.toInt()}' : ''} for $category has been added successfully.';
    }

    // fallback: use raw message if provided, else generic
    if (rawMsg.isNotEmpty) return rawMsg;
    return 'You have a new notification.';
  }

  // ---------- Load and group ----------
  Future<void> _load() async {
    try {
      final list = await _dao.getNotificationsByStudent(widget.studentId);
      if (!mounted) return;

      // defensively ensure list is a List<Map<String,dynamic>>
      final parsed = <Map<String, dynamic>>[];

      // ignore: unnecessary_null_comparison
      if (list != null) {
        for (final e in list) {
          // ignore: unnecessary_type_check
          if (e is Map<String, dynamic>) {
            parsed.add(Map<String, dynamic>.from(e));
            // ignore: dead_code
          } else {
            try {
              parsed.add(Map<String, dynamic>.from(e));
            } catch (_) {
              // ignore invalid items
            }
          }
        }
      }

      // 🔴 REMOVE recommendation notifications
      parsed.removeWhere(
        (n) => (n['type'] ?? '').toString().toLowerCase() == 'recommendation',
      );

      // enrich each item with DateTime and generated message
      final now = DateTime.now();
      for (final item in parsed) {
        final dt = _tryParseCreatedAt(item['created_at']) ?? now;
        item['created_at_dt'] = dt;
        item['display_message'] = _buildMessage(item);
        item['display_time'] = _formatShortDateTime(dt);
      }

      // sort newest first
      parsed.sort((a, b) {
        final da = a['created_at_dt'] as DateTime;
        final db = b['created_at_dt'] as DateTime;
        return db.compareTo(da);
      });

      // grouping: first 5 -> Recent
      final recentList = parsed.take(5).toList();
      final remaining = parsed.skip(5);

      final yesterdayList = <Map<String, dynamic>>[];
      final last7List = <Map<String, dynamic>>[];
      final last30List = <Map<String, dynamic>>[];
      final olderList = <Map<String, dynamic>>[];

      final todayDateOnly = DateTime(now.year, now.month, now.day);

      for (final item in remaining) {
        final DateTime dt = item['created_at_dt'] as DateTime;
        final dtDateOnly = DateTime(dt.year, dt.month, dt.day);
        final daysDiff = todayDateOnly.difference(dtDateOnly).inDays;

        if (daysDiff == 1) {
          yesterdayList.add(item);
        } else if (daysDiff >= 2 && daysDiff <= 7) {
          last7List.add(item);
        } else if (daysDiff >= 8 && daysDiff <= 30) {
          last30List.add(item);
        } else {
          olderList.add(item);
        }
      }

      setState(() {
        _all = parsed;
        _recent = recentList;
        _yesterday = yesterdayList;
        _last7 = last7List;
        _last30 = last30List;
        _older = olderList;
      });
    } catch (e) {
      // ignore UI crash but you can log if needed
    }
  }

  // ---------- UI builders ----------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _notificationCard(Map<String, dynamic> n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (n['title'] ?? '').toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (n['display_message'] ?? n['message'] ?? '').toString(),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  (n['display_time'] ?? n['created_at'] ?? '').toString(),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        const SizedBox(height: 6),
        ...list.map(_notificationCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final anyNotifications = _all.isNotEmpty;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/MainScreens.jpeg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                const SizedBox(height: 12),
                Expanded(
                  child: !anyNotifications
                      ? const Center(
                          child: Text(
                            "No notifications yet 😊",
                            style: TextStyle(fontSize: 14),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              if (_recent.isNotEmpty) _sectionTitle('Recent'),
                              if (_recent.isNotEmpty)
                                const SizedBox(height: 10),
                              ..._recent.map(_notificationCard),

                              // grouped remainder
                              if (_yesterday.isNotEmpty)
                                const SizedBox(height: 6),
                              _buildSection('Yesterday', _yesterday),
                              _buildSection('Last 7 days', _last7),
                              _buildSection('Last 30 days', _last30),
                              _buildSection('Older', _older),

                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // topbar (same as before)
  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 8),
          Image.asset('assets/Intellects_Logo.png', height: 36),
          const SizedBox(width: 10),
          const Text(
            "Notifications",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
