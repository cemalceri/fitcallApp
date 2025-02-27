import 'package:flutter/material.dart';
import 'package:fitcall/screens/1_common/1_notification/notification_icon.dart';
import 'package:fitcall/screens/2_uye/ders_talep_page.dart';
import 'package:fitcall/screens/2_uye/uygun_saatler_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_dersler_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_ogrenciler_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_profil_page.dart';
import 'package:fitcall/screens/antrenor_home_page.dart';
import 'package:fitcall/screens/4_auth/qr_kod_page.dart';
import 'package:fitcall/screens/4_auth/register_page.dart';
import 'package:fitcall/screens/2_uye/dersler_page.dart';
import 'package:fitcall/screens/uye_home_page.dart';
import 'package:fitcall/screens/4_auth/login_page.dart';
import 'package:fitcall/screens/2_uye/muhasebe/borc_alacak_page.dart';
import 'package:fitcall/screens/2_uye/profil_page.dart';
import 'package:fitcall/screens/2_uye/uyelik/uyelik_paket_screen.dart';

// AuthService -> Token kontrolünü yapan servis (onGenerateRoute'ta kullanacağız)
import 'package:fitcall/services/auth_service.dart';

/// Uygulama genelinde kullanacağımız sayfaların enum değerleri
enum SayfaAdi {
  login,
  kayitol,
  qrKod,
  uyeAnasayfa,
  profil,
  borcAlacak,
  dersler,
  uyelikPaket,
  antrenorAnasayfa,
  antrenorProfil,
  antrenorDersler,
  antrenorOgrenciler,
  uyeDersTalepleri,
  uygunSaatler,
  bildirimler,
}

/// 1) Enum -> Rota ismi eşleşmesi
final Map<SayfaAdi, String> routeEnums = {
  SayfaAdi.login: '/',
  SayfaAdi.kayitol: '/kayitol',
  SayfaAdi.qrKod: '/qrKod',
  SayfaAdi.uyeAnasayfa: '/uyeAnasayfa',
  SayfaAdi.profil: '/profil',
  SayfaAdi.borcAlacak: '/borcalacak',
  SayfaAdi.dersler: '/dersler',
  SayfaAdi.uyelikPaket: '/uyelikPaket',
  SayfaAdi.antrenorAnasayfa: '/antrenorAnasayfa',
  SayfaAdi.antrenorProfil: '/antrenor_profil',
  SayfaAdi.antrenorDersler: '/antrenor_dersler',
  SayfaAdi.antrenorOgrenciler: '/antrenor_ogrenciler',
  SayfaAdi.uyeDersTalepleri: '/uyeDersTalepleri',
  SayfaAdi.uygunSaatler: '/uygunSaatler',
  SayfaAdi.bildirimler: '/bildirimler',
};

/// 2) Rota -> Widget eşleşmesi (onGenerateRoute içinde kullanacağız)
final Map<String, WidgetBuilder> routes = {
  routeEnums[SayfaAdi.login]!: (context) => const LoginPage(),
  routeEnums[SayfaAdi.kayitol]!: (context) => const RegisterPage(),
  routeEnums[SayfaAdi.qrKod]!: (context) => const QRKodPage(),
  routeEnums[SayfaAdi.uyeAnasayfa]!: (context) => UyeHomePage(),
  routeEnums[SayfaAdi.profil]!: (context) => const ProfilePage(),
  routeEnums[SayfaAdi.borcAlacak]!: (context) => const BorcAlacakPage(),
  routeEnums[SayfaAdi.dersler]!: (context) => const DersListesiPage(),
  routeEnums[SayfaAdi.uyelikPaket]!: (context) => const UyelikPaketPage(),
  routeEnums[SayfaAdi.antrenorAnasayfa]!: (context) => AntrenorHomePage(),
  routeEnums[SayfaAdi.antrenorProfil]!: (context) => AntrenorProfilPage(),
  routeEnums[SayfaAdi.antrenorDersler]!: (context) => AntrenorDerslerPage(),
  routeEnums[SayfaAdi.antrenorOgrenciler]!: (context) =>
      AntrenorOgrencilerPage(),
  routeEnums[SayfaAdi.uyeDersTalepleri]!: (context) => const DersTalepPage(),
  routeEnums[SayfaAdi.uygunSaatler]!: (context) => const UygunSaatlerPage(),
  routeEnums[SayfaAdi.bildirimler]!: (context) =>
      NotificationPage(notifications: []),
};

/// 3) Public rotalar (token kontrolü olmadan açılabilen ekranlar)
///   Burada da enum -> string dönüşümü yapıyoruz
final Set<String> publicRoutes = {
  routeEnums[SayfaAdi.login]!, // login -> '/'
  routeEnums[SayfaAdi.kayitol]!, // '/kayitol'
  routeEnums[SayfaAdi.qrKod]!, // '/qrKod'
};

/// 4) onGenerateRoute: Rota oluşturma + Token kontrolü
Route<dynamic>? myRouteGenerator(RouteSettings settings) {
  final builder = routes[settings.name]; // Map'ten builder'ı çek

  // a) Map'te yoksa 404
  if (builder == null) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text("404 - Sayfa bulunamadı")),
      ),
    );
  }

  // b) Public rota mı? -> Direkt aç
  if (publicRoutes.contains(settings.name)) {
    return MaterialPageRoute(builder: builder, settings: settings);
  }

  // c) Private rota -> Token kontrol
  return MaterialPageRoute(
    builder: (context) {
      return FutureBuilder<bool>(
        future: AuthService.tokenGecerliMi(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Yükleniyor
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Hata veya token geçersiz -> Login'e yönlendir
          if (snapshot.hasError || (snapshot.data == false)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(
                  context, routeEnums[SayfaAdi.login]!);
            });
            return const Scaffold();
          }

          // Token geçerli -> Asıl sayfa
          return builder(context);
        },
      );
    },
    settings: settings,
  );
}
