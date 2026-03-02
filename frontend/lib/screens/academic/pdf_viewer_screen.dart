import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../constants/app_colors.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfName;
  final String pdfUrl;

  const PdfViewerScreen({
    super.key,
    required this.pdfName,
    required this.pdfUrl,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  File? _file;
  bool _loading = true;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _controller;
  bool _showControls = true; // toggle controls visibility

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      setState(() { _loading = true; _error = null; });

      final res = await http.get(Uri.parse(widget.pdfUrl))
          .timeout(const Duration(seconds: 45));

      if (res.statusCode != 200) {
        throw Exception('Server returned ${res.statusCode}');
      }
      if (res.bodyBytes.isEmpty) {
        throw Exception('Empty file received');
      }

      // Detect HTML response (wrong Google Drive URL)
      final first5 = String.fromCharCodes(res.bodyBytes.take(5));
      final ct = res.headers['content-type'] ?? '';
      if (ct.contains('text/html') || first5.startsWith('<!') || first5.toLowerCase().startsWith('<html')) {
        throw Exception(
          'Received an HTML page instead of PDF.\n\n'
          'For Google Drive, use this format:\n'
          'drive.google.com/uc?export=download&id=YOUR_FILE_ID'
        );
      }

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/pdf_$ts.pdf');
      await file.writeAsBytes(res.bodyBytes, flush: true);

      if (mounted) {
        setState(() {
          _file = file;
          _localPath = file.path;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      _controller?.setPage(page);
    }
  }

  void _showPageJumpDialog() {
    final ctrl = TextEditingController(text: '${_currentPage + 1}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Go to page'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 – $_totalPages',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final p = int.tryParse(ctrl.text);
              if (p != null && p >= 1 && p <= _totalPages) {
                _goToPage(p - 1);
              }
              Navigator.pop(context);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.pdfName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (_totalPages > 0)
            Text('$_totalPages pages',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ]),
        actions: [
          if (!_loading && _error == null)
            IconButton(
              icon: Icon(_showControls ? Icons.fullscreen : Icons.fullscreen_exit,
                  color: Colors.white),
              tooltip: _showControls ? 'Hide controls' : 'Show controls',
              onPressed: () => setState(() => _showControls = !_showControls),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _downloadPdf,
            tooltip: 'Reload',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(color: Colors.white),
        const SizedBox(height: 16),
        Text('Loading "${widget.pdfName}"...',
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        const Text('This may take a moment', style: TextStyle(color: Colors.white38, fontSize: 12)),
      ]));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.white70, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Could not load PDF',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade700.withOpacity(0.5)),
              ),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              onPressed: _downloadPdf,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back', style: TextStyle(color: Colors.white54)),
            ),
          ]),
        ),
      );
    }

    return Column(children: [
      // ── Top progress bar ────────────────────────────────────────────
      if (_totalPages > 0)
        LinearProgressIndicator(
          value: _totalPages > 1 ? _currentPage / (_totalPages - 1) : 1.0,
          backgroundColor: Colors.grey.shade800,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          minHeight: 3,
        ),

      // ── PDF Content ─────────────────────────────────────────────────
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: PDFView(
            filePath: _localPath!,
            enableSwipe: true,
            autoSpacing: false,
            pageFling: true,
            swipeHorizontal: false,
            fitPolicy: FitPolicy.BOTH,
            backgroundColor: Colors.grey.shade900,
            onViewCreated: (c) => setState(() => _controller = c),
            onRender: (p) { if (mounted) setState(() => _totalPages = p ?? 0); },
            onPageChanged: (p, t) {
              if (mounted) setState(() {
                _currentPage = p ?? 0;
                _totalPages = t ?? 0;
              });
            },
            onError: (e) { if (mounted) setState(() => _error = 'Render error: $e'); },
            onPageError: (p, e) => debugPrint('Page $p error: $e'),
          ),
        ),
      ),

      // ── Bottom controls bar ─────────────────────────────────────────
      AnimatedSlide(
        offset: _showControls ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: _buildControlsBar(),
        ),
      ),
    ]);
  }

  Widget _buildControlsBar() {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _totalPages - 1;

    return Container(
      padding: EdgeInsets.only(
        left: 8, right: 8, top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(children: [
        // ◀ First page
        _CtrlBtn(
          icon: Icons.first_page,
          enabled: !isFirst,
          onTap: () => _goToPage(0),
          tooltip: 'First page',
        ),
        // ◀ Previous
        _CtrlBtn(
          icon: Icons.chevron_left,
          enabled: !isFirst,
          onTap: () => _goToPage(_currentPage - 1),
          tooltip: 'Previous',
          size: 32,
        ),

        // Page counter — tap to jump
        Expanded(
          child: GestureDetector(
            onTap: _totalPages > 1 ? _showPageJumpDialog : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  '${_currentPage + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  ' / $_totalPages',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14),
                ),
                if (_totalPages > 1) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.edit_outlined,
                      size: 13, color: Colors.white.withOpacity(0.4)),
                ],
              ]),
            ),
          ),
        ),

        // Next ▶
        _CtrlBtn(
          icon: Icons.chevron_right,
          enabled: !isLast,
          onTap: () => _goToPage(_currentPage + 1),
          tooltip: 'Next',
          size: 32,
        ),
        // Last page ▶
        _CtrlBtn(
          icon: Icons.last_page,
          enabled: !isLast,
          onTap: () => _goToPage(_totalPages - 1),
          tooltip: 'Last page',
        ),
      ]),
    );
  }
}

// ── Control button ─────────────────────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String tooltip;
  final double size;

  const _CtrlBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.tooltip,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Icon(icon,
              size: size,
              color: enabled ? Colors.white : Colors.white24),
        ),
      ),
    );
  }
}