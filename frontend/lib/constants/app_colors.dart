import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF4F46E5);      // Indigo
  static const Color secondary = Color(0xFF06B6D4);    // Cyan
  static const Color accent = Color(0xFF22C55E);       // Green
  static const Color warning = Color(0xFFF59E0B);      // Amber
  static const Color error = Color(0xFFEF4444);        // Red

  // Science & Math subject colors
  static const Color scienceGradStart = Color(0xFF10B981);
  static const Color scienceGradEnd = Color(0xFF059669);
  static const Color mathGradStart = Color(0xFF4F46E5);
  static const Color mathGradEnd = Color(0xFF7C3AED);

  // Light Theme
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Theme
  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // Gradient backgrounds
  static const List<Color> heroGradient = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
    Color(0xFF06B6D4),
  ];

  static const List<Color> darkHeroGradient = [
    Color(0xFF1E1B4B),
    Color(0xFF312E81),
    Color(0xFF0C4A6E),
  ];

  // Streak colors
  static const Color streakFire = Color(0xFFFF6B35);
  static const Color streakGold = Color(0xFFFFB800);

  // Badge colors
  static const Color badgeGold = Color(0xFFFFD700);
  static const Color badgeSilver = Color(0xFFC0C0C0);
  static const Color badgeBronze = Color(0xFFCD7F32);
}
