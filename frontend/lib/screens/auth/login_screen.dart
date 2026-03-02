import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/gradient_button.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.login(_identifierCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.heroGradient,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('∑π', style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Text('Welcome back!', style: theme.textTheme.displaySmall?.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Sign in to continue learning', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15)),
                ],
              ),
            ),
            // Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _identifierCtrl,
                      label: 'Email or Phone',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscure,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: const Text('Forgot Password?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    // Error message
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) => auth.error != null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                                ),
                                child: Text(auth.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) => GradientButton(
                        label: 'Sign In',
                        loading: auth.loading,
                        onPressed: _login,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: const Text('Register', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                      child: Text('Continue as Guest', style: TextStyle(color: Colors.grey[500])),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}