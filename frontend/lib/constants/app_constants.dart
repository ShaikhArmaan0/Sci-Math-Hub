class AppConstants {
  // API Base URL — change this to your server's IP/domain
  // static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000'; // iOS simulator
  // static const String baseUrl = 'http://192.168.137.1:5000'; // Physical device
  static const String baseUrl = 'https://sci-math-hub.onrender.com';

  // Storage Keys
  static const String jwtKey = 'jwt_token';
  static const String userKey = 'user_data';

  // Quiz
  static const int maxQuizAttempts = 5;
  static const int pointsPerCorrect = 10;

  // Pagination
  static const int notifPerPage = 20;

  // App Info
  static const String appName = 'Sci-Math Hub';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Learn Smart. Compete Smart.';
  static const String developerName = 'Sci-Math Hub Team';
  static const String supportEmail = 'support@scimathub.com';
}
