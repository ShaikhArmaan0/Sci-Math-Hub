import 'package:flutter/material.dart';
import '../models/academic_models.dart';
import '../services/api_service.dart';

class AcademicProvider extends ChangeNotifier {
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<ChapterModel> _chapters = [];
  ChapterModel? _currentChapter;
  List<ProgressModel> _progress = [];
  bool _loading = false;
  String? _error;

  List<ClassModel> get classes => _classes;
  List<SubjectModel> get subjects => _subjects;
  List<ChapterModel> get chapters => _chapters;
  ChapterModel? get currentChapter => _currentChapter;
  List<ProgressModel> get progress => _progress;
  bool get loading => _loading;
  String? get error => _error;

  double getChapterProgress(String chapterId) {
    final p = _progress.firstWhere(
      (p) => p.chapterId == chapterId,
      orElse: () => ProgressModel(userId: '', chapterId: chapterId, completionPercentage: 0),
    );
    return p.completionPercentage;
  }

  Future<void> loadClasses() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final res = await ApiService.getClasses();
    _loading = false;
    if (res['_ok'] == true) {
      _classes = (res['classes'] as List).map((c) => ClassModel.fromJson(c)).toList();
    } else {
      _error = res['error'] ?? 'Failed to load classes';
    }
    notifyListeners();
  }

  Future<void> loadSubjects(String classId) async {
    _loading = true;
    _subjects = [];
    _error = null;
    notifyListeners();
    final res = await ApiService.getSubjects(classId);
    _loading = false;
    if (res['_ok'] == true) {
      _subjects = (res['subjects'] as List).map((s) => SubjectModel.fromJson(s)).toList();
    } else {
      _error = res['error'] ?? 'Failed to load subjects';
    }
    notifyListeners();
  }

  Future<void> loadChapters(String subjectId) async {
    _loading = true;
    _chapters = [];
    _error = null;
    notifyListeners();
    final res = await ApiService.getChapters(subjectId);
    _loading = false;
    if (res['_ok'] == true) {
      _chapters = (res['chapters'] as List).map((c) => ChapterModel.fromJson(c)).toList();
    } else {
      _error = res['error'] ?? 'Failed to load chapters';
    }
    notifyListeners();
  }

  Future<ChapterModel?> loadChapter(String chapterId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final res = await ApiService.getChapter(chapterId);
    _loading = false;
    if (res['_ok'] == true) {
      _currentChapter = ChapterModel.fromJson(res['chapter']);
      notifyListeners();
      return _currentChapter;
    }
    _error = res['error'] ?? 'Failed to load chapter';
    notifyListeners();
    return null;
  }

  Future<void> loadProgress() async {
    final res = await ApiService.getMyProgress();
    if (res['_ok'] == true) {
      _progress = (res['progress'] as List).map((p) => ProgressModel.fromJson(p)).toList();
      notifyListeners();
    }
  }

  Future<void> updateProgress(String chapterId, double pct) async {
    await ApiService.updateProgress(chapterId, pct);
    await loadProgress();
  }
}