import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/quiz_provider.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;
  const QuizScreen({super.key, required this.quizId});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await context.read<QuizProvider>().loadQuiz(widget.quizId);
      if (!ok && mounted) Navigator.pop(context);
      else _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _next() {
    final quiz = context.read<QuizProvider>();
    _slideController.reverse().then((_) {
      quiz.nextQuestion();
      _slideController.forward();
    });
  }

  Future<void> _submit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: const Text('Are you sure you want to submit? You cannot change answers after submission.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await context.read<QuizProvider>().submitQuiz();
    if (!mounted) return;
    if (result != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const QuizResultScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    if (quiz.loading && quiz.currentQuiz == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (quiz.currentQuiz == null) return const Scaffold(body: Center(child: Text('Quiz not found')));

    final q = quiz.currentQuestion!;
    final total = quiz.totalQuestions;
    final current = quiz.currentQuestionIndex;
    final selected = quiz.selectedAnswers[q.questionId];

    return Scaffold(
      appBar: AppBar(
        title: Text('Q${current + 1} of $total'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (current + 1) / total,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 4,
          ),
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question counter chips
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: total,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final isAnswered = quiz.selectedAnswers.containsKey(quiz.currentQuiz!.questions[i].questionId);
                          final isCurrent = i == current;
                          return GestureDetector(
                            onTap: () { _slideController.reverse().then((_) { quiz.goToQuestion(i); _slideController.forward(); }); },
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: isCurrent ? AppColors.primary : isAnswered ? AppColors.accent.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: isCurrent ? AppColors.primary : isAnswered ? AppColors.accent : Colors.grey.withOpacity(0.3)),
                              ),
                              child: Center(child: Text('${i + 1}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                      color: isCurrent ? Colors.white : isAnswered ? AppColors.accent : Colors.grey))),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Question card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.heroGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(q.questionText, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, height: 1.5)),
                    ),
                    const SizedBox(height: 20),
                    // Options
                    ...q.options.entries.map((e) => _OptionTile(
                      key: ValueKey(e.key),
                      label: e.key,
                      text: e.value,
                      isSelected: selected == e.key,
                      onTap: () => context.read<QuizProvider>().selectAnswer(q.questionId, e.key),
                    )),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          // Navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                if (current > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () { _slideController.reverse().then((_) { quiz.prevQuestion(); _slideController.forward(); }); },
                      child: const Text('Previous'),
                    ),
                  ),
                if (current > 0) const SizedBox(width: 12),
                Expanded(
                  child: quiz.isLastQuestion
                      ? ElevatedButton(onPressed: _submit, child: const Text('Submit Quiz'))
                      : ElevatedButton(onPressed: _next, child: const Text('Next →')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({super.key, required this.label, required this.text, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey),
              ),
              child: Center(child: Text(label,
                  style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.w700, fontSize: 13))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 14,
              color: isSelected ? AppColors.primary : null,
            ))),
          ],
        ),
      ),
    );
  }
}
