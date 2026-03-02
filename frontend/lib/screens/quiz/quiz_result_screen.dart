import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/auth_provider.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final result = quiz.lastResult;
    if (result == null) return const Scaffold(body: Center(child: Text('No result')));

    final pct = result.percentage;
    final color = pct >= 80 ? AppColors.accent : pct >= 50 ? AppColors.warning : AppColors.error;
    final emoji = pct >= 80 ? '🎉' : pct >= 50 ? '👍' : '📚';
    final message = pct >= 80 ? 'Excellent Work!' : pct >= 50 ? 'Good Job!' : 'Keep Practicing!';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Score circle
              Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 6),
                  color: color.withOpacity(0.08),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 36)),
                    Text('${pct.toInt()}%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(message, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('${result.score} / ${result.totalQuestions} correct',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
              const SizedBox(height: 24),
              // Points earned
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.streakGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.streakGold.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.streakGold, size: 28),
                    const SizedBox(width: 10),
                    Text('+${result.pointsEarned} XP earned',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.streakGold)),
                  ],
                ),
              ),
              // New badges
              if (result.newBadges.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('🏅 New Badges Unlocked!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...result.newBadges.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(b.iconUrl.isNotEmpty ? b.iconUrl : '🏅', style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.badgeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(b.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      )),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 24),
              // Answer review
              const Text('Answer Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...result.results.asMap().entries.map((e) => _ResultTile(index: e.key, result2: e.value)),
              const SizedBox(height: 24),
              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    quiz.resetQuiz();
                    context.read<AuthProvider>().refreshUser();
                    Navigator.popUntil(context, (r) => r.isFirst);
                  },
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  quiz.resetQuiz();
                  Navigator.pop(context);
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final int index;
  final dynamic result2;
  const _ResultTile({required this.index, required this.result2});

  @override
  Widget build(BuildContext context) {
    final isCorrect = result2.isCorrect as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.accent.withOpacity(0.08) : AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCorrect ? AppColors.accent.withOpacity(0.25) : AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isCorrect ? AppColors.accent : AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Q${index + 1}: Your answer: ${result2.selected.isEmpty ? "—" : result2.selected}  •  Correct: ${result2.correct}',
                  style: TextStyle(fontSize: 12, color: isCorrect ? AppColors.accent : AppColors.error, fontWeight: FontWeight.w500)),
              if (result2.explanation.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(result2.explanation, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ],
          )),
        ],
      ),
    );
  }
}
