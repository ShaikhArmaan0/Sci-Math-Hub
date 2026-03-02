import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/gradient_button.dart';

enum _Step { enterContact, enterOtp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Step _step = _Step.enterContact;

  final _contactCtrl = TextEditingController();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _successMsg;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  int _resendSeconds = 0;

  // NOTE: OTP logic requires a backend endpoint /api/auth/forgot-password
  // and /api/auth/verify-otp and /api/auth/reset-password.
  // These are stubbed here — wire to your backend when ready.

  Future<void> _sendOtp() async {
    if (_contactCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter email or phone');
      return;
    }
    setState(() { _loading = true; _error = null; });

    // Call backend to send OTP
    final res = await ApiService.sendOtp(_contactCtrl.text.trim());
    setState(() => _loading = false);

    if (res['_ok'] == true) {
      setState(() {
        _step = _Step.enterOtp;
        _resendSeconds = 60;
        _successMsg = 'OTP sent to ${_contactCtrl.text.trim()}';
      });
      _startResendTimer();
    } else {
      setState(() => _error = res['error'] ?? 'Failed to send OTP');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final res = await ApiService.verifyOtp(_contactCtrl.text.trim(), otp);
    setState(() => _loading = false);

    if (res['_ok'] == true) {
      setState(() { _step = _Step.newPassword; _successMsg = null; });
    } else {
      setState(() => _error = res['error'] ?? 'Invalid OTP');
    }
  }

  Future<void> _resetPassword() async {
    if (_newPassCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final otp = _otpCtrls.map((c) => c.text).join();
    final res = await ApiService.resetPassword(
        _contactCtrl.text.trim(), otp, _newPassCtrl.text);
    setState(() => _loading = false);

    if (res['_ok'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password reset successfully! Please login.'),
            backgroundColor: AppColors.accent),
      );
      Navigator.popUntil(context, (r) => r.settings.name == '/login');
    } else {
      setState(() => _error = res['error'] ?? 'Failed to reset password');
    }
  }

  void _startResendTimer() async {
    while (_resendSeconds > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendSeconds--);
    }
  }

  @override
  void dispose() {
    _contactCtrl.dispose();
    for (var c in _otpCtrls) c.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_step == _Step.enterContact) {
                        Navigator.pop(context);
                      } else if (_step == _Step.enterOtp) {
                        setState(() { _step = _Step.enterContact; _error = null; });
                      } else {
                        setState(() { _step = _Step.enterOtp; _error = null; });
                      }
                    },
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _step == _Step.enterContact
                        ? 'Forgot Password'
                        : _step == _Step.enterOtp
                            ? 'Verify OTP'
                            : 'New Password',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _step == _Step.enterContact
                        ? 'Enter your email or phone to receive OTP'
                        : _step == _Step.enterOtp
                            ? 'Enter the 6-digit code sent to ${_contactCtrl.text}'
                            : 'Choose a strong new password',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Step indicator
                  Row(
                    children: List.generate(3, (i) {
                      final active = i <= _step.index;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // ── Step 1: Enter contact ────────────────────────────────
                  if (_step == _Step.enterContact) ...[
                    AppTextField(
                      controller: _contactCtrl,
                      label: 'Email or Phone Number',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],

                  // ── Step 2: OTP boxes ────────────────────────────────────
                  if (_step == _Step.enterOtp) ...[
                    if (_successMsg != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          Text(_successMsg!,
                              style: const TextStyle(
                                  color: AppColors.accent, fontSize: 13)),
                        ]),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => _OtpBox(
                        controller: _otpCtrls[i],
                        onFilled: () {
                          if (i < 5) {
                            FocusScope.of(context).nextFocus();
                          } else {
                            FocusScope.of(context).unfocus();
                          }
                        },
                      )),
                    ),
                    const SizedBox(height: 20),
                    // Resend
                    Center(
                      child: _resendSeconds > 0
                          ? Text('Resend OTP in ${_resendSeconds}s',
                              style: const TextStyle(color: Colors.grey))
                          : TextButton(
                              onPressed: _sendOtp,
                              child: const Text('Resend OTP'),
                            ),
                    ),
                  ],

                  // ── Step 3: New password ─────────────────────────────────
                  if (_step == _Step.newPassword) ...[
                    AppTextField(
                      controller: _newPassCtrl,
                      label: 'New Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureNew,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _confirmPassCtrl,
                      label: 'Confirm New Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ],

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: 28),

                  GradientButton(
                    label: _step == _Step.enterContact
                        ? 'Send OTP'
                        : _step == _Step.enterOtp
                            ? 'Verify OTP'
                            : 'Reset Password',
                    loading: _loading,
                    onPressed: _step == _Step.enterContact
                        ? _sendOtp
                        : _step == _Step.enterOtp
                            ? _verifyOtp
                            : _resetPassword,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFilled;
  const _OtpBox({required this.controller, required this.onFilled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 54,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (v) { if (v.isNotEmpty) onFilled(); },
      ),
    );
  }
}