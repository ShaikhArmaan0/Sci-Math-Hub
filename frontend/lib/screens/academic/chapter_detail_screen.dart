import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../constants/app_colors.dart';
import '../../models/academic_models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/login_required_sheet.dart';
import '../quiz/quiz_list_screen.dart';
import 'pdf_viewer_screen.dart';
import 'video_player_screen.dart';

class ChapterDetailScreen extends StatefulWidget {
  final ChapterModel chapter;
  const ChapterDetailScreen({super.key, required this.chapter});
  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  ChapterModel? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detail =
        await context.read<AcademicProvider>().loadChapter(widget.chapter.id);
    if (mounted) setState(() { _detail = detail; _loading = false; });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chapter = _detail ?? widget.chapter;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chapter ${widget.chapter.chapterNumber}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(widget.chapter.chapterName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Notes'),
            Tab(icon: Icon(Icons.play_circle_outline, size: 18), text: 'Videos'),
            Tab(icon: Icon(Icons.quiz_outlined, size: 18), text: 'Quiz'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _NotesTab(chapter: chapter),
                _VideosTab(chapter: chapter),
                _QuizTab(chapter: chapter, isLoggedIn: auth.isLoggedIn),
              ],
            ),
    );
  }
}

// ── Notes Tab ─────────────────────────────────────────────────────────────────


// ── Notes Tab ─────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  final ChapterModel chapter;
  const _NotesTab({required this.chapter});

  @override
  Widget build(BuildContext context) {
    final pdfs = chapter.allPdfs;

    if (pdfs.isNotEmpty) {
      return _PdfPickerView(chapter: chapter, pdfs: pdfs);
    }

    // No PDFs — show text topics or empty state
    if (chapter.topics.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('📄', style: TextStyle(fontSize: 56)),
          SizedBox(height: 12),
          Text('No notes available yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('PDF notes will appear here once uploaded',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: chapter.topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final topic = chapter.topics[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Center(child: Text('${i + 1}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(topic.topicName,
                    style: Theme.of(context).textTheme.titleSmall)),
              ]),
              if (topic.content.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Text(topic.content,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.6)),
              ],
            ]),
          ),
        );
      },
    );
  }
}

// ── PDF Picker View ───────────────────────────────────────────────────────────

class _PdfPickerView extends StatelessWidget {
  final ChapterModel chapter;
  final List<PdfItem> pdfs;

  const _PdfPickerView({required this.chapter, required this.pdfs});

  // Returns an icon based on PDF name keywords
  IconData _iconForPdf(String name) {
    final n = name.toLowerCase();
    if (n.contains('exercise') || n.contains('practice')) return Icons.edit_outlined;
    if (n.contains('solution') || n.contains('answer')) return Icons.check_circle_outline;
    if (n.contains('question') || n.contains('paper')) return Icons.quiz_outlined;
    if (n.contains('summary') || n.contains('revision')) return Icons.summarize_outlined;
    return Icons.picture_as_pdf_outlined;
  }

  Color _colorForIndex(int i) {
    const colors = [AppColors.primary, AppColors.accent, AppColors.warning, Color(0xFF7C3AED)];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(chapter.chapterName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${pdfs.length} PDF ${pdfs.length == 1 ? "file" : "files"} available',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Select a PDF to open',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ]),
          ),
        ),

        // PDF cards grid (2 columns if 2+, else single column)
        pdfs.length == 1
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _PdfCard(
                    pdf: pdfs[0],
                    index: 0,
                    color: _colorForIndex(0),
                    icon: _iconForPdf(pdfs[0].name),
                    chapterName: chapter.chapterName,
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _PdfCard(
                      pdf: pdfs[i],
                      index: i,
                      color: _colorForIndex(i),
                      icon: _iconForPdf(pdfs[i].name),
                      chapterName: chapter.chapterName,
                    ),
                    childCount: pdfs.length,
                  ),
                ),
              ),
      ],
    );
  }
}

// ── Single PDF Card ───────────────────────────────────────────────────────────

class _PdfCard extends StatelessWidget {
  final PdfItem pdf;
  final int index;
  final Color color;
  final IconData icon;
  final String chapterName;

  const _PdfCard({
    required this.pdf,
    required this.index,
    required this.color,
    required this.icon,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            pdfName: pdf.name,
            pdfUrl: pdf.url,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon area
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(children: [
                Center(child: Icon(icon, size: 34, color: color)),
                // PDF badge
                Positioned(
                  right: 6, bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('PDF',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                pdf.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            // Open button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.open_in_new, size: 12, color: color),
                const SizedBox(width: 4),
                Text('Open', style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Videos Tab ────────────────────────────────────────────────────────────────

class _VideosTab extends StatelessWidget {
  final ChapterModel chapter;
  const _VideosTab({required this.chapter});

  @override
  Widget build(BuildContext context) {
    if (chapter.videos.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('🎬', style: TextStyle(fontSize: 56)),
          SizedBox(height: 12),
          Text('No videos available yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: chapter.videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _VideoCard(video: chapter.videos[i]),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final VideoModel video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play button overlay
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  'https://img.youtube.com/vi/${video.youtubeVideoId}/hqdefault.jpg',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.black87,
                    child: const Center(child: Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 64)),
                  ),
                ),
                // Dark overlay for contrast
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
                // Play button
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                ),
                // Duration badge (top right)
                if (video.duration.isNotEmpty)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(video.duration,
                          style: const TextStyle(color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                // Landscape hint (bottom left)
                Positioned(
                  bottom: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.screen_rotation, color: Colors.white70, size: 11),
                      SizedBox(width: 4),
                      Text('Fullscreen', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    ]),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(video.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (video.duration.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.access_time, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(video.duration,
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                    ],
                  ]),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.play_circle_outline, color: Colors.red, size: 16),
                    SizedBox(width: 5),
                    Text('Watch', style: TextStyle(color: Colors.red,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quiz Tab ──────────────────────────────────────────────────────────────────

class _QuizTab extends StatelessWidget {
  final ChapterModel chapter;
  final bool isLoggedIn;
  const _QuizTab({required this.chapter, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📝', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('Chapter Quiz',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Test your knowledge of ${chapter.chapterName}',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoggedIn
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => QuizListScreen(
                                chapterId: chapter.id,
                                chapterName: chapter.chapterName)))
                    : () => showLoginRequiredSheet(context),
                child: Text(isLoggedIn
                    ? 'Start Quiz'
                    : 'Sign in to attempt Quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}