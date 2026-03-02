import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _curPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl= TextEditingController();

  bool _obscureCur  = true;
  bool _obscureNew  = true;
  bool _obscureConf = true;
  bool _savingInfo  = false;
  bool _savingPass  = false;

  String? _infoError;
  String? _infoSuccess;
  String? _passError;
  String? _passSuccess;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  // Populate fields from current user — called on init AND after save
  void _populateFields() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text  = user.fullName;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phone;
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl,
        _curPassCtrl, _newPassCtrl, _confPassCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _saveInfo() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user!;
    setState(() { _savingInfo = true; _infoError = null; _infoSuccess = null; });

    String? error;
    bool changed = false;

    final newName  = _nameCtrl.text.trim();
    final newEmail = _emailCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();
    final curPass  = _curPassCtrl.text;

    // Name changed
    if (newName.isNotEmpty && newName != user.fullName) {
      final ok = await auth.updateProfile(fullName: newName);
      if (!ok) error = auth.error ?? 'Failed to update name';
      else changed = true;
    }

    // Email changed — requires current password
    if (error == null && newEmail.isNotEmpty && newEmail != user.email) {
      if (curPass.isEmpty) {
        setState(() { _savingInfo = false; _infoError = 'Enter your current password to change email'; });
        return;
      }
      final ok = await auth.changeEmail(newEmail, curPass);
      if (!ok) error = auth.error ?? 'Failed to update email';
      else changed = true;
    }

    // Phone changed — requires current password
    if (error == null && newPhone.isNotEmpty && newPhone != user.phone) {
      if (curPass.isEmpty) {
        setState(() { _savingInfo = false; _infoError = 'Enter your current password to change phone'; });
        return;
      }
      final ok = await auth.changePhone(newPhone, curPass);
      if (!ok) error = auth.error ?? 'Failed to update phone';
      else changed = true;
    }

    setState(() { _savingInfo = false; });

    if (error != null) {
      setState(() => _infoError = error);
    } else if (changed) {
      _curPassCtrl.clear();
      // Re-populate fields with the freshly updated user data from provider
      _populateFields();
      setState(() => _infoSuccess = '✅ Profile updated successfully!');
    } else {
      setState(() => _infoSuccess = 'No changes detected');
    }
  }

  Future<void> _changePassword() async {
    setState(() { _savingPass = true; _passError = null; _passSuccess = null; });

    if (_curPassCtrl.text.isEmpty) {
      setState(() { _savingPass = false; _passError = 'Enter your current password'; });
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      setState(() { _savingPass = false; _passError = 'New password must be at least 6 characters'; });
      return;
    }
    if (_newPassCtrl.text != _confPassCtrl.text) {
      setState(() { _savingPass = false; _passError = 'Passwords do not match'; });
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(_curPassCtrl.text, _newPassCtrl.text);
    setState(() { _savingPass = false; });

    if (ok) {
      _curPassCtrl.clear();
      _newPassCtrl.clear();
      _confPassCtrl.clear();
      setState(() => _passSuccess = '✅ Password changed successfully!');
    } else {
      setState(() => _passError = auth.error ?? 'Failed to change password. Check current password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch so the avatar/name at top updates live
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Avatar ────────────────────────────────────────────────────
          Center(child: Column(children: [
            Stack(children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  (user?.fullName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 15),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(user?.fullName ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(user?.email ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ])),

          const SizedBox(height: 28),

          // ── Personal Info ─────────────────────────────────────────────
          _SectionCard(
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              _Field(controller: _nameCtrl, label: 'Full Name',
                  icon: Icons.badge_outlined, hint: 'Your full name'),
              const SizedBox(height: 14),
              _Field(controller: _emailCtrl, label: 'Email Address',
                  icon: Icons.email_outlined, hint: 'your@email.com',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _Field(controller: _phoneCtrl, label: 'Phone Number',
                  icon: Icons.phone_outlined, hint: '10-digit number',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _Field(
                controller: _curPassCtrl,
                label: 'Current Password',
                icon: Icons.lock_outline,
                hint: 'Required only if changing email or phone',
                obscure: _obscureCur,
                onToggleObscure: () => setState(() => _obscureCur = !_obscureCur),
              ),
              if (_infoError != null) ...[
                const SizedBox(height: 12),
                _StatusBox(message: _infoError!, isError: true),
              ],
              if (_infoSuccess != null) ...[
                const SizedBox(height: 12),
                _StatusBox(message: _infoSuccess!, isError: false),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savingInfo ? null : _saveInfo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _savingInfo
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Change Password ───────────────────────────────────────────
          _SectionCard(
            title: 'Change Password',
            icon: Icons.lock_outline,
            children: [
              _Field(
                controller: _curPassCtrl,
                label: 'Current Password',
                icon: Icons.lock_outline,
                hint: 'Enter current password',
                obscure: _obscureCur,
                onToggleObscure: () => setState(() => _obscureCur = !_obscureCur),
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _newPassCtrl,
                label: 'New Password',
                icon: Icons.lock_reset_outlined,
                hint: 'Minimum 6 characters',
                obscure: _obscureNew,
                onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _confPassCtrl,
                label: 'Confirm New Password',
                icon: Icons.lock_reset_outlined,
                hint: 'Repeat new password',
                obscure: _obscureConf,
                onToggleObscure: () => setState(() => _obscureConf = !_obscureConf),
              ),
              if (_passError != null) ...[
                const SizedBox(height: 12),
                _StatusBox(message: _passError!, isError: true),
              ],
              if (_passSuccess != null) ...[
                const SizedBox(height: 12),
                _StatusBox(message: _passSuccess!, isError: false),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savingPass ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _savingPass
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Change Password',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        const Divider(),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  const _Field({
    required this.controller, required this.label,
    required this.icon, required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false, this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      suffixIcon: onToggleObscure != null
          ? IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
              onPressed: onToggleObscure)
          : null,
    ),
  );
}

class _StatusBox extends StatelessWidget {
  final String message;
  final bool isError;
  const _StatusBox({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isError ? Colors.red.shade50 : Colors.green.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: isError ? Colors.red.shade200 : Colors.green.shade200),
    ),
    child: Row(children: [
      Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
          color: isError ? Colors.red : Colors.green, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: TextStyle(color: isError ? Colors.red : Colors.green, fontSize: 13))),
    ]),
  );
}