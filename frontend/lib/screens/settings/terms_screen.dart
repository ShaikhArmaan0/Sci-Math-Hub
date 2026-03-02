import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(context, 'Terms & Conditions'),
          _subtitle(context, 'Last updated: January 2025'),
          const SizedBox(height: 20),

          _section(context, '1. Acceptance of Terms',
              'By downloading, installing, or using Sci-Math Hub ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App.\n\nThese terms apply to all users of the App, including students, parents, and educators.'),

          _section(context, '2. Educational Purpose',
              'Sci-Math Hub is an educational platform designed to help students of Classes 8, 9, and 10 (Maharashtra Board) learn Science and Mathematics through interactive content, quizzes, and gamification.\n\nThe App is intended for personal, non-commercial educational use only.'),

          _section(context, '3. User Accounts',
              'To access full features of the App, you must create an account with accurate information.\n\nYou are responsible for:\n• Maintaining the confidentiality of your account credentials\n• All activities that occur under your account\n• Ensuring your account information is accurate and up to date\n\nYou must notify us immediately of any unauthorized use of your account.'),

          _section(context, '4. Acceptable Use',
              'You agree to use Sci-Math Hub only for lawful, educational purposes. You must not:\n\n• Attempt to gain unauthorized access to the App or its servers\n• Upload or share any harmful, offensive, or inappropriate content\n• Use the App to harm, harass, or deceive other users\n• Attempt to reverse engineer or copy the App\n• Use automated tools to access or scrape the App\n• Share your account credentials with others'),

          _section(context, '5. Educational Content',
              'The educational content in Sci-Math Hub (notes, videos, quiz questions) is provided for learning purposes and is aligned with the Maharashtra Board curriculum.\n\nWhile we strive for accuracy, we make no warranty that all content is error-free. Educational content should be used alongside official textbooks and classroom instruction.\n\nVideo content is sourced from YouTube and is subject to YouTube\'s terms of service.'),

          _section(context, '6. Gamification and Leaderboard',
              'Sci-Math Hub uses points, badges, streaks, and leaderboards to motivate learning. These are for educational motivation purposes only and have no monetary value.\n\nLeaderboard participation is optional. You may disable your leaderboard visibility in Settings at any time.\n\nWe reserve the right to reset or adjust gamification data to maintain fairness.'),

          _section(context, '7. Intellectual Property',
              'All content, features, and functionality of Sci-Math Hub, including but not limited to text, graphics, logos, and software, are owned by Sci-Math Hub and are protected by applicable intellectual property laws.\n\nYou may not reproduce, distribute, or create derivative works from our content without express written permission.'),

          _section(context, '8. Disclaimer of Warranties',
              'Sci-Math Hub is provided "as is" without any warranties of any kind, either express or implied. We do not warrant that:\n\n• The App will be error-free or uninterrupted\n• The App will meet your specific educational requirements\n• Any errors will be corrected\n\nUse of the App is at your own risk.'),

          _section(context, '9. Limitation of Liability',
              'To the maximum extent permitted by law, Sci-Math Hub shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App, including but not limited to loss of data or educational outcomes.'),

          _section(context, '10. Modifications to Terms',
              'We reserve the right to modify these Terms at any time. We will notify users of significant changes through the App. Continued use of the App after changes constitutes acceptance of the revised Terms.'),

          _section(context, '11. Termination',
              'We reserve the right to suspend or terminate your account if you violate these Terms. You may also delete your account at any time by contacting our support team.'),

          _section(context, '12. Governing Law',
              'These Terms are governed by the laws of India. Any disputes arising from these Terms shall be subject to the jurisdiction of courts in Maharashtra, India.'),

          _section(context, '13. Contact Us',
              'For questions about these Terms and Conditions, please contact:\n\n📧 ${AppConstants.supportEmail}\n\nDeveloped by: ${AppConstants.developerName}'),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.gavel_outlined, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'By using Sci-Math Hub, you acknowledge that you have read, understood, and agree to these Terms & Conditions.',
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