import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, guest, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  UserPreferences _prefs = UserPreferences();
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  UserPreferences get prefs => _prefs;
  String? get error => _error;
  bool get loading => _loading;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  Future<void> initialize() async {
    final token = await ApiService.getToken();
    if (token == null) {
      _status = AuthStatus.guest;
      notifyListeners();
      return;
    }
    final res = await ApiService.getMe();
    if (res['_ok'] == true) {
      _user = UserModel.fromJson(res['user']);
      if (res['user']['preferences'] != null) {
        _prefs = UserPreferences.fromJson(res['user']['preferences']);
      }
      _status = AuthStatus.authenticated;
    } else {
      await ApiService.deleteToken();
      _status = AuthStatus.guest;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? classId,
  }) async {
    _setLoading(true);
    _error = null;
    final res = await ApiService.register({
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      if (classId != null) 'class_id': classId,
    });
    _setLoading(false);
    if (res['_ok'] == true) {
      await ApiService.saveToken(res['token']);
      _user = UserModel.fromJson(res['user']);
      _status = AuthStatus.authenticated;
      notifyListeners();
      _loadPrefsInBackground();
      return true;
    }
    _error = res['error'] ?? 'Registration failed';
    notifyListeners();
    return false;
  }

  Future<bool> login(String identifier, String password) async {
    _setLoading(true);
    _error = null;
    final res = await ApiService.login(identifier, password);
    _setLoading(false);
    if (res['_ok'] == true) {
      await ApiService.saveToken(res['token']);
      _user = UserModel.fromJson(res['user']);
      _status = AuthStatus.authenticated;
      notifyListeners();
      _loadPrefsInBackground();
      return true;
    }
    _error = res['error'] ?? 'Login failed';
    notifyListeners();
    return false;
  }

  void _loadPrefsInBackground() async {
    final prefRes = await ApiService.getPreferences();
    if (prefRes['_ok'] == true) {
      _prefs = UserPreferences.fromJson(prefRes['preferences']);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    await ApiService.deleteToken();
    _user = null;
    _prefs = UserPreferences();
    _status = AuthStatus.guest;
    notifyListeners();
  }

  Future<bool> updateProfile({String? fullName, String? profileImage}) async {
    _setLoading(true);
    _error = null;
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (profileImage != null) data['profile_image'] = profileImage;
    final res = await ApiService.updateProfile(data);
    _setLoading(false);
    if (res['_ok'] == true) {
      _user = UserModel.fromJson(res['user']);
      notifyListeners();
      return true;
    }
    _error = res['error'];
    notifyListeners();
    return false;
  }

  Future<bool> changePassword(String current, String newPass) async {
    _setLoading(true);
    _error = null;
    final res = await ApiService.changePassword(current, newPass);
    _setLoading(false);
    if (res['_ok'] == true) { notifyListeners(); return true; }
    _error = res['error'];
    notifyListeners();
    return false;
  }

  // FIX: refresh _user after email change so UI reflects new email immediately
  Future<bool> changeEmail(String newEmail, String password) async {
    _setLoading(true);
    _error = null;
    final res = await ApiService.changeEmail(newEmail, password);
    _setLoading(false);
    if (res['_ok'] == true) {
      await _refreshUser();
      return true;
    }
    _error = res['error'];
    notifyListeners();
    return false;
  }

  // FIX: refresh _user after phone change so UI reflects new phone immediately
  Future<bool> changePhone(String newPhone, String password) async {
    _setLoading(true);
    _error = null;
    final res = await ApiService.changePhone(newPhone, password);
    _setLoading(false);
    if (res['_ok'] == true) {
      await _refreshUser();
      return true;
    }
    _error = res['error'];
    notifyListeners();
    return false;
  }

  Future<bool> changeClass(String classId) async {
    final res = await ApiService.changeClass(classId);
    if (res['_ok'] == true) {
      _user = UserModel.fromJson(res['user']);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> updatePreferences(Map<String, dynamic> updates) async {
    final res = await ApiService.updatePreferences(updates);
    if (res['_ok'] == true) {
      _prefs = UserPreferences.fromJson(res['preferences']);
      notifyListeners();
    }
  }

  // Private async refresh — awaitable
  Future<void> _refreshUser() async {
    final res = await ApiService.getMe();
    if (res['_ok'] == true) {
      _user = UserModel.fromJson(res['user']);
      notifyListeners();
    }
  }

  // Public non-async version for fire-and-forget calls
  void refreshUser() async { await _refreshUser(); }

  void clearError() { _error = null; notifyListeners(); }
  void _setLoading(bool val) { _loading = val; notifyListeners(); }
}