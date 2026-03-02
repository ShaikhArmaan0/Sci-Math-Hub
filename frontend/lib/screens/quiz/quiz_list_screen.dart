import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/quiz_model.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/loading_shimmer.dart';
import '../../services/api_service.dart';
import 'quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  final String chapterId;
  final String chapterName;
  const QuizListScreen({super.key, required this.chapterId, required this.chapterName});
  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  List<QuizSummary> _quizzes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final res = await ApiService.getChapterQuizzes(widget.chapterId);
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['_ok'] == true) {
          _quizzes = (res['quizzes'] as List).map((q) => QuizSummary.fromJson(q)).toList();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.chapterName} — Quizzes')),
      body: _loading
          ? const LoadingShimmer()
          : _quizzes.isEmpty
              ? const Center(child: Text('No quizzes available for this chapter yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _quizzes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final quiz = _quizzes[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Text('📝', style: TextStyle(fontSize: 24))),
                        ),
                        title: Text(quiz.title, style: Theme.of(context).textTheme.titleSmall),
                        subtitle: Text('${quiz.questionCount} questions • ${quiz.questionCount * 10} max points'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => QuizScreen(quizId: quiz.id),
                        )),
                      ),
                    );
                  },
                ),
    );
  }
}
