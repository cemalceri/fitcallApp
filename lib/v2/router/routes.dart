import 'package:fitcall/v2/modules/auth/screens/login_screen.dart';
import 'package:fitcall/v2/modules/auth/screens/profil_secim_screen.dart';
import 'package:fitcall/v2/modules/uye/screens/anasayfa_screen.dart';
import 'package:flutter/material.dart';

/// Uygulama genelinde kullanacağımız sayfaların enum değerleri
enum SayfaAdi {
  loginV2,
  profilSecimV2,
  uyeAnasayfaV2,
  antrenorAnasayfaV2,
}

/// 1) Enum -> Rota ismi eşleşmesi
final Map<SayfaAdi, String> routeEnums = {
  SayfaAdi.loginV2: '/',
  SayfaAdi.profilSecimV2: '/profilSecim',
  SayfaAdi.uyeAnasayfaV2: '/uyeAnasayfa',
  SayfaAdi.antrenorAnasayfaV2: '/antrenorAnasayfa',
};

/// 2) Rota -> Widget eşleşmesi (onGenerateRoute içinde kullanacağız)
final Map<String, WidgetBuilder> routes = {
  routeEnums[SayfaAdi.loginV2]!: (context) => const LoginScreen(),
  routeEnums[SayfaAdi.profilSecimV2]!: (context) => ProfilSecimScreen(),
  routeEnums[SayfaAdi.uyeAnasayfaV2]!: (context) => UyeAnaSayfaScreen(),
  routeEnums[SayfaAdi.antrenorAnasayfaV2]!: (context) => UyeAnaSayfaScreen(),
};

/// 3) Public rotalar (token kontrolü olmadan açılabilen ekranlar)
///   Burada da enum -> string dönüşümü yapıyoruz
final Set<String> publicRoutes = {
  routeEnums[SayfaAdi.loginV2]!, // login -> '/'
};

Route<dynamic>? v2RouteGenerator(RouteSettings settings) {
  final builder = routes[settings.name]; // Map'ten builder'ı çek

  // a) Map'te yoksa 404
  if (builder == null) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text("404 - Sayfa bulunamadı")),
      ),
    );
  }

  // b) ŞİMDİLİK: Token kontrolsüz tüm sayfalar açılacak
  return MaterialPageRoute(
    builder: builder,
    settings: settings,
  );

  /*
  // GELECEKTE: Token kontrolünü yeniden aktif etmek istersen burayı aç
  if (publicRoutes.contains(settings.name)) {
    return MaterialPageRoute(builder: builder, settings: settings);
  }

  return MaterialPageRoute(
    builder: (context) {
      return FutureBuilder<bool>(
        future: AuthService.tokenGecerliMi(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError || (snapshot.data == false)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(
                  context, routeEnums[SayfaAdi.loginV2]!);
            });
            return const Scaffold();
          }

          return builder(context);
        },
      );
    },
    settings: settings,
  );
  */
}
