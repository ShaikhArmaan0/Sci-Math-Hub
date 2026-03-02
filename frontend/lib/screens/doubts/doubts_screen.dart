import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/login_required_sheet.dart';
import 'doubt_detail_screen.dart';

class DoubtsScreen extends StatefulWidget {
  const DoubtsScreen({super.key});
  @override
  State<DoubtsScreen> createState() => _DoubtsScreenState();
}

class _DoubtsScreenState extends State<DoubtsScreen> {
  List<Map<String, dynamic>> _doubts = [];
  bool _loading = true;
  String? _selectedSubject;
  final _subjects = ['All', 'Science', 'Mathematics', 'General'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getDoubts(
        subject: _selectedSubject == 'All' ? null : _selectedSubject);
    if (mounted && res['_ok'] == true) {
      setState(() {
        _doubts = List<Map<String, dynamic>>.from(res['doubts'] ?? []);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doubts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _subjects.map((s) {
                final selected = (s == 'All' && _selectedSubject == null) ||
                    s == _selectedSubject;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedSubject = s == 'All' ? null : s);
                      _load();
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: auth.isLoggedIn
            ? () => _showPostDoubt(context)
            : () => showLoginRequiredSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Ask Doubt'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _doubts.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: _doubts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _DoubtCard(
                      doubt: _doubts[i],
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => DoubtDetailScreen(
                                doubtId: _doubts[i]['_id'])));
                        _load();
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🤔', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text('No doubts yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Be the first to ask!', style: TextStyle(color: Colors.grey)),
        ]),
      );

  void _showPostDoubt(BuildContext context) {
    final textCtrl = TextEditingController();
    String subject = 'General';
    String? imageBase64;
    String? imageName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Ask a Doubt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 12),
            // Subject picker
            DropdownButtonFormField<String>(
              value: subject,
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
              items: ['General', 'Science', 'Mathematics'].map((s) =>
                  DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setSt(() => subject = v!),
            ),
            const SizedBox(height: 12),
            // Text field
            TextField(
              controller: textCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Write your doubt here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            // Image picker
            if (imageName != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.image, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(imageName!, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setSt(() { imageBase64 = null; imageName = null; }),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                ]),
              ),
            Row(children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Camera'),
                onPressed: () async {
                  final img = await ImagePicker().pickImage(
                      source: ImageSource.camera, imageQuality: 60);
                  if (img != null) {
                    final bytes = await File(img.path).readAsBytes();
                    setSt(() {
                      imageBase64 = base64Encode(bytes);
                      imageName = img.name;
                    });
                  }
                },
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Gallery'),
                onPressed: () async {
                  final img = await ImagePicker().pickImage(
                      source: ImageSource.gallery, imageQuality: 60);
                  if (img != null) {
                    final bytes = await File(img.path).readAsBytes();
                    setSt(() {
                      imageBase64 = base64Encode(bytes);
                      imageName = img.name;
                    });
                  }
                },
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (textCtrl.text.trim().isEmpty && imageBase64 == null) return;
                  Navigator.pop(ctx);
                  final res = await ApiService.postDoubt(
                    textCtrl.text.trim(),
                    subject: subject,
                    imageBase64: imageBase64,
                  );
                  if (res['_ok'] == true) {
                    _load();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Doubt posted!'),
                            backgroundColor: AppColors.accent));
                    }
                  }
                },
                child: const Text('Post Doubt'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DoubtCard extends StatelessWidget {
  final Map<String, dynamic> doubt;
  final VoidCallback onTap;
  const _DoubtCard({required this.doubt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isResolved = doubt['is_resolved'] == true;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text((doubt['user_name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(doubt['user_name'] ?? 'Student',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(_timeAgo(doubt['created_at'] ?? ''),
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isResolved ? AppColors.accent : AppColors.warning).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(isResolved ? '✅ Resolved' : '❓ Open',
                    style: TextStyle(
                        fontSize: 11,
                        color: isResolved ? AppColors.accent : AppColors.warning,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            if ((doubt['text'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(doubt['text'], maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.4)),
            ],
            if ((doubt['image_base64'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(doubt['image_base64']),
                  height: 120, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(children: [
              _tag(doubt['subject'] ?? 'General', AppColors.primary),
              const Spacer(),
              const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${doubt['answer_count'] ?? 0} answers',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );

  String _timeAgo(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }
}