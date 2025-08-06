// lib/screens/1_common/1_notification/notification_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/1_common/notification_model.dart';
import 'package:fitcall/services/notification_service.dart';
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  NOTIFICATION PAGE – Listeyi burada çeker
/// ─────────────────────────────────────────────────────────────────────────
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> _notifications = const [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  /* -------------------- API -------------------- */

  Future<List<NotificationModel>> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final list = await NotificationService.fetchNotifications(context);
    setState(() {
      _notifications = list;
      _isLoading = false;
    });
    return list;
  }

  Future<void> _markNotificationRead(NotificationModel notif) async {
    if (!notif.isUnread) return;
    final ok =
        await NotificationService.markNotificationsRead(context, [notif.id]);
    if (ok) {
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notif.id);
        if (idx != -1) _notifications[idx] = notif.copyWith(read: true);
      });
    }
  }

  Future<void> _markAllRead() async {
    final ids =
        _notifications.where((n) => n.isUnread).map((e) => e.id).toList();
    if (ids.isEmpty) return;
    setState(() => _isLoading = true);
    final ok = await NotificationService.markNotificationsRead(context, ids);
    if (ok) {
      setState(() {
        _notifications =
            _notifications.map((e) => e.copyWith(read: true)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  /* -------------------- UI Helpers -------------------- */

  List<Map<String, dynamic>> _groupByDate() {
    final today = <NotificationModel>[];
    final last7 = <NotificationModel>[];
    final last30 = <NotificationModel>[];

    final now = DateTime.now();
    for (final n in _notifications) {
      final d = now.difference(n.timestamp).inDays;
      if (d == 0) {
        today.add(n);
      } else if (d < 7) {
        last7.add(n);
      } else if (d < 30) {
        last30.add(n);
      }
    }
    return [
      {'title': 'Bugün', 'items': today},
      {'title': 'Son 7 Gün', 'items': last7},
      {'title': 'Son 30 Gün', 'items': last30},
    ];
  }

  /* -------------------- BUILD -------------------- */

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (_notifications.any((n) => n.isUnread))
            IconButton(
              tooltip: 'Tümünü okundu işaretle',
              icon: const Icon(Icons.mark_email_read_rounded),
              onPressed: _markAllRead,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildNoNotifications()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: groups
                      .map((g) => _buildGroup(g['title'], g['items']))
                      .cast<Widget>()
                      .toList(),
                ),
    );
  }

  Widget _buildGroup(String title, List<NotificationModel> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          ...items.map(_buildTile),
        ],
      ),
    );
  }

  Widget _buildTile(NotificationModel notif) {
    final isUnread = notif.isUnread;
    final bgColor = isUnread ? Colors.blue.shade50 : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: const Icon(Icons.notifications, color: Colors.white, size: 20),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Text(notif.subject),
        trailing: isUnread
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _onNotificationTap(notif),
      ),
    );
  }

  /* -------------------- TAP LOGIC -------------------- */
  Future<void> _onNotificationTap(NotificationModel notif) async {
    // Ders teyit mi?
    if (_isDersTeyit(notif)) {
      await Navigator.pushNamed(
        context,
        routeEnums[SayfaAdi.dersTeyit]!,
        arguments: {
          'notification_id': notif.id,
          'generic_id': notif.genericId, // uye_id
          'model_own_id': notif.modelOwnId // etkinlik_id
        },
      );
      _markNotificationRead(notif);
      return;
    }

    // Normal bildirim → detay sheet
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _NotificationDetailSheet(notification: notif),
    );
    _markNotificationRead(notif);
  }

  bool _isDersTeyit(NotificationModel n) {
    return n.type == NotificationType.DI &&
        n.modelName == 'EtkinlikModel' &&
        n.modelOwnId != null;
  }

  /* -------------------- No Notifications -------------------- */

  Widget _buildNoNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Şu anda herhangi bir bildirim bulunmuyor.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
///  DETAIL BOTTOM SHEET
/// ─────────────────────────────────────────────────────────────────────────
class _NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationDetailSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notification.subject,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(notification.body),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _prettyDate(notification.timestamp),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  static String _prettyDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.difference(now).inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}
