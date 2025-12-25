// lib/screens/1_common/1_notification/notifications_bell.dart

import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/services/core/notification_service.dart';

class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});

  Future<void> _openPage(BuildContext ctx) async {
    await Navigator.pushNamed(
      ctx,
      routeEnums[SayfaAdi.bildirimler]!,
    );
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
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                      : Colors.grey.shade100,
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
                          ? const Color(0xFF3B82F6)
                          : Colors.grey.shade600,
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: _Badge(count: count),
                      ),
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
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 4 : 0,
        vertical: 0,
      ),
      constraints: BoxConstraints(
        minWidth: isWide ? 18 : 16,
        minHeight: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
