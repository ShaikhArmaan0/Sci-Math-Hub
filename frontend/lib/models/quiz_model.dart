class QuizQuestion {
  final String questionId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  QuizQuestion({
    required this.questionId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    questionId: json['question_id'] ?? '',
    questionText: json['question_text'] ?? '',
    optionA: json['option_a'] ?? '',
    optionB: json['option_b'] ?? '',
    optionC: json['option_c'] ?? '',
    optionD: json['option_d'] ?? '',
  );

  Map<String, String> get options => {
    'A': optionA,
    'B': optionB,
    'C': optionC,
    'D': optionD,
  };
}

class QuizModel {
  final String id;
  final String chapterId;
  final String title;
  final String description;
  final List<QuizQuestion> questions;
  final int attemptsUsed;
  final int attemptsRemaining;

  QuizModel({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.description,
    required this.questions,
    required this.attemptsUsed,
    required this.attemptsRemaining,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) => QuizModel(
    id: json['_id']?.toString() ?? '',
    chapterId: json['chapter_id']?.toString() ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    questions: (json['questions'] as List<dynamic>?)
        ?.map((q) => QuizQuestion.fromJson(q))
        .toList() ?? [],
    attemptsUsed: json['attempts_used'] ?? 0,
    attemptsRemaining: json['attempts_remaining'] ?? 5,
  );
}

class QuizResult {
  final String questionId;
  final String selected;
  final String correct;
  final bool isCorrect;
  final String explanation;

  QuizResult({
    required this.questionId,
    required this.selected,
    required this.correct,
    required this.isCorrect,
    required this.explanation,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    questionId: json['question_id'] ?? '',
    selected: json['selected'] ?? '',
    correct: json['correct'] ?? '',
    isCorrect: json['is_correct'] ?? false,
    explanation: json['explanation'] ?? '',
  );
}

class QuizSubmissionResult {
  final int score;
  final int totalQuestions;
  final double percentage;
  final int pointsEarned;
  final List<QuizResult> results;
  final List<BadgeModel> newBadges;

  QuizSubmissionResult({
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.pointsEarned,
    required this.results,
    required this.newBadges,
  });

  factory QuizSubmissionResult.fromJson(Map<String, dynamic> json) => QuizSubmissionResult(
    score: json['score'] ?? 0,
    totalQuestions: json['total_questions'] ?? 0,
    percentage: (json['percentage'] ?? 0).toDouble(),
    pointsEarned: json['points_earned'] ?? 0,
    results: (json['results'] as List<dynamic>?)
        ?.map((r) => QuizResult.fromJson(r))
        .toList() ?? [],
    newBadges: (json['new_badges'] as List<dynamic>?)
        ?.map((b) => BadgeModel.fromJson(b))
        .toList() ?? [],
  );
}

class QuizSummary {
  final String id;
  final String chapterId;
  final String title;
  final String description;
  final int questionCount;

  QuizSummary({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.description,
    required this.questionCount,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) => QuizSummary(
    id: json['_id']?.toString() ?? '',
    chapterId: json['chapter_id']?.toString() ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    questionCount: json['question_count'] ?? 0,
  );
}

class BadgeModel {
  final String id;
  final String badgeName;
  final String description;
  final String iconUrl;
  final String criteriaType;
  final int criteriaValue;
  final String? earnedAt;

  BadgeModel({
    required this.id,
    required this.badgeName,
    required this.description,
    required this.iconUrl,
    required this.criteriaType,
    required this.criteriaValue,
    this.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    final badgeData = json['badge'] ?? json;
    return BadgeModel(
      id: (badgeData['_id'] ?? json['badge_id'] ?? '').toString(),
      badgeName: badgeData['badge_name'] ?? '',
      description: badgeData['description'] ?? '',
      iconUrl: badgeData['icon_url'] ?? '',
      criteriaType: badgeData['criteria_type'] ?? '',
      criteriaValue: badgeData['criteria_value'] ?? 0,
      earnedAt: json['earned_at']?.toString(),
    );
  }
}

class AttemptModel {
  final String id;
  final String quizId;
  final int score;
  final int totalQuestions;
  final double percentage;
  final int pointsEarned;
  final String attemptedAt;

  AttemptModel({
    required this.id,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.pointsEarned,
    required this.attemptedAt,
  });

  factory AttemptModel.fromJson(Map<String, dynamic> json) => AttemptModel(
    id: json['_id']?.toString() ?? '',
    quizId: json['quiz_id']?.toString() ?? '',
    score: json['score'] ?? 0,
    totalQuestions: json['total_questions'] ?? 0,
    percentage: (json['percentage'] ?? 0).toDouble(),
    pointsEarned: json['points_earned'] ?? 0,
    attemptedAt: json['attempted_at']?.toString() ?? '',
  );
}
