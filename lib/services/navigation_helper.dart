import 'package:flutter/material.dart';
import 'package:fitcall/common/constants.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action_store.dart';

class NavigationHelper {
  /// Stack’i temizleyerek güvenli yönlendirme
  static void _pushClear(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    final nav = Navigator.of(context, rootNavigator: true);

    // 1) Açık dialog/overlay varsa kapat
    if (nav.canPop()) {
      nav.popUntil((route) => route is PageRoute);
    }

    // 2) Navigasyonu build sonrası yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        routeName,
        (route) => false,
        arguments: arguments,
      );
    });
  }

  static Future<void> redirectAfterLogin(
      BuildContext context, Roller role) async {
    final pending = await PendingActionStore.instance.take();

    if (pending != null) {
      switch (pending.type) {
        case PendingActionType.dersTeyit:
          if (!context.mounted) return;
          _pushClear(
            context,
            routeEnums[SayfaAdi.dersTeyit]!,
            arguments: pending.data,
          );
          return;
        case PendingActionType.bildirimListe:
          if (!context.mounted) return;
          _pushClear(context, routeEnums[SayfaAdi.bildirimler]!);
          return;
      }
    }

    if (!context.mounted) return;
    switch (role) {
      case Roller.antrenor:
        _pushClear(context, routeEnums[SayfaAdi.antrenorAnasayfa]!);
        break;
      case Roller.yonetici:
        _pushClear(context, routeEnums[SayfaAdi.yoneticiAnasayfa]!);
        break;
      default:
        _pushClear(context, routeEnums[SayfaAdi.uyeAnasayfa]!);
    }
  }
}
