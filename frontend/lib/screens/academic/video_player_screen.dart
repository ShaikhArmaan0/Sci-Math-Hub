import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/academic_models.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  const VideoPlayerScreen({super.key, required this.video});
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadHtmlString(_buildHtml(widget.video.youtubeVideoId));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _buildHtml(String videoId) => '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    * { margin:0; padding:0; background:#000; box-sizing:border-box; }
    html, body { width:100%; height:100vh; overflow:hidden; }
    iframe { width:100%; height:100%; border:none; display:block; }
  </style>
</head>
<body>
  <iframe
    src="https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1&rel=0&modestbranding=1&controls=1"
    allow="autoplay; encrypted-media"
    allowfullscreen>
  </iframe>
</body>
</html>
''';

  void _setLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    setState(() => _isLandscape = true);
  }

  void _setPortrait() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    setState(() => _isLandscape = false);
  }

  Future<void> _openInYoutube() async {
    final appUri = Uri.parse(
        'youtube://www.youtube.com/watch?v=${widget.video.youtubeVideoId}');
    final webUri =
        Uri.parse('https://www.youtube.com/watch?v=${widget.video.youtubeVideoId}');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // ── Landscape: true fullscreen ──────────────────────────────────
    if (isLandscape) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          SizedBox(width: size.width, height: size.height,
              child: WebViewWidget(controller: _controller)),
          if (_loading) _loadingOverlay(),
          // Back button overlay
          Positioned(
            top: 8, left: 8,
            child: SafeArea(child: _OverlayBtn(
              icon: Icons.arrow_back,
              onTap: () { _setPortrait(); Navigator.pop(context); },
            )),
          ),
          // Exit fullscreen
          Positioned(
            top: 8, right: 8,
            child: SafeArea(child: _OverlayBtn(
              icon: Icons.fullscreen_exit,
              onTap: _setPortrait,
            )),
          ),
        ]),
      );
    }

    // ── Portrait: 16:9 player + info panel ─────────────────────────
    final playerH = size.width * 9 / 16;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.video.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (widget.video.duration.isNotEmpty)
            Text(widget.video.duration,
                style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white70),
            tooltip: 'Open in YouTube',
            onPressed: _openInYoutube,
          ),
        ],
      ),
      body: Column(children: [
        // ── Video player ─────────────────────────────────────────────
        SizedBox(
          height: playerH,
          width: size.width,
          child: Stack(children: [
            WebViewWidget(controller: _controller),
            if (_loading) _loadingOverlay(),
          ]),
        ),

        // ── Info panel ───────────────────────────────────────────────
        Expanded(
          child: Container(
            color: const Color(0xFF0F0F0F),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.w700, height: 1.4)),
                const SizedBox(height: 8),
                if (widget.video.duration.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.access_time, color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text(widget.video.duration,
                        style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ]),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 14),

                // Fullscreen button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.fullscreen),
                    label: const Text('Watch Fullscreen',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _setLandscape,
                  ),
                ),
                const SizedBox(height: 10),

                // Open in YouTube button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.play_circle_outline, color: Colors.red),
                    label: const Text('Open in YouTube App',
                        style: TextStyle(color: Colors.white70)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white12),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _openInYoutube,
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text('💡 Rotate phone sideways for fullscreen',
                      style: TextStyle(color: Colors.white24, fontSize: 12)),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _loadingOverlay() => Container(
    color: Colors.black,
    child: const Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.red),
        SizedBox(height: 12),
        Text('Loading video...', style: TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    )),
  );
}

class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _OverlayBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black54,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    ),
  );
}