import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.notifications.any((n) => !n.isRead))
            TextButton(onPressed: provider.markAllRead, child: const Text('Mark all read')),
        ],
      ),
      body: provider.loading && provider.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('🔔', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 12),
                  Text('No notifications yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ]))
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.separated(
                    itemCount: provider.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final n = provider.notifications[i];
                      return Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          color: AppColors.error,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => provider.delete(n.id),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _notifColor(n.type).withOpacity(0.12),
                            child: Text(_notifEmoji(n.type), style: const TextStyle(fontSize: 20)),
                          ),
                          title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700)),
                          subtitle: Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: !n.isRead ? Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary)) : null,
                          tileColor: n.isRead ? null : AppColors.primary.withOpacity(0.03),
                          onTap: () => provider.markRead(n.id),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _notifColor(String type) {
    return switch (type) {
      'badge' => AppColors.streakGold,
      'quiz_result' => AppColors.accent,
      _ => AppColors.primary,
    };
  }

  String _notifEmoji(String type) {
    return switch (type) {
      'badge' => '🏅',
      'quiz_result' => '📝',
      _ => '🔔',
    };
  }
}
