class LeaderboardEntry {
  final String userId;
  final String fullName;
  final String profileImage;
  final int totalPoints;
  final int streakCount;
  final int quizzesAttempted;
  final double averageScore;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.fullName,
    required this.profileImage,
    required this.totalPoints,
    required this.streakCount,
    required this.quizzesAttempted,
    required this.averageScore,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    userId: json['user_id']?.toString() ?? '',
    fullName: json['full_name'] ?? '',
    profileImage: json['profile_image'] ?? '',
    totalPoints: json['total_points'] ?? 0,
    streakCount: json['streak_count'] ?? 0,
    quizzesAttempted: json['quizzes_attempted'] ?? 0,
    averageScore: (json['average_score'] ?? 0).toDouble(),
    rank: json['rank'] ?? 0,
  );
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['_id']?.toString() ?? '',
    title: json['title'] ?? '',
    message: json['message'] ?? '',
    type: json['type'] ?? '',
    isRead: json['is_read'] ?? false,
    createdAt: json['created_at']?.toString() ?? '',
  );
}

class StudySchedule {
  final String id;
  final String userId;
  final String title;
  final String subject;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final List<String> repeatDays;
  final List<StudySession> sessions;

  StudySchedule({
    required this.id,
    required this.userId,
    required this.title,
    this.subject = '',
    required this.startDate,
    required this.endDate,
    this.startTime = '',
    this.endTime = '',
    this.durationMinutes = 60,
    this.repeatDays = const [],
    this.sessions = const [],
  });

  factory StudySchedule.fromJson(Map<String, dynamic> json) => StudySchedule(
    id: json['_id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    title: json['title'] ?? '',
    subject: json['subject']?.toString() ?? '',
    startDate: json['start_date']?.toString() ?? '',
    endDate: json['end_date']?.toString() ?? '',
    startTime: json['start_time']?.toString() ?? '',
    endTime: json['end_time']?.toString() ?? '',
    durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
    repeatDays: (json['repeat_days'] as List<dynamic>?)
        ?.map((e) => e.toString()).toList() ?? [],
    sessions: (json['sessions'] as List<dynamic>?)
        ?.map((s) => StudySession.fromJson(s))
        .toList() ?? [],
  );
}

class StudySession {
  final String id;
  final String scheduleId;
  final String plannedDate;
  final String? scheduledTime;
  final int? durationMinutes;
  final bool completed;

  StudySession({
    required this.id,
    required this.scheduleId,
    required this.plannedDate,
    this.scheduledTime,
    this.durationMinutes,
    required this.completed,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    id: json['_id']?.toString() ?? '',
    scheduleId: json['schedule_id']?.toString() ?? '',
    plannedDate: json['planned_date']?.toString() ?? '',
    scheduledTime: json['scheduled_time']?.toString(),
    durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
    completed: json['completed'] ?? false,
  );
}

class UserStats {
  final int totalPoints;
  final int streakCount;
  final int totalQuizzesAttempted;
  final double averageScore;
  final double bestScore;
  final int badgesEarned;

  UserStats({
    required this.totalPoints,
    required this.streakCount,
    required this.totalQuizzesAttempted,
    required this.averageScore,
    required this.bestScore,
    required this.badgesEarned,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    totalPoints: json['total_points'] ?? 0,
    streakCount: json['streak_count'] ?? 0,
    totalQuizzesAttempted: json['total_quizzes_attempted'] ?? 0,
    averageScore: (json['average_score'] ?? 0).toDouble(),
    bestScore: (json['best_score'] ?? 0).toDouble(),
    badgesEarned: json['badges_earned'] ?? 0,
  );
}