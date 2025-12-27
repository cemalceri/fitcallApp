import 'package:flutter/material.dart';
import 'package:fitcall/common/constants.dart';
import 'package:fitcall/common/routes.dart';

class NavigationHelper {
  static void _pushClear(BuildContext context, String routeName,
      {Object? arguments}) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.popUntil((route) => route is PageRoute);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          routeName, (route) => false,
          arguments: arguments);
    });
  }

  static Future<void> redirectAfterLogin(
      BuildContext context, Roller role) async {
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
