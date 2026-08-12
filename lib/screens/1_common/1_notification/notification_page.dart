// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/screens/1_common/1_notification/widgets/bildirim_ortak_widgetlari.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/fcm_service.dart';
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
      // İzin verilmiş olabilir: hem iOS'ta token ancak izinden sonra geliyor
      // hem de cihaz kaydındaki bildirim_izni alanı böylece güncel kalıyor.
      await sendFCMDevice();
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

  /// Sunucu tarafında toplu işaretleme yapar.
  ///
  /// Eskiden ekrandaki okunmamışların id'leri gönderiliyordu; liste ucu son 50
  /// kaydı döndüğü için daha eski okunmamışlar işaretlenmiyor ve zildeki sayı
  /// (tüm okunmamışları sayar) "9+" olarak takılı kalıyordu.
  Future<void> _markAllRead() async {
    if (_unreadCount == 0) return;
    setState(() => _isLoading = true);
    try {
      await NotificationService.markAllNotificationsRead();
      setState(() {
        _notifications =
            _notifications.map((e) => e.copyWith(isRead: true)).toList();
        _isLoading = false;
      });
      await NotificationService.refreshUnreadCount();
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      ShowMessage.error(context, e.message);
    } catch (e) {
      setState(() => _isLoading = false);
      ShowMessage.error(context, 'Bildirim durumu güncellenemedi: $e');
    }
  }

  Future<void> _deleteAll() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm bildirimler silinsin mi?'),
        content: const Text(
            'Bu profildeki tüm bildirimler listeden kaldırılacak. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Sil', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (onay != true) return;

    setState(() => _isLoading = true);
    try {
      await NotificationService.deleteAllNotifications();
      setState(() {
        _notifications = const [];
        _isLoading = false;
      });
      await NotificationService.refreshUnreadCount();
      if (!mounted) return;
      ShowMessage.success(context, 'Tüm bildirimler silindi.');
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      ShowMessage.error(context, e.message);
    } catch (e) {
      setState(() => _isLoading = false);
      ShowMessage.error(context, 'Bildirimler silinemedi: $e');
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                          color: context.bildirimRenk.anaMavi,
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
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            bottom: BorderSide(
                color:
                    context.bildirimRenk.ayiriciCizgi.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri',
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 22, color: context.bildirimRenk.yaziAna),
          ),
          Expanded(
            child: Text(
              'Bildirimler',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.bildirimRenk.yaziAna,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  size: 22, color: context.bildirimRenk.yaziAna),
              tooltip: 'Bildirim işlemleri',
              onSelected: (secim) {
                if (secim == 'okundu') {
                  _markAllRead();
                } else if (secim == 'sil') {
                  _deleteAll();
                }
              },
              itemBuilder: (_) => [
                if (_unreadCount > 0)
                  PopupMenuItem(
                    value: 'okundu',
                    child: Row(
                      children: [
                        Icon(Icons.done_all_rounded,
                            size: 20, color: context.bildirimRenk.anaMavi),
                        SizedBox(width: 12),
                        Text('Tümünü okundu yap'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'sil',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 20, color: Color(0xFFEF4444)),
                      SizedBox(width: 12),
                      Text('Tümünü sil',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
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
        // Diğer liste ekranlarıyla aynı grup başlığı kalıbı.
        ListeGrupBasligi(baslik: title, sayi: items.length),
        ...items.map(
          (n) => Dismissible(
            key: ValueKey('bildirim_${n.id}'),
            direction: DismissDirection.endToStart,
            background: _silmeZemini(),
            onDismissed: (_) => _bildirimSil(n),
            child: _BildirimSatiri(
              notification: n,
              onTap: () => _onNotificationTap(n),
            ),
          ),
        ),
      ],
    );
  }

  /// Kaydırınca beliren kırmızı zemin.
  Widget _silmeZemini() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(Icons.delete_outline_rounded, color: cs.onError),
    );
  }

  /// Tek bildirimi siler; sunucuya gitmeden önce geri alma penceresi bırakır.
  ///
  /// "Tümünü sil" menüsü geri alınamaz bir işlemdi ve tek bir bildirimden
  /// kurtulmanın başka yolu yoktu.
  Future<void> _bildirimSil(NotificationModel notif) async {
    final eskiListe = _notifications;
    setState(() {
      _notifications = [
        for (final n in _notifications)
          if (n.id != notif.id) n
      ];
    });

    final sonuc = await ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text('Bildirim silindi'),
            action: SnackBarAction(label: 'Geri al', onPressed: () {}),
            duration: const Duration(seconds: 4),
          ),
        )
        .closed;

    if (!mounted) return;

    if (sonuc == SnackBarClosedReason.action) {
      setState(() => _notifications = eskiListe);
      return;
    }

    try {
      await NotificationService.deleteNotifications([notif.id]);
      await NotificationService.refreshUnreadCount();
    } catch (e) {
      if (!mounted) return;
      setState(() => _notifications = eskiListe);
      ShowMessage.error(context, 'Bildirim silinemedi');
    }
  }

  Future<void> _onNotificationTap(NotificationModel notif) async {
    await _markNotificationRead(notif);
    if (!mounted) return;
    await _router.route(context, notif);
  }

  Widget _buildLoadingState() => const IskeletListe();

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
              border: Border.all(color: context.bildirimRenk.yaziAna, width: 2),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: context.bildirimRenk.yaziAna,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bildirim yok',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: context.bildirimRenk.yaziAna,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ders teyidi, iptal ve duyurular burada görünecek.',
            style: TextStyle(
              fontSize: 14,
              color: context.bildirimRenk.yaziIkincil,
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
      color: isUnread
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.35)
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(context),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: context.bildirimRenk.yaziAna,
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
                                  ? context.bildirimRenk.yaziAna
                                  : context.bildirimRenk.yaziIkincil,
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
                            ? context.bildirimRenk.anaMavi
                            : context.bildirimRenk.yaziIkincil,
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
                  decoration: BoxDecoration(
                    color: context.bildirimRenk.anaMavi,
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

  Widget _buildAvatar(BuildContext context) {
    final iconData =
        BildirimGorselYardimci.ikonGetir(notification.notificationType);
    final bgColor = BildirimGorselYardimci.arkaplanRengiGetir(
        context, notification.notificationType);
    final iconColor = BildirimGorselYardimci.renkGetir(
        context, notification.notificationType);

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
