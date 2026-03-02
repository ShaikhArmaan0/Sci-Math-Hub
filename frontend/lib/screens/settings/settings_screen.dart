import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';

import '../profile/edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prefs = auth.prefs;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── ACCOUNT (now in Edit Profile) ─────────────────────────────────
          _SectionHeader(title: 'Account', icon: Icons.person_outline),
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            subtitle: 'Update name, email, phone & password',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            titleColor: Colors.red,
            iconColor: Colors.red,
            onTap: () => _confirmLogout(context),
          ),

          // ── ACADEMIC ─────────────────────────────────────────────────────
          _SectionHeader(title: 'Academic Preferences', icon: Icons.school_outlined),
          _SettingsTile(
            icon: Icons.class_outlined,
            title: 'Difficulty Level',
            subtitle: prefs.difficultyLevel.capitalize(),
            onTap: () => _showDifficultyDialog(context, auth),
          ),

          // ── NOTIFICATIONS ────────────────────────────────────────────────
          _SectionHeader(title: 'Notifications', icon: Icons.notifications_outlined),
          _SwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Enable Notifications',
            value: prefs.notificationsEnabled,
            onChanged: (v) => auth.updatePreferences({'notifications_enabled': v}),
          ),
          _SwitchTile(
            icon: Icons.today_outlined,
            title: 'Daily Study Reminder',
            value: prefs.studyReminderEnabled,
            onChanged: (v) => auth.updatePreferences({'study_reminder_enabled': v}),
          ),
          _SwitchTile(
            icon: Icons.military_tech_outlined,
            title: 'Badge Alerts',
            value: prefs.badgeAlertEnabled,
            onChanged: (v) => auth.updatePreferences({'badge_alert_enabled': v}),
          ),
          _SwitchTile(
            icon: Icons.quiz_outlined,
            title: 'Quiz Reminders',
            value: prefs.quizReminderEnabled,
            onChanged: (v) => auth.updatePreferences({'quiz_reminder_enabled': v}),
          ),

          // ── APPEARANCE ───────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
          _SwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            value: prefs.darkMode,
            onChanged: (v) => auth.updatePreferences({'dark_mode': v}),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: prefs.language == 'en' ? 'English' : 'हिंदी (Hindi)',
            onTap: () => _showLanguageDialog(context, auth),
          ),

          // ── GAMIFICATION ─────────────────────────────────────────────────
          _SectionHeader(title: 'Gamification', icon: Icons.sports_esports_outlined),
          _SwitchTile(
            icon: Icons.leaderboard_outlined,
            title: 'Show on Leaderboard',
            value: prefs.showOnLeaderboard,
            onChanged: (v) => auth.updatePreferences({'show_on_leaderboard': v}),
          ),
          _SwitchTile(
            icon: Icons.local_fire_department_outlined,
            title: 'Show Streak Publicly',
            value: prefs.showStreakPublicly,
            onChanged: (v) => auth.updatePreferences({'show_streak_publicly': v}),
          ),

          // ── ABOUT ────────────────────────────────────────────────────────
          _SectionHeader(title: 'About', icon: Icons.info_outline),
          _SettingsTile(
            icon: Icons.apps,
            title: 'App Version',
            subtitle: AppConstants.appVersion,
            onTap: null,
          ),
          _SettingsTile(
            icon: Icons.support_agent_outlined,
            title: 'Support',
            subtitle: AppConstants.supportEmail,
            onTap: null,
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => Navigator.pushNamed(context, '/terms'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showEditNameDialog(BuildContext context) {
    final ctrl = TextEditingController(
        text: context.read<AuthProvider>().user?.fullName);
    _showFormDialog(
      context,
      title: 'Edit Name',
      child: AppTextField(
          controller: ctrl,
          label: 'Full Name',
          prefixIcon: Icons.badge_outlined),
      onConfirm: () async {
        if (ctrl.text.trim().isEmpty) return _Result(false, 'Name cannot be empty');
        final ok = await context.read<AuthProvider>().updateProfile(fullName: ctrl.text.trim());
        final err = context.read<AuthProvider>().error;
        return _Result(ok, ok ? 'Name updated!' : (err ?? 'Update failed'));
      },
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    _showFormDialog(
      context,
      title: 'Change Email',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AppTextField(controller: emailCtrl, label: 'New Email', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        AppTextField(controller: passCtrl, label: 'Current Password', prefixIcon: Icons.lock_outline, obscureText: true),
      ]),
      onConfirm: () async {
        if (emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty)
          return _Result(false, 'All fields are required');
        final ok = await context.read<AuthProvider>().changeEmail(emailCtrl.text.trim(), passCtrl.text);
        final err = context.read<AuthProvider>().error;
        return _Result(ok, ok ? 'Email updated!' : (err ?? 'Update failed'));
      },
    );
  }

  void _showChangePhoneDialog(BuildContext context) {
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    _showFormDialog(
      context,
      title: 'Change Phone',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AppTextField(controller: phoneCtrl, label: 'New Phone (10 digits)', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        AppTextField(controller: passCtrl, label: 'Current Password', prefixIcon: Icons.lock_outline, obscureText: true),
      ]),
      onConfirm: () async {
        if (phoneCtrl.text.trim().isEmpty || passCtrl.text.isEmpty)
          return _Result(false, 'All fields are required');
        final ok = await context.read<AuthProvider>().changePhone(phoneCtrl.text.trim(), passCtrl.text);
        final err = context.read<AuthProvider>().error;
        return _Result(ok, ok ? 'Phone updated!' : (err ?? 'Update failed'));
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    _showFormDialog(
      context,
      title: 'Change Password',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AppTextField(controller: currentCtrl, label: 'Current Password', prefixIcon: Icons.lock_outline, obscureText: true),
        const SizedBox(height: 12),
        AppTextField(controller: newCtrl, label: 'New Password (min 6 chars)', prefixIcon: Icons.lock_outline, obscureText: true),
        const SizedBox(height: 12),
        AppTextField(controller: confirmCtrl, label: 'Confirm New Password', prefixIcon: Icons.lock_outline, obscureText: true),
      ]),
      onConfirm: () async {
        if (currentCtrl.text.isEmpty || newCtrl.text.isEmpty)
          return _Result(false, 'All fields are required');
        if (newCtrl.text.length < 6)
          return _Result(false, 'New password must be at least 6 characters');
        if (newCtrl.text != confirmCtrl.text)
          return _Result(false, 'Passwords do not match');
        final ok = await context.read<AuthProvider>().changePassword(currentCtrl.text, newCtrl.text);
        final err = context.read<AuthProvider>().error;
        return _Result(ok, ok ? 'Password changed!' : (err ?? 'Update failed'));
      },
    );
  }

  void _showFormDialog(BuildContext context, {
    required String title,
    required Widget child,
    required Future<_Result> Function() onConfirm,
  }) {
    String? errorMsg;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(errorMsg!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final result = await onConfirm();
                if (result.success) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(result.message),
                      backgroundColor: AppColors.accent,
                    ));
                  }
                } else {
                  setSt(() => errorMsg = result.message);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Difficulty Level'),
        children: ['easy', 'medium', 'hard'].map((d) => RadioListTile<String>(
          title: Text(d.capitalize()),
          value: d,
          groupValue: auth.prefs.difficultyLevel,
          onChanged: (v) {
            auth.updatePreferences({'difficulty_level': v!});
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          RadioListTile<String>(
            title: const Text('English'),
            subtitle: const Text('English'),
            value: 'en',
            groupValue: auth.prefs.language,
            onChanged: (v) {
              auth.updatePreferences({'language': v!});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language changed to English')),
              );
            },
          ),
          RadioListTile<String>(
            title: const Text('हिंदी'),
            subtitle: const Text('Hindi'),
            value: 'hi',
            groupValue: auth.prefs.language,
            onChanged: (v) {
              auth.updatePreferences({'language': v!});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('भाषा हिंदी में बदल दी गई')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted)
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    }
  }
}

class _Result {
  final bool success;
  final String message;
  const _Result(this.success, this.message);
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.5)),
      ]),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color, size: 22),
      title: Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 13)) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right, size: 18, color: Colors.grey) : null,
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}

extension StringExt on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}