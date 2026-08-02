// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/screens/1_common/1_notification/widgets/bildirim_ortak_widgetlari.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:fitcall/services/notification/notification_router.dart';
import 'package:fitcall/main.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fitcall/common/tarih_util.dart';

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
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;

    if (status.isGranted) return;

    if (status.isDenied) {
      await Permission.notification.request();
      return;
    }

    if (status.isPermanentlyDenied) {
      final sonSorulanTarih =
          await SecureStorageService.getValue("notification_permission_prompt");
      final lastAsked =
          sonSorulanTarih != null ? int.tryParse(sonSorulanTarih) ?? 0 : 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const oneWeek = 7 * 24 * 60 * 60 * 1000;

      if (now - lastAsked > oneWeek) {
        SecureStorageService.setValue(
            "notification_permission_prompt", now.toString());
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Bildirim İzni'),
              content: const Text(
                  'Bildirimleri alabilmek için ayarlardan izin vermeniz gerekiyor.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Daha Sonra'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text('Ayarlara Git'),
                ),
              ],
            ),
          );
        }
      }
    }
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
    final yesterday = <NotificationModel>[];
    final thisWeek = <NotificationModel>[];
    final thisMonth = <NotificationModel>[];
    final older = <NotificationModel>[];
    final now = simdiKulup();

    for (final n in _notifications) {
      final d = now.difference(n.timestamp).inDays;
      if (d == 0) {
        today.add(n);
      } else if (d == 1) {
        yesterday.add(n);
      } else if (d < 7) {
        thisWeek.add(n);
      } else if (d < 30) {
        thisMonth.add(n);
      } else {
        older.add(n);
      }
    }
    return [
      {'title': 'Bugün', 'items': today},
      {'title': 'Dün', 'items': yesterday},
      {'title': 'Bu Hafta', 'items': thisWeek},
      {'title': 'Bu Ay', 'items': thisMonth},
      {'title': 'Daha Eski', 'items': older},
    ];
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate();
    return Scaffold(
      backgroundColor: Colors.white,
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
                          color: BildirimRenkleri.anaMavi,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            padding: EdgeInsets.zero,
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
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(
                color: BildirimRenkleri.ayiriciCizgi.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 22, color: BildirimRenkleri.yaziAna),
          ),
          const Expanded(
            child: Text(
              'Bildirimler',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: BildirimRenkleri.yaziAna,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (_unreadCount > 0)
            GestureDetector(
              onTap: _markAllRead,
              child: const Text(
                'Tümünü Okundu Yap',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BildirimRenkleri.anaMavi,
                ),
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BildirimRenkleri.yaziAna,
            ),
          ),
        ),
        ...items.map((n) => _BildirimSatiri(
              notification: n,
              onTap: () => _onNotificationTap(n),
            )),
      ],
    );
  }

  Future<void> _onNotificationTap(NotificationModel notif) async {
    await _markNotificationRead(notif);
    if (!mounted) return;
    await _router.route(context, notif);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: BildirimRenkleri.yaziIkincil,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BildirimRenkleri.yaziAna, width: 2),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: BildirimRenkleri.yaziAna,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Etkinlik Yok',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: BildirimRenkleri.yaziAna,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yeni bildirimler burada görünecek',
            style: TextStyle(
              fontSize: 14,
              color: BildirimRenkleri.yaziIkincil,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         BİLDİRİM TILE - INSTAGRAM TARZI                     */
/* -------------------------------------------------------------------------- */
class _BildirimSatiri extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const _BildirimSatiri({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread ? const Color(0xFFEFF6FF) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: BildirimRenkleri.yaziAna,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: notification.title,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: notification.body,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: isUnread
                                  ? BildirimRenkleri.yaziAna
                                  : BildirimRenkleri.yaziIkincil,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread
                            ? BildirimRenkleri.anaMavi
                            : BildirimRenkleri.yaziIkincil,
                        fontWeight:
                            isUnread ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: 12),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: BildirimRenkleri.anaMavi,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final iconData =
        BildirimGorselYardimci.ikonGetir(notification.notificationType);
    final bgColor = BildirimGorselYardimci.arkaplanRengiGetir(
        notification.notificationType);
    final iconColor =
        BildirimGorselYardimci.renkGetir(notification.notificationType);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 22, color: iconColor),
    );
  }

  String _formatTime(DateTime dt) {
    final now = simdiKulup();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}d';
    if (diff.inHours < 24) return '${diff.inHours}s';
    if (diff.inDays < 7) return '${diff.inDays}g';
    return '${diff.inDays ~/ 7}h';
  }
}
