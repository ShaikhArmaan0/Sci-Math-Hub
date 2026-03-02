import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/other_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _board = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) { setState(() => _loading = false); return; }
    final classId = auth.user?.classId;
    final res = classId != null
        ? await ApiService.getLiveLeaderboard(classId)
        : await ApiService.getGlobalLeaderboard();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['_ok'] == true) {
          _board = (res['leaderboard'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: !auth.isLoggedIn
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('Sign in to see leaderboard', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: const Text('Sign In')),
            ]))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _board.isEmpty
                  ? const Center(child: Text('No data yet. Be the first to top the leaderboard!'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _board.length,
                        itemBuilder: (_, i) {
                          final entry = _board[i];
                          final isMe = entry.userId == auth.user?.id;
                          return _LeaderboardTile(entry: entry, isMe: isMe);
                        },
                      ),
                    ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  const _LeaderboardTile({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final rankColors = [AppColors.badgeGold, AppColors.badgeSilver, AppColors.badgeBronze];
    final isTop3 = entry.rank <= 3;
    final rankColor = isTop3 ? rankColors[entry.rank - 1] : Colors.grey;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.08) : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary.withOpacity(0.4) : isTop3 ? rankColor.withOpacity(0.3) : Theme.of(context).dividerColor,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: isTop3
                ? Text(['🥇', '🥈', '🥉'][entry.rank - 1], style: const TextStyle(fontSize: 24))
                : Text('#${entry.rank}', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey[500], fontSize: 14)),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              entry.fullName.isNotEmpty ? entry.fullName[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(entry.fullName, style: Theme.of(context).textTheme.titleSmall),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                      child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                Text('${entry.quizzesAttempted} quizzes • ${entry.averageScore.toStringAsFixed(1)}% avg',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.totalPoints}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.streakGold)),
              const Text('XP', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
