// ============================================================
// lib/models/user_model.dart
// ============================================================

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? classId;
  final String profileImage;
  final int totalPoints;
  final int streakCount;
  final bool isActive;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.classId,
    required this.profileImage,
    required this.totalPoints,
    required this.streakCount,
    required this.isActive,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'student',
      classId: json['class_id']?.toString(),
      profileImage: json['profile_image'] ?? '',
      totalPoints: json['total_points'] ?? 0,
      streakCount: json['streak_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'class_id': classId,
    'profile_image': profileImage,
    'total_points': totalPoints,
    'streak_count': streakCount,
    'is_active': isActive,
  };

  UserModel copyWith({
    String? fullName,
    String? profileImage,
    String? classId,
    int? totalPoints,
    int? streakCount,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone,
      role: role,
      classId: classId ?? this.classId,
      profileImage: profileImage ?? this.profileImage,
      totalPoints: totalPoints ?? this.totalPoints,
      streakCount: streakCount ?? this.streakCount,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}

class UserPreferences {
  final bool darkMode;
  final String language;
  final bool notificationsEnabled;
  final bool studyReminderEnabled;
  final bool badgeAlertEnabled;
  final bool quizReminderEnabled;
  final bool showOnLeaderboard;
  final bool showStreakPublicly;
  final String difficultyLevel;
  final String? preferredSubject;
  final String fontSize;
  final bool wifiOnlyDownload;

  UserPreferences({
    this.darkMode = false,
    this.language = 'en',
    this.notificationsEnabled = true,
    this.studyReminderEnabled = true,
    this.badgeAlertEnabled = true,
    this.quizReminderEnabled = true,
    this.showOnLeaderboard = true,
    this.showStreakPublicly = true,
    this.difficultyLevel = 'medium',
    this.preferredSubject,
    this.fontSize = 'medium',
    this.wifiOnlyDownload = false,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      darkMode: json['dark_mode'] ?? false,
      language: json['language'] ?? 'en',
      notificationsEnabled: json['notifications_enabled'] ?? true,
      studyReminderEnabled: json['study_reminder_enabled'] ?? true,
      badgeAlertEnabled: json['badge_alert_enabled'] ?? true,
      quizReminderEnabled: json['quiz_reminder_enabled'] ?? true,
      showOnLeaderboard: json['show_on_leaderboard'] ?? true,
      showStreakPublicly: json['show_streak_publicly'] ?? true,
      difficultyLevel: json['difficulty_level'] ?? 'medium',
      preferredSubject: json['preferred_subject']?.toString(),
      fontSize: json['font_size'] ?? 'medium',
      wifiOnlyDownload: json['wifi_only_download'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'dark_mode': darkMode,
    'language': language,
    'notifications_enabled': notificationsEnabled,
    'study_reminder_enabled': studyReminderEnabled,
    'badge_alert_enabled': badgeAlertEnabled,
    'quiz_reminder_enabled': quizReminderEnabled,
    'show_on_leaderboard': showOnLeaderboard,
    'show_streak_publicly': showStreakPublicly,
    'difficulty_level': difficultyLevel,
    'preferred_subject': preferredSubject,
    'font_size': fontSize,
    'wifi_only_download': wifiOnlyDownload,
  };

  UserPreferences copyWith({
    bool? darkMode,
    String? language,
    bool? notificationsEnabled,
    bool? studyReminderEnabled,
    bool? badgeAlertEnabled,
    bool? quizReminderEnabled,
    bool? showOnLeaderboard,
    bool? showStreakPublicly,
    String? difficultyLevel,
    String? preferredSubject,
    String? fontSize,
    bool? wifiOnlyDownload,
  }) {
    return UserPreferences(
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      studyReminderEnabled: studyReminderEnabled ?? this.studyReminderEnabled,
      badgeAlertEnabled: badgeAlertEnabled ?? this.badgeAlertEnabled,
      quizReminderEnabled: quizReminderEnabled ?? this.quizReminderEnabled,
      showOnLeaderboard: showOnLeaderboard ?? this.showOnLeaderboard,
      showStreakPublicly: showStreakPublicly ?? this.showStreakPublicly,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      preferredSubject: preferredSubject ?? this.preferredSubject,
      fontSize: fontSize ?? this.fontSize,
      wifiOnlyDownload: wifiOnlyDownload ?? this.wifiOnlyDownload,
    );
  }
}
