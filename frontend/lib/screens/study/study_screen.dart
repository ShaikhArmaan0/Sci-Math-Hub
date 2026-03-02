import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/study_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/other_models.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});
  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isLoggedIn) {
        context.read<StudyProvider>().loadSchedules();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final study = context.watch<StudyProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study Planner')),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('📅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Sign in to manage your study plan'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Sign In'),
          ),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Study Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddDialog(context),
            tooltip: 'New Schedule',
          ),
        ],
      ),
      body: study.loading && study.schedules.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : study.schedules.isEmpty
              ? _emptyState(context)
              : RefreshIndicator(
                  onRefresh: study.loadSchedules,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: study.schedules.length,
                    itemBuilder: (_, i) => _ScheduleCard(
                      schedule: study.schedules[i],
                      study: study,
                    ),
                  ),
                ),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('📅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('No Study Plans Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Create a schedule to stay on track',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Schedule'),
            onPressed: () => _showAddDialog(context),
          ),
        ]),
      );

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    List<String> selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('New Study Schedule'),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Schedule Title *',
                  hintText: 'e.g., Science Revision',
                  prefixIcon: Icon(Icons.title, size: 18),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Subject
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject (optional)',
                  hintText: 'e.g., Mathematics',
                  prefixIcon: Icon(Icons.book_outlined, size: 18),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Study Period', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 15),
                    label: Text(startDate != null ? _fmtDate(startDate!) : 'Start Date',
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx, initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setSt(() => startDate = d);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 15),
                    label: Text(endDate != null ? _fmtDate(endDate!) : 'End Date',
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setSt(() => endDate = d);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              const Text('Daily Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, size: 15),
                    label: Text('Start: ${startTime.format(ctx)}', style: const TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final t = await showTimePicker(context: ctx, initialTime: startTime);
                      if (t != null) setSt(() => startTime = t);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, size: 15),
                    label: Text('End: ${endTime.format(ctx)}', style: const TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final t = await showTimePicker(context: ctx, initialTime: endTime);
                      if (t != null) setSt(() => endTime = t);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              const Text('Repeat on Days', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((day) {
                  final selected = selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day, style: TextStyle(fontSize: 12,
                        color: selected ? AppColors.primary : Colors.grey[700])),
                    selected: selected,
                    onSelected: (v) => setSt(() {
                      if (v) selectedDays.add(day); else selectedDays.remove(day);
                    }),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill title and select dates')));
                  return;
                }
                Navigator.pop(ctx);
                final dur = _calcDuration(startTime, endTime);
                await context.read<StudyProvider>().createSchedule(
                  title: titleCtrl.text.trim(),
                  subject: subjectCtrl.text.trim().isEmpty ? null : subjectCtrl.text.trim(),
                  startDate: _isoDate(startDate!),
                  endDate: _isoDate(endDate!),
                  startTime: _fmtTime(startTime),
                  endTime: _fmtTime(endTime),
                  durationMinutes: dur,
                  repeatDays: selectedDays,
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _isoDate(DateTime d) => d.toIso8601String().split('T')[0];
  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  int _calcDuration(TimeOfDay s, TimeOfDay e) {
    final sm = s.hour * 60 + s.minute;
    final em = e.hour * 60 + e.minute;
    return em > sm ? em - sm : 60;
  }
}

// ── Rich Schedule Card ────────────────────────────────────────────────────────

class _ScheduleCard extends StatefulWidget {
  final StudySchedule schedule;
  final StudyProvider study;
  const _ScheduleCard({required this.schedule, required this.study});
  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sched = widget.schedule;
    final sessions = sched.sessions;
    final completed = sessions.where((s) => s.completed).length;
    final total = sessions.length;
    final progress = total > 0 ? completed / total : 0.0;

    // Determine status color
    final now = DateTime.now();
    final end = DateTime.tryParse(sched.endDate);
    final isExpired = end != null && end.isBefore(DateTime(now.year, now.month, now.day));
    final statusColor = isExpired
        ? Colors.grey
        : progress == 1.0
            ? AppColors.accent
            : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Color accent bar
            Container(
              width: 4, height: 52,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Title
                Text(sched.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                // Subject tag
                if (sched.subject.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 2, bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(sched.subject,
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                // Date range
                Row(children: [
                  const Icon(Icons.date_range, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${_fmtDateStr(sched.startDate)} → ${_fmtDateStr(sched.endDate)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ]),
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _confirmDelete(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
        ),

        // ── Time & Days Info ─────────────────────────────────────────────
        if (sched.startTime.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
            child: Row(children: [
              _InfoChip(icon: Icons.access_time, text:
                  sched.endTime.isNotEmpty ? '${sched.startTime} – ${sched.endTime}' : sched.startTime),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.timer_outlined, text: '${sched.durationMinutes} min'),
              if (sched.repeatDays.isNotEmpty) ...[
                const SizedBox(width: 8),
                _InfoChip(icon: Icons.repeat, text: sched.repeatDays.join(', ')),
              ],
            ]),
          ),

        // ── Progress bar ─────────────────────────────────────────────────
        if (total > 0) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(children: [
              Text('$completed / $total sessions',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(progress * 100).toInt()}%',
                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w700)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              isExpired ? 'Schedule expired' : 'No sessions yet — dates may be in the past',
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
          ),

        // ── Expand / Collapse toggle ─────────────────────────────────────
        if (sessions.isNotEmpty) ...[
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_expanded ? 'Hide Sessions' : 'Show ${sessions.length} Sessions',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16, color: AppColors.primary),
              ]),
            ),
          ),

          // ── Session List ───────────────────────────────────────────────
          if (_expanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Column(
                children: sessions.map((s) => _SessionTile(
                  session: s,
                  scheduleTitle: sched.title,
                  onComplete: s.completed
                      ? null
                      : () => widget.study.markSessionComplete(s.id, sched.id),
                )).toList(),
              ),
            ),
        ],
      ]),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Schedule?'),
        content: Text('Delete "${widget.schedule.title}"? All sessions will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) widget.study.deleteSchedule(widget.schedule.id);
  }

  String _fmtDateStr(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
    } catch (_) { return iso; }
  }
}

// ── Session Tile ──────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final StudySession session;
  final String scheduleTitle;
  final VoidCallback? onComplete;

  const _SessionTile({
    required this.session,
    required this.scheduleTitle,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(session.plannedDate);
    final isToday = d != null &&
        d.year == DateTime.now().year &&
        d.month == DateTime.now().month &&
        d.day == DateTime.now().day;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: session.completed
            ? AppColors.accent.withOpacity(0.06)
            : isToday
                ? AppColors.primary.withOpacity(0.06)
                : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: session.completed
              ? AppColors.accent.withOpacity(0.2)
              : isToday
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: GestureDetector(
          onTap: onComplete,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: session.completed
                  ? AppColors.accent.withOpacity(0.15)
                  : Colors.grey.shade100,
              border: Border.all(
                  color: session.completed ? AppColors.accent : Colors.grey.shade300),
            ),
            child: Icon(
              session.completed ? Icons.check : Icons.circle_outlined,
              size: 16,
              color: session.completed ? AppColors.accent : Colors.grey,
            ),
          ),
        ),
        title: Row(children: [
          // Day + Date
          Expanded(
            child: Text(
              _fmtFull(session.plannedDate),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                decoration: session.completed ? TextDecoration.lineThrough : null,
                color: session.completed ? Colors.grey : null,
              ),
            ),
          ),
          if (isToday && !session.completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Today',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
        ]),
        subtitle: session.scheduledTime != null
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(children: [
                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text(session.scheduledTime!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (session.durationMinutes != null) ...[
                    const Text('  ·  ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Icon(Icons.timer_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text('${session.durationMinutes} min',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ]),
              )
            : null,
        trailing: session.completed
            ? const Text('✅', style: TextStyle(fontSize: 16))
            : onComplete != null
                ? TextButton(
                    onPressed: onComplete,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 28)),
                    child: const Text('Done', style: TextStyle(fontSize: 12)),
                  )
                : null,
      ),
    );
  }

  String _fmtFull(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return '${days[d.weekday-1]}, ${d.day} ${months[d.month-1]} ${d.year}';
    } catch (_) { return iso; }
  }
}

// ── Info Chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ]),
    );
  }
}