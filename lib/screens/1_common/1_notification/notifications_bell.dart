import 'package:fitcall/screens/1_common/1_notification/notification_page.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/services/notification_service.dart';

class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});

  Future<void> _openPage(BuildContext ctx) async {
    await Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
    // ➜ Sayfa kapandıktan sonra gerçek unread sayısını tekrar çek
    NotificationService.refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unreadCount,
      builder: (_, count, __) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => _openPage(context),
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: _Badge(count: count),
              ),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration:
          const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Center(
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
