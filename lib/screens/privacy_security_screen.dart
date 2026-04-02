import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          /// FULL SCREEN BACKGROUND
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/MainScreens.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Light overlay for readability
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.05),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  _topBar(context),
                  const SizedBox(height: 18),
                  _titleCard(),
                  const SizedBox(height: 22),
                  _contentCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TOP BAR =================
  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_back,
                size: 28,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ================= TITLE CARD =================
  Widget _titleCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.security_outlined,
              color: AppColors.primaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Privacy & Security',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  // ================= CONTENT CARD =================
  Widget _contentCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          _ExpandableItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            content:
                'Account Deletion\n\n'
                'When a user chooses to delete their account, the account is deactivated immediately and access to the application is permanently revoked. '
                'The user will no longer be able to log in or use any features of the app.\n\n'
                'Transaction Data Retention\n\n'
                'Even after account deletion, the user’s financial transaction records (Income and Expense data) are retained for a temporary period of 90 days '
                'for the following purposes:\n'
                '• Data integrity and consistency\n'
                '• Audit and recovery support\n'
                '• Prevention of accidental data loss\n\n'
                'During this 90-day period:\n'
                '• Transaction records are not accessible to the user\n'
                '• The data is not reused for analytics or shared with third parties\n'
                '• The records are securely stored in the local database\n\n'
                'Permanent Deletion\n\n'
                'After the 90-day retention period:\n'
                '• All retained transaction records are permanently deleted\n'
                '• The user’s profile information is completely removed\n'
                '• The data cannot be recovered under any circumstances\n\n'
                'Data Security\n\n'
                'All user data is stored securely and processed only within the application. '
                'The system ensures that deleted accounts remain inaccessible and that retained data is handled according to this policy.\n\n'
                'User Consent\n\n'
                'By using this application and deleting an account, users acknowledge and agree to the above data retention and deletion policy.',
          ),
          _DividerLine(),
          _ExpandableItem(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            content:
                'Terms & Conditions\n\n'
                'Acceptance of Terms\n\n'
                'By installing, accessing, or using the Budget Ease application, you agree to comply with and be bound by these Terms and Conditions. '
                'If you do not agree with any part of these terms, you should discontinue use of the application.\n\n'
                'Purpose of the Application\n\n'
                'Budget Ease is designed for personal budgeting and expense tracking purposes only. '
                'The application helps users manage income and expenses and does not provide financial, legal, or professional advice.\n\n'
                'User Responsibilities\n\n'
                'Users are responsible for maintaining the confidentiality of their login credentials and for all activities performed under their account. '
                'Users must ensure that the information entered into the application is accurate and up to date.\n\n'
                'Account Deletion\n\n'
                'Users may delete their account at any time through the application. Once deleted, account access is immediately revoked and cannot be restored.\n\n'
                'Transaction Data Retention\n\n'
                'After account deletion, Income and Expense records are retained for a period of 90 days. '
                'During this period, the data is not accessible to the user and is not shared with third parties. '
                'After 90 days, all retained transaction data is permanently deleted.\n\n'
                'Data Usage and Storage\n\n'
                'All user data is stored securely within the application. '
                'The application does not sell, share, or distribute user data to third parties.\n\n'
                'Limitation of Liability\n\n'
                'The developers of Budget Ease shall not be held responsible for any financial loss, data loss, or decisions made based on information provided by the application.\n\n'
                'Modifications to Terms\n\n'
                'The application reserves the right to update or modify these Terms and Conditions at any time. '
                'Continued use of the application after changes implies acceptance of the updated terms.\n\n'
                'Educational Use Disclaimer\n\n'
                'This application is developed for educational purposes. All data is stored locally on the user’s device.',
          ),
        ],
      ),
    );
  }
}

// ================= EXPANDABLE ITEM =================
class _ExpandableItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _ExpandableItem({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      collapsedIconColor: AppColors.primaryBlue,
      iconColor: AppColors.primaryBlue,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(content, style: const TextStyle(height: 1.5)),
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 70, color: Colors.grey.shade200);
  }
}
