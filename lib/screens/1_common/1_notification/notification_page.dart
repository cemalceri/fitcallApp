// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:fitcall/services/notification/notification_router.dart';
import 'package:fitcall/main.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> _notifications = const [];
  bool _isLoading = false;
  late final NotificationRouter _router;

  @override
  void initState() {
    super.initState();
    _router = NotificationRouter(navigatorKey: navigatorKey);
    _fetchNotifications();
  }

  Future<List<NotificationModel>> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await NotificationService.fetchNotifications();
      final list = res.data ?? <NotificationModel>[];
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
      return list;
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      ShowMessage.error(context, e.message);
      return <NotificationModel>[];
    } catch (e) {
      setState(() => _isLoading = false);
      ShowMessage.error(context, 'Bildirimler alınamadı: $e');
      return <NotificationModel>[];
    }
  }

  Future<void> _markNotificationRead(NotificationModel notif) async {
    if (notif.isRead) return;
    try {
      final res = await NotificationService.markNotificationsRead([notif.id]);
      final ok = res.data == true;
      if (ok) {
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == notif.id);
          if (idx != -1) _notifications[idx] = notif.copyWith(isRead: true);
        });
        NotificationService.refreshUnreadCount();
      }
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Bildirim güncellenemedi: $e');
    }
  }

  Future<void> _markAllRead() async {
    final ids =
        _notifications.where((n) => !n.isRead).map((e) => e.id).toList();
    if (ids.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await NotificationService.markNotificationsRead(ids);
      final ok = res.data == true;
      setState(() {
        if (ok) {
          _notifications =
              _notifications.map((e) => e.copyWith(isRead: true)).toList();
        }
        _isLoading = false;
      });
      NotificationService.refreshUnreadCount();
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      ShowMessage.error(context, e.message);
    } catch (e) {
      setState(() => _isLoading = false);
      ShowMessage.error(context, 'Bildirim durumu güncellenemedi: $e');
    }
  }

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

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _notifications.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchNotifications,
                          color: const Color(0xFF3B82F6),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              final group = groups[index];
                              return _buildGroup(group['title'] as String,
                                  group['items'] as List<NotificationModel>);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2))
      ]),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: Color(0xFF1E293B))),
              const Expanded(
                  child: Text('Bildirimler',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3))),
              if (_unreadCount > 0)
                TextButton.icon(
                    onPressed: _markAllRead,
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8)),
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Tümü Okundu',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600))),
            ],
          ),
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Row(
                children: [
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('$_unreadCount okunmamış',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6)))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroup(String title, List<NotificationModel> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.3))),
        ...items.map((n) => _NotificationTile(
            notification: n, onTap: () => _onNotificationTap(n))),
      ],
    );
  }

  Future<void> _onNotificationTap(NotificationModel notif) async {
    await _markNotificationRead(notif);
    if (notif.actionType == ActionType.navigateToScreen) {
      await _router.route(context, notif);
    } else {
      await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _NotificationDetailSheet(notification: notif));
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.grey.shade400)),
          const SizedBox(height: 16),
          Text('Bildirimler yükleniyor...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.notifications_off_outlined,
                  size: 36, color: Colors.grey.shade400)),
          const SizedBox(height: 20),
          Text('Bildirim yok',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text('Yeni bildirimler burada görünecek',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isUnread
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                  : Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(notification.title,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isUnread
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: const Color(0xFF1E293B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text(_formatTime(notification.timestamp),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(notification.body,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (isUnread)
                  Container(
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6), shape: BoxShape.circle)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = _getNotificationIcon();
    final iconColor = _getIconColor();
    return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(iconData, size: 20, color: iconColor));
  }

  IconData _getNotificationIcon() {
    switch (notification.notificationType) {
      case NotificationType.dersTeyidi:
        return Icons.event_available_rounded;
      case NotificationType.dersIptal:
        return Icons.event_busy_rounded;
      case NotificationType.gecikenOdeme:
        return Icons.payment_rounded;
      case NotificationType.paketBitiyor:
      case NotificationType.paketSuresiDoluyor:
        return Icons.hourglass_bottom_rounded;
      case NotificationType.paketBitti:
        return Icons.inventory_2_outlined;
      case NotificationType.paketSatinAlma:
        return Icons.shopping_bag_rounded;
      case NotificationType.paketHakGuncelleme:
        return Icons.sync_rounded;
      case NotificationType.telafiKullanildi:
        return Icons.replay_rounded;
      case NotificationType.telafiIade:
        return Icons.undo_rounded;
      case NotificationType.uyelikTanimlandi:
        return Icons.card_membership_rounded;
      case NotificationType.antrenorDegisikligi:
        return Icons.swap_horiz_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor() {
    switch (notification.notificationType) {
      case NotificationType.dersTeyidi:
      case NotificationType.telafiIade:
      case NotificationType.paketSatinAlma:
        return const Color(0xFF10B981);
      case NotificationType.dersIptal:
      case NotificationType.gecikenOdeme:
        return const Color(0xFFEF4444);
      case NotificationType.paketBitiyor:
      case NotificationType.paketSuresiDoluyor:
      case NotificationType.antrenorDegisikligi:
        return const Color(0xFFF59E0B);
      case NotificationType.paketBitti:
        return const Color(0xFF64748B);
      case NotificationType.paketHakGuncelleme:
      case NotificationType.uyelikTanimlandi:
        return const Color(0xFF3B82F6);
      case NotificationType.telafiKullanildi:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
    if (diff.inHours < 24) return '${diff.inHours} sa';
    if (diff.inDays < 7) return '${diff.inDays} gün';
    return '${dt.day}.${dt.month}';
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationDetailSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTypeIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.title,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Text(_formatDateTime(notification.timestamp),
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(notification.body,
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.grey.shade700))),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF475569),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('Kapat',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)))),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildTypeIcon() {
    final iconData = _getIcon();
    final color = _getColor();
    return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14)),
        child: Icon(iconData, size: 24, color: color));
  }

  IconData _getIcon() {
    switch (notification.notificationType) {
      case NotificationType.dersTeyidi:
        return Icons.event_available_rounded;
      case NotificationType.dersIptal:
        return Icons.event_busy_rounded;
      case NotificationType.gecikenOdeme:
        return Icons.payment_rounded;
      case NotificationType.paketBitiyor:
      case NotificationType.paketSuresiDoluyor:
        return Icons.hourglass_bottom_rounded;
      case NotificationType.paketBitti:
        return Icons.inventory_2_outlined;
      case NotificationType.paketSatinAlma:
        return Icons.shopping_bag_rounded;
      case NotificationType.paketHakGuncelleme:
        return Icons.sync_rounded;
      case NotificationType.telafiKullanildi:
        return Icons.replay_rounded;
      case NotificationType.telafiIade:
        return Icons.undo_rounded;
      case NotificationType.uyelikTanimlandi:
        return Icons.card_membership_rounded;
      case NotificationType.antrenorDegisikligi:
        return Icons.swap_horiz_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor() {
    switch (notification.notificationType) {
      case NotificationType.dersTeyidi:
      case NotificationType.telafiIade:
      case NotificationType.paketSatinAlma:
        return const Color(0xFF10B981);
      case NotificationType.dersIptal:
      case NotificationType.gecikenOdeme:
        return const Color(0xFFEF4444);
      case NotificationType.paketBitiyor:
      case NotificationType.paketSuresiDoluyor:
      case NotificationType.antrenorDegisikligi:
        return const Color(0xFFF59E0B);
      case NotificationType.paketBitti:
        return const Color(0xFF64748B);
      case NotificationType.paketHakGuncelleme:
      case NotificationType.uyelikTanimlandi:
        return const Color(0xFF3B82F6);
      case NotificationType.telafiKullanildi:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
