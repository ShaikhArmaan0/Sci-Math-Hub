import 'package:flutter/material.dart';
import '../models/other_models.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _loading = false;
  int _total = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get loading => _loading;
  int get total => _total;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final res = await ApiService.getNotifications();
    _loading = false;
    if (res['_ok'] == true) {
      _notifications = (res['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
      _total = res['total'] ?? 0;
    }
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await ApiService.markRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = NotificationModel(
        id: _notifications[idx].id,
        title: _notifications[idx].title,
        message: _notifications[idx].message,
        type: _notifications[idx].type,
        isRead: true,
        createdAt: _notifications[idx].createdAt,
      );
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await ApiService.markAllRead();
    _notifications = _notifications.map((n) => NotificationModel(
      id: n.id, title: n.title, message: n.message,
      type: n.type, isRead: true, createdAt: n.createdAt,
    )).toList();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await ApiService.deleteNotification(id);
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
