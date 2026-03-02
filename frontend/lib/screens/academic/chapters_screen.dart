import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/academic_models.dart';
import '../../providers/academic_provider.dart';
import 'chapter_detail_screen.dart';

class ChaptersScreen extends StatefulWidget {
  final SubjectModel subject;
  const ChaptersScreen({super.key, required this.subject});
  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicProvider>().loadChapters(widget.subject.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.subject.subjectName)),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(AcademicProvider provider) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return _retry(provider.error!);
    }

    if (provider.chapters.isEmpty) {
      return _retry('No chapters found for this subject.');
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AcademicProvider>().loadChapters(widget.subject.id),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.chapters.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final chapter = provider.chapters[i];
          final progress = provider.getChapterProgress(chapter.id);
          return _ChapterCard(chapter: chapter, progress: progress);
        },
      ),
    );
  }

  Widget _retry(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('😕', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(msg, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.read<AcademicProvider>().loadChapters(widget.subject.id),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final ChapterModel chapter;
  final double progress;
  const _ChapterCard({required this.chapter, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => ChapterDetailScreen(chapter: chapter))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${chapter.chapterNumber}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chapter.chapterName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    if (chapter.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(chapter.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                    if (progress > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: AppColors.accent,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}