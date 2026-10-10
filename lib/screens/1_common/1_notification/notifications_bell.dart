import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/services/notification/notification_service.dart';

class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});

  Future<void> _openPage(BuildContext ctx) async {
    await Navigator.pushNamed(ctx, routeEnums[SayfaAdi.bildirimler]!);
    NotificationService.refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unreadCount,
      builder: (_, count, __) {
        return Container(
          margin: const EdgeInsets.only(right: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openPage(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: count > 0
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                        count > 0
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_outlined,
                        size: 22,
                        color: count > 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    if (count > 0)
                      Positioned(right: 8, top: 8, child: _Badge(count: count)),
                  ],
                ),
              ),
            ),
          ),
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
    final displayText = count > 9 ? '9+' : '$count';
    final isWide = count > 9;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 4 : 0, vertical: 0),
      constraints: BoxConstraints(minWidth: isWide ? 18 : 16, minHeight: 16),
      decoration: BoxDecoration(
          // Rozet hata renginde (her temada aynı), çerçevesi zemin renginde.
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Theme.of(context).colorScheme.surface, width: 1.5)),
      child: Center(
          child: Text(displayText,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.2))),
    );
  }
}
