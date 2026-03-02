import 'package:flutter/material.dart';
import '../models/other_models.dart';
import '../services/api_service.dart';

class StudyProvider extends ChangeNotifier {
  List<StudySchedule> _schedules = [];
  bool _loading = false;
  String? _error;

  List<StudySchedule> get schedules => _schedules;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadSchedules() async {
    _loading = true;
    notifyListeners();
    final res = await ApiService.getSchedules();
    _loading = false;
    if (res['_ok'] == true) {
      _schedules = (res['schedules'] as List)
          .map((s) => StudySchedule.fromJson(s))
          .toList();
    }
    notifyListeners();
  }

  Future<bool> createSchedule({
    required String title,
    required String startDate,
    required String endDate,
    String? subject,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    List<String> repeatDays = const [],
  }) async {
    _loading = true;
    notifyListeners();
    final res = await ApiService.createSchedule({
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      if (subject != null) 'subject': subject,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (repeatDays.isNotEmpty) 'repeat_days': repeatDays,
    });
    _loading = false;
    if (res['_ok'] == true) {
      await loadSchedules();
      return true;
    }
    _error = res['error'];
    notifyListeners();
    return false;
  }

  Future<bool> deleteSchedule(String id) async {
    final res = await ApiService.deleteSchedule(id);
    if (res['_ok'] == true) {
      _schedules.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> markSessionComplete(String sessionId, String scheduleId) async {
    final res = await ApiService.markSessionComplete(sessionId);
    if (res['_ok'] == true) {
      final sIdx = _schedules.indexWhere((s) => s.id == scheduleId);
      if (sIdx != -1) {
        final old = _schedules[sIdx];
        final updatedSessions = old.sessions.map((s) {
          if (s.id == sessionId) {
            return StudySession(
              id: s.id,
              scheduleId: s.scheduleId,
              plannedDate: s.plannedDate,
              scheduledTime: s.scheduledTime,
              durationMinutes: s.durationMinutes,
              completed: true,
            );
          }
          return s;
        }).toList();
        _schedules[sIdx] = StudySchedule(
          id: old.id,
          userId: old.userId,
          title: old.title,
          subject: old.subject,
          startDate: old.startDate,
          endDate: old.endDate,
          startTime: old.startTime,
          endTime: old.endTime,
          durationMinutes: old.durationMinutes,
          repeatDays: old.repeatDays,
          sessions: updatedSessions,
        );
        notifyListeners();
      }
      return true;
    }
    return false;
  }
}