import 'package:flutter/material.dart';
import '../models/other_models.dart';
import '../services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  List<StudySession> _todaySessions = [];
  int _unreadNotifications = 0;
  UserStats? _stats;
  bool _loading = false;

  List<StudySession> get todaySessions => _todaySessions;
  int get unreadNotifications => _unreadNotifications;
  UserStats? get stats => _stats;
  bool get loading => _loading;

  Future<void> loadDashboard() async {
    _loading = true;
    notifyListeners();

    // Load all dashboard data in parallel
    await Future.wait([
      _loadTodaySessions(),
      _loadUnreadCount(),
      _loadStats(),
    ]);

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadTodaySessions() async {
    final res = await ApiService.getTodaySessions();
    if (res['_ok'] == true) {
      _todaySessions = (res['sessions'] as List)
          .map((s) => StudySession.fromJson(s))
          .toList();
    }
  }

  Future<void> _loadUnreadCount() async {
    final res = await ApiService.getUnreadCount();
    if (res['_ok'] == true) {
      _unreadNotifications = res['unread_count'] ?? 0;
    }
  }

  Future<void> _loadStats() async {
    final res = await ApiService.getUserStats();
    if (res['_ok'] == true) {
      _stats = UserStats.fromJson(res['stats']);
    }
  }

  void decrementUnread() {
    if (_unreadNotifications > 0) {
      _unreadNotifications--;
      notifyListeners();
    }
  }

  void clearUnread() {
    _unreadNotifications = 0;
    notifyListeners();
  }
}
