import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/academic_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/home_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/study_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/privacy_policy_screen.dart';
import 'screens/settings/terms_screen.dart';

void main() {
  runApp(const SciMathHubApp());
}

class SciMathHubApp extends StatelessWidget {
  const SciMathHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AcademicProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => StudyProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (_, auth, __) => MaterialApp(
          title: 'Sci-Math Hub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: auth.prefs.darkMode ? ThemeMode.dark : ThemeMode.light,
          // ── Hindi language support ──
          locale: auth.prefs.language == 'hi'
              ? const Locale('hi', 'IN')
              : const Locale('en', 'US'),
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('hi', 'IN'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/home': (_) => const HomeScreen(),
            '/notifications': (_) => const NotificationsScreen(),
            '/privacy-policy': (_) => const PrivacyPolicyScreen(),
            '/terms': (_) => const TermsScreen(),
          },
        ),
      ),
    );
  }
}