import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/study_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/login_required_sheet.dart';
import '../academic/classes_screen.dart';
import '../doubts/doubts_screen.dart';
import '../study/study_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List<Map<String, dynamic>> _activity = [];
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<HomeProvider>().loadDashboard();
      if (auth.isLoggedIn) {
        context.read<StudyProvider>().loadSchedules();
        context.read<QuizProvider>().loadMyBadges();
        _loadActivity();
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _loadActivity() async {
    final res = await ApiService.getMyActivity();
    if (mounted && res['_ok'] == true) {
      setState(() => _activity = List<Map<String, dynamic>>.from(res['activities'] ?? []));
    }
  }

  List<_SessionInfo> _getTodaySessions(StudyProvider study) {
    final today = _dateStr(_now);
    final sessions = <_SessionInfo>[];
    for (final sched in study.schedules) {
      for (final s in sched.sessions) {
        if (s.plannedDate == today) {
          sessions.add(_SessionInfo(scheduleTitle: sched.title, session: s, scheduleId: sched.id));
        }
      }
    }
    sessions.sort((a, b) => (a.session.scheduledTime ?? '').compareTo(b.session.scheduledTime ?? ''));
    return sessions;
  }

  _SessionInfo? _getNextSession(StudyProvider study) {
    final today = _dateStr(_now);
    _SessionInfo? next;
    for (final sched in study.schedules) {
      for (final s in sched.sessions) {
        if (!s.completed && s.plannedDate.compareTo(today) > 0) {
          if (next == null || s.plannedDate.compareTo(next.session.plannedDate) < 0) {
            next = _SessionInfo(scheduleTitle: sched.title, session: s, scheduleId: sched.id);
          }
        }
      }
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final home = context.watch<HomeProvider>();
    final study = context.watch<StudyProvider>();
    final quiz = context.watch<QuizProvider>();
    final todaySessions = _getTodaySessions(study);
    final nextSession = _getNextSession(study);
    final activeSession = todaySessions.where((s) => !s.session.completed).isNotEmpty
        ? todaySessions.where((s) => !s.session.completed).first : null;
    final stats = home.stats;

    return RefreshIndicator(
        onRefresh: () async {
          await home.loadDashboard();
          if (auth.isLoggedIn) {
            await study.loadSchedules();
            await _loadActivity();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── HEADER ────────────────────────────────────────────────
              _buildHeader(context, auth, home),

              const SizedBox(height: 20),

              // ── ACTIVE / UPCOMING TASK ────────────────────────────────
              if (auth.isLoggedIn) ...[
                if (activeSession != null)
                  _buildActiveTask(context, activeSession, study)
                else if (nextSession != null)
                  _buildUpcomingTask(context, nextSession)
                else
                  _buildNoScheduleCTA(context),
                const SizedBox(height: 20),
              ],

              // ── STATS CARDS (logged in) ───────────────────────────────
              if (auth.isLoggedIn) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Your Progress', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    _StatCard(icon: Icons.quiz_outlined, color: AppColors.primary,
                        label: 'Quizzes', value: '${stats?.totalQuizzesAttempted ?? 0}'),
                    const SizedBox(width: 10),
                    _StatCard(icon: Icons.trending_up, color: AppColors.accent,
                        label: 'Avg Score', value: '${stats?.averageScore.toStringAsFixed(1) ?? 0}%'),
                    const SizedBox(width: 10),
                    _StatCard(icon: Icons.military_tech_outlined, color: AppColors.streakGold,
                        label: 'Badges', value: '${quiz.myBadges.length}'),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // ── GUEST CTA ─────────────────────────────────────────────
              if (!auth.isLoggedIn) ...[
                _buildGuestCTA(context),
                const SizedBox(height: 20),
              ],

              // ── TODAY'S SCHEDULE ──────────────────────────────────────
              if (auth.isLoggedIn && todaySessions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Text("Today's Schedule", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyScreen())),
                      child: const Text('See All', style: TextStyle(fontSize: 12)),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                ...todaySessions.map((info) => _buildSessionTile(context, info, study)),
                const SizedBox(height: 20),
              ],

              // ── QUICK ACCESS ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Quick Access', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _QuickCard(emoji: '⚗️', label: 'Science', color: AppColors.accent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassesScreen()))),
                  const SizedBox(width: 10),
                  _QuickCard(emoji: '📐', label: 'Maths', color: AppColors.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassesScreen()))),
                  const SizedBox(width: 10),
                  _QuickCard(emoji: '🤔', label: 'Doubts', color: AppColors.warning,
                      onTap: auth.isLoggedIn
                          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtsScreen()))
                          : () => showLoginRequiredSheet(context)),
                  const SizedBox(width: 10),
                  _QuickCard(emoji: '📅', label: 'Planner', color: const Color(0xFF7C3AED),
                      onTap: auth.isLoggedIn
                          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyScreen()))
                          : () => showLoginRequiredSheet(context)),
                ]),
              ),
              const SizedBox(height: 20),

              // ── RECENT ACTIVITY ───────────────────────────────────────
              if (auth.isLoggedIn) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (_activity.isNotEmpty)
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtsScreen())),
                        child: const Text('View All', style: TextStyle(fontSize: 12)),
                      ),
                  ]),
                ),
                const SizedBox(height: 8),
                if (_activity.isEmpty)
                  _buildEmptyActivity(context)
                else
                  ..._activity.take(4).map((a) => _buildActivityTile(a)),
                const SizedBox(height: 20),
              ],

              // ── MOTIVATIONAL BANNER ───────────────────────────────────
              _buildMotivationalBanner(context, auth),

              const SizedBox(height: 40),
            ],
          ),
        ),
      );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AuthProvider auth, HomeProvider home) {
    final hour = _now.hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final name = auth.isLoggedIn ? auth.user!.fullName.split(' ').first : 'Explorer';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: AppColors.heroGradient),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greeting, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
            const SizedBox(height: 2),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          ])),
          if (auth.isLoggedIn) ...[
            StreakBadge(count: auth.user!.streakCount),
            const SizedBox(width: 12),
            Stack(children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
              if (home.unreadNotifications > 0)
                Positioned(right: 8, top: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                    child: Center(child: Text('${home.unreadNotifications}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
                  )),
            ]),
          ] else
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ]),
        if (auth.isLoggedIn) ...[
          const SizedBox(height: 20),
          // XP + today's progress mini summary
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: AppColors.streakGold, size: 18),
                const SizedBox(width: 6),
                Text('${auth.user!.totalPoints} XP',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
            ),
          ]),
        ],
      ]),
    );
  }

  // ── Active Task ───────────────────────────────────────────────────────────
  Widget _buildActiveTask(BuildContext context, _SessionInfo info, StudyProvider study) {
    final timeStr = info.session.scheduledTime;
    final duration = info.session.durationMinutes ?? 60;
    String timeLabel = '';
    bool isOngoing = false;

    if (timeStr != null) {
      try {
        final parts = timeStr.split(':');
        final start = DateTime(_now.year, _now.month, _now.day, int.parse(parts[0]), int.parse(parts[1]));
        final end = start.add(Duration(minutes: duration));
        if (_now.isAfter(start) && _now.isBefore(end)) {
          final rem = end.difference(_now);
          timeLabel = '${rem.inMinutes} min remaining';
          isOngoing = true;
        } else if (_now.isBefore(start)) {
          final until = start.difference(_now);
          timeLabel = until.inMinutes < 60 ? 'Starts in ${until.inMinutes} min' : 'Starts at $timeStr';
        }
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: isOngoing
              ? [AppColors.accent, const Color(0xFF15803D)]
              : [AppColors.primary, const Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: (isOngoing ? AppColors.accent : AppColors.primary).withOpacity(0.3),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text(isOngoing ? '🟢  In Progress' : '⏰  Today',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            if (timeLabel.isNotEmpty)
              Text(timeLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text(info.scheduleTitle,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.access_time, color: Colors.white70, size: 15),
            const SizedBox(width: 4),
            Text(timeStr ?? 'Today', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(width: 14),
            const Icon(Icons.timer_outlined, color: Colors.white70, size: 15),
            const SizedBox(width: 4),
            Text('$duration min', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          if (isOngoing) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => study.markSessionComplete(info.session.id, info.scheduleId),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: AppColors.accent),
                child: const Text('Mark as Complete ✅', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Upcoming Task ─────────────────────────────────────────────────────────
  Widget _buildUpcomingTask(BuildContext context, _SessionInfo info) {
    final planned = DateTime.tryParse(info.session.plannedDate);
    String daysLabel = '';
    if (planned != null) {
      final diff = planned.difference(DateTime(_now.year, _now.month, _now.day));
      daysLabel = diff.inDays == 1 ? 'Tomorrow' : 'In ${diff.inDays} days';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Next Session', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text(info.scheduleTitle,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text('${info.session.scheduledTime ?? ''} · $daysLabel',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ])),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ]),
      ),
    );
  }

  // ── No Schedule CTA ───────────────────────────────────────────────────────
  Widget _buildNoScheduleCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Text('📅', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('No study plan yet!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const Text('Create a schedule to track your daily study sessions.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyScreen())),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning, foregroundColor: Colors.white,
                  minimumSize: const Size(120, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 16)),
              child: const Text('Create Plan', style: TextStyle(fontSize: 13)),
            ),
          ])),
        ]),
      ),
    );
  }

  // ── Session tile ──────────────────────────────────────────────────────────
  Widget _buildSessionTile(BuildContext context, _SessionInfo info, StudyProvider study) {
    final s = info.session;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: s.completed ? AppColors.accent.withOpacity(0.06) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: s.completed ? AppColors.accent.withOpacity(0.2) : Colors.grey.shade200),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: s.completed ? null : () => study.markSessionComplete(s.id, info.scheduleId),
            child: Icon(s.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: s.completed ? AppColors.accent : Colors.grey, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(info.scheduleTitle, style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14,
                decoration: s.completed ? TextDecoration.lineThrough : null,
                color: s.completed ? Colors.grey : null)),
            if (s.scheduledTime != null)
              Text('${s.scheduledTime}  ·  ${s.durationMinutes ?? 60} min',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          if (s.completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Text('Done ✅', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
    );
  }

  // ── Guest CTA ─────────────────────────────────────────────────────────────
  Widget _buildGuestCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Join Sci-Math Hub! 🎓',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Sign up to attempt quizzes, earn badges, track progress and compete on the leaderboard!',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
              child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white)),
              child: const Text('Sign In'),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Empty Activity ────────────────────────────────────────────────────────
  Widget _buildEmptyActivity(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(children: [
          const Text('🌱', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text('No activity yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Attempt a quiz, ask a doubt or watch a video to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ]),
      ),
    );
  }

  // ── Activity Tile ─────────────────────────────────────────────────────────
  Widget _buildActivityTile(Map<String, dynamic> a) {
    final icons = {
      'doubt_posted': '🤔', 'doubt_answered': '💡',
      'quiz_attempted': '📝', 'chapter_viewed': '📖',
    };
    final labels = {
      'doubt_posted': 'Asked a doubt', 'doubt_answered': 'Answered a doubt',
      'quiz_attempted': 'Attempted a quiz', 'chapter_viewed': 'Viewed chapter',
    };
    final type = a['type'] ?? '';
    final emoji = icons[type] ?? '📌';
    final label = labels[type] ?? type;
    final title = (a['title'] ?? '') as String;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (title.isNotEmpty)
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Text(_timeAgo(a['created_at'] ?? ''),
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ),
    );
  }

  // ── Motivational Banner ───────────────────────────────────────────────────
  Widget _buildMotivationalBanner(BuildContext context, AuthProvider auth) {
    final quotes = [
      ('🚀', 'Keep Learning!', 'Every chapter brings you closer to your goal.'),
      ('🔥', 'Stay Consistent!', 'Daily study habits make the biggest difference.'),
      ('🏆', 'You Can Do It!', 'Success is the sum of small efforts repeated daily.'),
      ('💡', 'Stay Curious!', 'Questions are the beginning of understanding.'),
    ];
    final q = quotes[_now.day % quotes.length];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accent.withOpacity(0.15), AppColors.primary.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.2)),
        ),
        child: Row(children: [
          Text(q.$1, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            Text(q.$3, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.3)),
          ])),
        ]),
      ),
    );
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

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

class _SessionInfo {
  final String scheduleTitle, scheduleId;
  final dynamic session;
  const _SessionInfo({required this.scheduleTitle, required this.session, required this.scheduleId});
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _StatCard({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String emoji, label;
  final Color color;
  final VoidCallback onTap;
  const _QuickCard({required this.emoji, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}