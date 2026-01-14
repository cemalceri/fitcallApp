// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:fitcall/services/notification/notification_router.dart';
import 'package:fitcall/main.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/* -------------------------------------------------------------------------- */
/*                             RENK SABİTLERİ                                  */
/* -------------------------------------------------------------------------- */
const Color _primaryBlue = Color(0xFF0095F6); // Instagram blue
const Color _textPrimary = Color(0xFF262626);
const Color _textSecondary = Color(0xFF8E8E8E);
const Color _dividerColor = Color(0xFFDBDBDB);
const Color _successGreen = Color(0xFF00D26A);
const Color _warningOrange = Color(0xFFFF9500);
const Color _errorRed = Color(0xFFED4956);

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

    // permanentlyDenied için haftada bir sor
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
    final now = DateTime.now();

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
                          color: _primaryBlue,
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
            bottom: BorderSide(color: _dividerColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 22, color: _textPrimary),
          ),
          const Expanded(
            child: Text(
              'Bildirimler',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (_unreadCount > 0)
            GestureDetector(
              onTap: _markAllRead,
              child: Text(
                'Tümünü Okundu Yap',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
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
              color: _textPrimary,
            ),
          ),
        ),
        ...items.map((n) => _NotificationTile(
              notification: n,
              onTap: () => _onNotificationTap(n),
            )),
      ],
    );
  }

  Future<void> _onNotificationTap(NotificationModel notif) async {
    await _markNotificationRead(notif);

    final shouldNavigate = notif.actionType == ActionType.navigateToScreen &&
        notif.actionScreen != null &&
        notif.actionScreen!.isNotEmpty &&
        notif.actionScreen != 'bildirim_detay';

    if (shouldNavigate) {
      try {
        await _router.route(context, notif);
      } catch (e) {
        debugPrint('🔔 Route hatası: $e');
        if (mounted) {
          _showDetailSheet(notif);
        }
      }
    } else {
      _showDetailSheet(notif);
    }
  }

  void _showDetailSheet(NotificationModel notif) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationDetailSheet(notification: notif),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: _textSecondary,
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
              border: Border.all(color: _textPrimary, width: 2),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Etkinlik Yok',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bildirimler burada görünecek',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
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
class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

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
              // Avatar / Icon
              _buildAvatar(),
              const SizedBox(width: 14),
              // Content
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
                          color: _textPrimary,
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
                              fontWeight:
                                  isUnread ? FontWeight.w400 : FontWeight.w400,
                              color: isUnread ? _textPrimary : _textSecondary,
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
                        color: isUnread ? _primaryBlue : _textSecondary,
                        fontWeight:
                            isUnread ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (isUnread) ...[
                const SizedBox(width: 12),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: _primaryBlue,
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
    final iconData = _getNotificationIcon();
    final bgColor = _getIconBgColor();
    final iconColor = _getIconColor();

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

  Color _getIconBgColor() {
    switch (notification.notificationType) {
      case NotificationType.dersTeyidi:
      case NotificationType.telafiIade:
      case NotificationType.paketSatinAlma:
        return _successGreen.withValues(alpha: 0.15);
      case NotificationType.dersIptal:
      case NotificationType.gecikenOdeme:
        return _errorRed.withValues(alpha: 0.15);
      case NotificationType.paketBitiyor:
      case NotificationType.paketSuresiDoluyor:
      case NotificationType.antrenorDegisikligi:
        return _warningOrange.withValues(alpha: 0.15);
      case NotificationType.paketHakGuncelleme:
      case NotificationType.uyelikTanimlandi:
        return _primaryBlue.withValues(alpha: 0.15);
      default:
        return _textSecondary.withValues(alpha: 0.15);
    }
  }

  Color _getIconColor() {
    switch (notification.notificationType) {
      case NotificationType.dersTeyidi:
      case NotificationType.telafiIade:
      case NotificationType.paketSatinAlma:
        return _successGreen;
      case NotificationType.dersIptal:
      case NotificationType.gecikenOdeme:
        return _errorRed;
      case NotificationType.paketBitiyor:
      case NotificationType.paketSuresiDoluyor:
      case NotificationType.antrenorDegisikligi:
        return _warningOrange;
      case NotificationType.paketHakGuncelleme:
      case NotificationType.uyelikTanimlandi:
        return _primaryBlue;
      default:
        return _textSecondary;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}d';
    if (diff.inHours < 24) return '${diff.inHours}s';
    if (diff.inDays < 7) return '${diff.inDays}g';
    return '${diff.inDays ~/ 7}h';
  }
}

/* -------------------------------------------------------------------------- */
/*                       BİLDİRİM DETAY SHEET                                  */
/* -------------------------------------------------------------------------- */
class _NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationDetailSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTypeIcon(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(notification.timestamp),
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
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
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: _textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      foregroundColor: _textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kapat',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
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
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 26, color: color),
    );
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
        return _successGreen;
      case NotificationType.dersIptal:
      case NotificationType.gecikenOdeme:
        return _errorRed;
      case NotificationType.paketBitiyor:
      case NotificationType.paketSuresiDoluyor:
      case NotificationType.antrenorDegisikligi:
        return _warningOrange;
      case NotificationType.paketHakGuncelleme:
      case NotificationType.uyelikTanimlandi:
        return _primaryBlue;
      default:
        return _textSecondary;
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
