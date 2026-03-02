import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(context, 'Privacy Policy'),
          _subtitle(context, 'Last updated: January 2025'),
          const SizedBox(height: 20),

          _section(context, '1. Information We Collect',
              'We collect information you provide directly to us, such as when you create an account, including your full name, email address, phone number, and class information.\n\nWe also collect information about how you use Sci-Math Hub, including quiz attempts, scores, study schedules, and learning progress.'),

          _section(context, '2. How We Use Your Information',
              'We use the information we collect to:\n\n• Provide, maintain, and improve our educational services\n• Track your learning progress and award badges\n• Display your ranking on the leaderboard (only if you opt in)\n• Send you study reminders and notifications (only if you opt in)\n• Communicate with you about your account'),

          _section(context, '3. Data Storage and Security',
              'Your data is stored securely on our servers. We use industry-standard encryption for data transmission and storage. Your password is stored as a secure hash and is never stored in plain text.\n\nWe implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.'),

          _section(context, '4. Sharing of Information',
              'We do not sell, trade, or rent your personal information to third parties.\n\nLeaderboard visibility is optional — you can control whether your name appears on the public leaderboard in Settings → Gamification → Show on Leaderboard.\n\nWe may share anonymized, aggregated data for educational research purposes.'),

          _section(context, '5. Children\'s Privacy',
              'Sci-Math Hub is designed for students of Classes 8, 9, and 10 (ages approximately 13-16). We collect only the minimum information necessary to provide our educational services. We do not knowingly collect personal information from children under 13 without parental consent.'),

          _section(context, '6. Your Rights',
              'You have the right to:\n\n• Access and update your personal information via Settings\n• Change your email, phone number, and password at any time\n• Delete your account by contacting our support team\n• Opt out of notifications and leaderboard participation\n• Request a copy of your data'),

          _section(context, '7. Data Retention',
              'We retain your account information for as long as your account is active. Quiz attempts and progress data are retained to provide continuity in your learning journey. You may request deletion of your account and associated data at any time.'),

          _section(context, '8. Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of significant changes through the app. Continued use of Sci-Math Hub after changes constitutes acceptance of the updated policy.'),

          _section(context, '9. Contact Us',
              'If you have any questions about this Privacy Policy or how we handle your data, please contact us at:\n\n📧 ${AppConstants.supportEmail}\n\nWe aim to respond within 48 hours.'),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your privacy matters to us. Sci-Math Hub is committed to keeping your educational data safe and secure.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String text) => Text(text,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700));

  Widget _subtitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      );

  Widget _section(BuildContext context, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[700], height: 1.6)),
        ]),
      );
}