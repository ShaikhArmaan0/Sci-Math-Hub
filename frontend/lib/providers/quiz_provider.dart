import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/api_service.dart';

class QuizProvider extends ChangeNotifier {
  QuizModel? _currentQuiz;
  QuizSubmissionResult? _lastResult;
  Map<String, String> _selectedAnswers = {};
  int _currentQuestionIndex = 0;
  bool _loading = false;
  bool _submitted = false;
  String? _error;
  List<BadgeModel> _myBadges = [];
  List<AttemptModel> _myAttempts = [];

  QuizModel? get currentQuiz => _currentQuiz;
  QuizSubmissionResult? get lastResult => _lastResult;
  Map<String, String> get selectedAnswers => _selectedAnswers;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get loading => _loading;
  bool get submitted => _submitted;
  String? get error => _error;
  List<BadgeModel> get myBadges => _myBadges;
  List<AttemptModel> get myAttempts => _myAttempts;

  int get totalQuestions => _currentQuiz?.questions.length ?? 0;
  bool get isLastQuestion => _currentQuestionIndex == totalQuestions - 1;
  QuizQuestion? get currentQuestion =>
      (_currentQuiz != null && _currentQuestionIndex < totalQuestions)
          ? _currentQuiz!.questions[_currentQuestionIndex]
          : null;

  Future<bool> loadQuiz(String quizId) async {
    _loading = true;
    _error = null;
    _selectedAnswers = {};
    _currentQuestionIndex = 0;
    _submitted = false;
    _lastResult = null;
    notifyListeners();

    final res = await ApiService.getQuiz(quizId);
    _loading = false;
    if (res['_ok'] == true) {
      _currentQuiz = QuizModel.fromJson(res['quiz']);
      notifyListeners();
      return true;
    }
    _error = res['error'] ?? 'Failed to load quiz';
    notifyListeners();
    return false;
  }

  void selectAnswer(String questionId, String option) {
    _selectedAnswers[questionId] = option;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < totalQuestions - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void prevQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < totalQuestions) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  Future<QuizSubmissionResult?> submitQuiz() async {
    if (_currentQuiz == null) return null;
    _loading = true;
    notifyListeners();

    final res = await ApiService.submitQuiz(_currentQuiz!.id, _selectedAnswers);
    _loading = false;
    if (res['_ok'] == true) {
      _lastResult = QuizSubmissionResult.fromJson(res);
      _submitted = true;
      notifyListeners();
      return _lastResult;
    }
    _error = res['error'] ?? 'Submission failed';
    notifyListeners();
    return null;
  }

  Future<void> loadMyBadges() async {
    final res = await ApiService.getMyBadges();
    if (res['_ok'] == true) {
      _myBadges = (res['badges'] as List).map((b) => BadgeModel.fromJson(b)).toList();
      notifyListeners();
    }
  }

  Future<void> loadMyAttempts() async {
    final res = await ApiService.getMyAttempts();
    if (res['_ok'] == true) {
      _myAttempts = (res['attempts'] as List).map((a) => AttemptModel.fromJson(a)).toList();
      notifyListeners();
    }
  }

  void resetQuiz() {
    _currentQuiz = null;
    _lastResult = null;
    _selectedAnswers = {};
    _currentQuestionIndex = 0;
    _submitted = false;
    _error = null;
    notifyListeners();
  }
}
