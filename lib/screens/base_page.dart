import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BasePage<T extends StatefulWidget> extends State<T> {
  @override
  void initState() {
    super.initState();
    tokenGecerliMi();
  }

  void tokenGecerliMi() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    bool hasAccess = await verifyUserAccess(token);

    if (token == null || !hasAccess) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(routeEnums[SayfaAdi.login]!);
      }
    } else {
      onAuthorized();
    }
  }

  Future<bool> verifyUserAccess(String? token) async {
    // Burada API'ye bir istek gönderilip token kontrolü yapılabilir
    // ve kullanıcının yetkisi kontrol edilebilir.
    // Örnek olarak her zaman true döndürülüyor.
    return true;
  }

  void onAuthorized(); // Yetkili kullanıcı için çağrılacak metod.
}
