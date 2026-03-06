import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class DoubtDetailScreen extends StatefulWidget {
  final String doubtId;
  const DoubtDetailScreen({super.key, required this.doubtId});
  @override
  State<DoubtDetailScreen> createState() => _DoubtDetailScreenState();
}

class _DoubtDetailScreenState extends State<DoubtDetailScreen> {
  Map<String, dynamic>? _doubt;
  bool _loading = true;
  final _answerCtrl = TextEditingController();
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getDoubt(widget.doubtId);
    if (mounted && res['_ok'] == true) {
      setState(() {
        _doubt = Map<String, dynamic>.from(res['doubt'] as Map);
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    final res = await ApiService.postAnswer(widget.doubtId, text);
    setState(() => _posting = false);
    if (res['_ok'] == true) {
      _answerCtrl.clear();
      FocusScope.of(context).unfocus();
      await _load();
    }
  }

  Future<void> _upvote(String answerId) async {
    try {
      await ApiService.upvoteAnswer(answerId);
      await _load();
    } catch (e) {
      debugPrint('Upvote error: $e');
    }
  }

  // ── Long-press delete answer ───────────────────────────────────────────────
  Future<void> _confirmDeleteAnswer(String answerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.delete_outline, color: Colors.red, size: 22),
          SizedBox(width: 8),
          Text('Delete Answer', style: TextStyle(fontSize: 17)),
        ]),
        content: const Text(
          'Are you sure you want to delete this answer?',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final res = await ApiService.deleteAnswer(answerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['_ok'] == true ? 'Answer deleted' : 'Failed to delete'),
          backgroundColor: res['_ok'] == true ? Colors.red : Colors.grey,
          behavior: SnackBarBehavior.floating,
        ));
        if (res['_ok'] == true) _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Doubt Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _doubt == null
              ? const Center(child: Text('Doubt not found'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        children: [
                          _DoubtHeader(doubt: _doubt!),
                          const SizedBox(height: 20),
                          _buildAnswersHeader(),
                          const SizedBox(height: 12),
                          ..._buildAnswers(auth),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    _buildInputBar(context, auth),
                  ],
                ),
    );
  }

  Widget _buildAnswersHeader() {
    final count = (_doubt!['answers'] as List? ?? []).length;
    return Row(children: [
      Text('$count ${count == 1 ? "Answer" : "Answers"}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const Spacer(),
      if (_doubt!['is_resolved'] == true)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
          child: const Text('✅ Resolved',
              style: TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600)),
        ),
    ]);
  }

  List<Widget> _buildAnswers(AuthProvider auth) {
    final raw = _doubt!['answers'] as List? ?? [];
    final answers = raw.map((a) => Map<String, dynamic>.from(a as Map)).toList();
    answers.sort((a, b) =>
        ((b['upvotes'] ?? 0) as int).compareTo((a['upvotes'] ?? 0) as int));

    if (answers.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: Column(children: [
            Text('💬', style: TextStyle(fontSize: 40)),
            SizedBox(height: 10),
            Text('No answers yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Be the first to help!', style: TextStyle(color: Colors.grey)),
          ])),
        ),
      ];
    }

    return answers.map((a) {
      final answerId = a['_id']?.toString() ?? '';
      final isOwner = auth.isLoggedIn && a['user_id']?.toString() == auth.user?.id;
      return _AnswerCard(
        answer: a,
        currentUserId: auth.user?.id ?? '',
        isOwner: isOwner,
        onUpvote: auth.isLoggedIn ? () => _upvote(answerId) : null,
        onLongPress: isOwner ? () => _confirmDeleteAnswer(answerId) : null,
      );
    }).toList();
  }

  Widget _buildInputBar(BuildContext context, AuthProvider auth) {
    if (!auth.isLoggedIn) {
      return Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Sign in to answer'),
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _answerCtrl,
            decoration: InputDecoration(
              hintText: 'Write your answer...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _postAnswer(),
          ),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          backgroundColor: AppColors.primary,
          child: _posting
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _postAnswer,
                  padding: EdgeInsets.zero,
                ),
        ),
      ]),
    );
  }
}

// ── Doubt Header ──────────────────────────────────────────────────────────────
class _DoubtHeader extends StatelessWidget {
  final Map<String, dynamic> doubt;
  const _DoubtHeader({required this.doubt});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text((doubt['user_name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doubt['user_name'] ?? 'Student',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(doubt['subject'] ?? 'General',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
          ]),
          if ((doubt['text'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(doubt['text'].toString(), style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
          if ((doubt['image_base64'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(base64Decode(doubt['image_base64'].toString()),
                  width: double.infinity, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Answer Card ───────────────────────────────────────────────────────────────
class _AnswerCard extends StatelessWidget {
  final Map<String, dynamic> answer;
  final String currentUserId;
  final bool isOwner;
  final VoidCallback? onUpvote;
  final VoidCallback? onLongPress;

  const _AnswerCard({
    required this.answer,
    required this.currentUserId,
    required this.isOwner,
    this.onUpvote,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final rawUpvotedBy = answer['upvoted_by'];
    final upvotedBy = rawUpvotedBy is List
        ? rawUpvotedBy.map((e) => e.toString()).toList()
        : <String>[];
    final hasUpvoted = upvotedBy.contains(currentUserId);
    final upvotes = (answer['upvotes'] ?? 0) as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOwner ? Colors.red.shade100 : Colors.grey.shade200,
              width: isOwner ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.accent.withOpacity(0.15),
                child: Text((answer['user_name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(answer['user_name']?.toString() ?? 'Student',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (isOwner)
                  Row(children: [
                    Icon(Icons.touch_app, size: 10, color: Colors.red.shade300),
                    const SizedBox(width: 2),
                    Text('Hold to delete',
                        style: TextStyle(fontSize: 9, color: Colors.red.shade300, fontWeight: FontWeight.w500)),
                  ]),
              ])),
              // Upvote button
              GestureDetector(
                onTap: onUpvote,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: hasUpvoted ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasUpvoted ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      hasUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 14,
                      color: hasUpvoted ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text('$upvotes',
                        style: TextStyle(
                            color: hasUpvoted ? AppColors.primary : Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(answer['text']?.toString() ?? '',
                style: const TextStyle(fontSize: 14, height: 1.5)),
          ]),
        ),
      ),
    );
  }
}