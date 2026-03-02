import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const String _base = AppConstants.baseUrl;
  static const _timeout = Duration(seconds: 10);

  // ── Token Cache (avoids slow keystore read on every request) ──────────────
  static String? _cachedToken;

  static Future<String?> getToken() async {
    _cachedToken ??= await _storage.read(key: AppConstants.jwtKey);
    return _cachedToken;
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: AppConstants.jwtKey, value: token);
  }

  static Future<void> deleteToken() async {
    _cachedToken = null;
    await _storage.delete(key: AppConstants.jwtKey);
  }

  // ── Headers ───────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> get _publicHeaders => {'Content-Type': 'application/json'};

  // ── Safe wrapper — catches timeout & network errors ───────────────────────
  static Future<Map<String, dynamic>> _safe(Future<Map<String, dynamic>> call) async {
    try {
      return await call;
    } on TimeoutException {
      return {'_ok': false, 'error': 'Request timed out. Check your connection.'};
    } catch (_) {
      return {'_ok': false, 'error': 'Network error. Please try again.'};
    }
  }

  // ── HTTP Helpers (with timeout) ───────────────────────────────────────────
  static Future<Map<String, dynamic>> _get(String path, {bool auth = true}) async {
    final headers = auth ? await _authHeaders() : _publicHeaders;
    final res = await http
        .get(Uri.parse('$_base$path'), headers: headers)
        .timeout(_timeout);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final headers = auth ? await _authHeaders() : _publicHeaders;
    final res = await http
        .post(Uri.parse('$_base$path'), headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final res = await http
        .put(Uri.parse('$_base$path'), headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> _delete(String path) async {
    final headers = await _authHeaders();
    final res = await http
        .delete(Uri.parse('$_base$path'), headers: headers)
        .timeout(_timeout);
    return _parse(res);
  }

  static Map<String, dynamic> _parse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    body['_statusCode'] = res.statusCode;
    body['_ok'] = res.statusCode >= 200 && res.statusCode < 300;
    return body;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) =>
      _safe(_post('/api/auth/register', data, auth: false));

  static Future<Map<String, dynamic>> login(String identifier, String password) =>
      _safe(_post('/api/auth/login', {'email_or_phone': identifier, 'password': password}, auth: false));

  static Future<Map<String, dynamic>> getMe() => _safe(_get('/api/auth/me'));

  static Future<Map<String, dynamic>> logout() => _safe(_post('/api/auth/logout', {}));

  // ── User ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) =>
      _safe(_put('/api/user/profile', data));

  static Future<Map<String, dynamic>> changeEmail(String newEmail, String password) =>
      _safe(_put('/api/user/change-email', {'new_email': newEmail, 'password': password}));

  static Future<Map<String, dynamic>> changePhone(String newPhone, String password) =>
      _safe(_put('/api/user/change-phone', {'new_phone': newPhone, 'password': password}));

  static Future<Map<String, dynamic>> changePassword(String current, String newPass) =>
      _safe(_put('/api/user/change-password', {'current_password': current, 'new_password': newPass}));

  static Future<Map<String, dynamic>> changeClass(String classId) =>
      _safe(_put('/api/user/change-class', {'class_id': classId}));

  static Future<Map<String, dynamic>> getPreferences() => _safe(_get('/api/user/preferences'));

  static Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> data) =>
      _safe(_put('/api/user/preferences', data));

  static Future<Map<String, dynamic>> getUserStats() => _safe(_get('/api/user/stats'));

  // ── Academic ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getClasses() => _safe(_get('/api/classes', auth: false));

  static Future<Map<String, dynamic>> getSubjects(String classId) =>
      _safe(_get('/api/classes/$classId/subjects', auth: false));

  static Future<Map<String, dynamic>> getChapters(String subjectId) =>
      _safe(_get('/api/subjects/$subjectId/chapters', auth: false));

  static Future<Map<String, dynamic>> getChapter(String chapterId) =>
      _safe(_get('/api/chapters/$chapterId', auth: false));

  static Future<Map<String, dynamic>> getVideos(String chapterId) =>
      _safe(_get('/api/chapters/$chapterId/videos', auth: false));

  static Future<Map<String, dynamic>> getMyProgress() => _safe(_get('/api/progress'));

  static Future<Map<String, dynamic>> updateProgress(String chapterId, double pct) =>
      _safe(_put('/api/progress/$chapterId', {'completion_percentage': pct}));

  static Future<Map<String, dynamic>> search(String query) =>
      _safe(_get('/api/search?q=${Uri.encodeComponent(query)}', auth: false));

  // ── Quiz ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getQuiz(String quizId) =>
      _safe(_get('/api/quizzes/$quizId'));

  static Future<Map<String, dynamic>> submitQuiz(String quizId, Map<String, String> answers) =>
      _safe(_post('/api/quizzes/$quizId/submit', {'answers': answers}));

  static Future<Map<String, dynamic>> getChapterQuizzes(String chapterId) =>
      _safe(_get('/api/chapters/$chapterId/quizzes'));

  static Future<Map<String, dynamic>> getMyAttempts() => _safe(_get('/api/attempts/my'));

  // ── Badges ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAllBadges() => _safe(_get('/api/badges/', auth: false));

  static Future<Map<String, dynamic>> getMyBadges() => _safe(_get('/api/badges/my'));

  // ── Leaderboard ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getLiveLeaderboard(String classId) =>
      _safe(_get('/api/leaderboard/live/$classId'));

  static Future<Map<String, dynamic>> getGlobalLeaderboard() =>
      _safe(_get('/api/leaderboard/live'));

  static Future<Map<String, dynamic>> getMyRank(String classId) =>
      _safe(_get('/api/leaderboard/my-rank/$classId'));

  // ── Notifications ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getNotifications({int page = 1}) =>
      _safe(_get('/api/notifications/?page=$page&per_page=${AppConstants.notifPerPage}'));

  static Future<Map<String, dynamic>> getUnreadCount() =>
      _safe(_get('/api/notifications/unread-count'));

  static Future<Map<String, dynamic>> markRead(String notifId) =>
      _safe(_put('/api/notifications/$notifId/read', {}));

  static Future<Map<String, dynamic>> markAllRead() =>
      _safe(_put('/api/notifications/read-all', {}));

  static Future<Map<String, dynamic>> deleteNotification(String notifId) =>
      _safe(_delete('/api/notifications/$notifId'));

  // ── Study ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getSchedules() => _safe(_get('/api/study/schedules'));

  static Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> data) =>
      _safe(_post('/api/study/schedules', data));

  static Future<Map<String, dynamic>> deleteSchedule(String scheduleId) =>
      _safe(_delete('/api/study/schedules/$scheduleId'));

  static Future<Map<String, dynamic>> markSessionComplete(String sessionId) =>
      _safe(_put('/api/study/sessions/$sessionId/complete', {}));

  static Future<Map<String, dynamic>> getTodaySessions() => _safe(_get('/api/study/today'));

  // ── Forgot Password / OTP ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendOtp(String contact) =>
      _safe(_post('/api/auth/forgot-password', {'contact': contact}, auth: false));

  static Future<Map<String, dynamic>> verifyOtp(String contact, String otp) =>
      _safe(_post('/api/auth/verify-otp', {'contact': contact, 'otp': otp}, auth: false));

  static Future<Map<String, dynamic>> resetPassword(String contact, String otp, String newPassword) =>
      _safe(_post('/api/auth/reset-password', {'contact': contact, 'otp': otp, 'new_password': newPassword}, auth: false));

  // ── Doubts ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDoubts({int page = 1, String? subject}) =>
      _safe(_get('/api/doubts?page=$page${subject != null ? "&subject=$subject" : ""}', auth: false));

  static Future<Map<String, dynamic>> getDoubt(String id) =>
      _safe(_get('/api/doubts/$id', auth: false));

  static Future<Map<String, dynamic>> postDoubt(String text, {String? subject, String? imageBase64}) =>
      _safe(_post('/api/doubts', {
        'text': text,
        'subject': subject ?? 'General',
        if (imageBase64 != null) 'image_base64': imageBase64,
      }));

  static Future<Map<String, dynamic>> deleteDoubt(String id) =>
      _safe(_delete('/api/doubts/$id'));

  static Future<Map<String, dynamic>> postAnswer(String doubtId, String text) =>
      _safe(_post('/api/doubts/$doubtId/answers', {'text': text}));

  static Future<Map<String, dynamic>> upvoteAnswer(String answerId) =>
      _safe(_post('/api/doubts/answers/$answerId/upvote', {}));

  static Future<Map<String, dynamic>> resolveDoubt(String doubtId) =>
      _safe(_put('/api/doubts/$doubtId/resolve', {}));

  static Future<Map<String, dynamic>> getMyActivity() =>
      _safe(_get('/api/doubts/activity/me'));
}