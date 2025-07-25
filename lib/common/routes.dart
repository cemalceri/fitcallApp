import 'package:fitcall/screens/5_etkinlik/ders_teyit_page.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/services/auth_service.dart';

/* ------------------ Ekranlar ------------------ */
import 'package:fitcall/screens/4_auth/login_page.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';
import 'package:fitcall/screens/4_auth/register_page.dart';
import 'package:fitcall/screens/4_auth/qr_kod_kayit_page.dart';
import 'package:fitcall/screens/4_auth/qr_kod_dogrula_page.dart';

import 'package:fitcall/screens/uye_home_page.dart';
import 'package:fitcall/screens/2_uye/profil_page.dart';
import 'package:fitcall/screens/muhasebe/muhasebe_page.dart';
import 'package:fitcall/screens/2_uye/dersler_page.dart';
import 'package:fitcall/screens/2_uye/uyelik/uyelik_paket_screen.dart';
import 'package:fitcall/screens/2_uye/ders_talep_page.dart';
import 'package:fitcall/screens/2_uye/uygun_saatler_page.dart';

import 'package:fitcall/screens/antrenor_home_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_profil_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_dersler_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_ogrenciler_page.dart';

import 'package:fitcall/screens/1_common/1_notification/notification_icon.dart';
import 'package:fitcall/screens/yonetici_home_page.dart';

/// Uygulama genelinde kullanacağımız sayfaların enum değerleri
enum SayfaAdi {
  login,
  profilSec,
  kayitol,
  qrKodKayit,
  qrKodDogrula,
  uyeAnasayfa,
  profil,
  muhasebe,
  dersler,
  uyelikPaket,
  antrenorAnasayfa,
  antrenorProfil,
  antrenorDersler,
  antrenorOgrenciler,
  uyeDersTalepleri,
  uygunSaatler,
  bildirimler,
  yoneticiAnasayfa,
  dersTeyit, // << yeni
}

/* ------------------ 1) Enum -> String ------------------ */
final Map<SayfaAdi, String> routeEnums = {
  SayfaAdi.login: '/',
  SayfaAdi.profilSec: '/profilSec',
  SayfaAdi.kayitol: '/kayitol',
  SayfaAdi.qrKodKayit: '/qrKodKayit',
  SayfaAdi.qrKodDogrula: '/qrKodDogrula',
  SayfaAdi.uyeAnasayfa: '/uyeAnasayfa',
  SayfaAdi.profil: '/profil',
  SayfaAdi.muhasebe: '/muhasebe',
  SayfaAdi.dersler: '/dersler',
  SayfaAdi.uyelikPaket: '/uyelikPaket',
  SayfaAdi.antrenorAnasayfa: '/antrenorAnasayfa',
  SayfaAdi.antrenorProfil: '/antrenor_profil',
  SayfaAdi.antrenorDersler: '/antrenor_dersler',
  SayfaAdi.antrenorOgrenciler: '/antrenor_ogrenciler',
  SayfaAdi.uyeDersTalepleri: '/uyeDersTalepleri',
  SayfaAdi.uygunSaatler: '/uygunSaatler',
  SayfaAdi.bildirimler: '/bildirimler',
  SayfaAdi.yoneticiAnasayfa: '/yoneticiAnasayfa',
  SayfaAdi.dersTeyit: '/dersTeyit', // << yeni
};

/* ------------------ 2) String -> Widget ------------------ */
final Map<String, WidgetBuilder> routes = {
  routeEnums[SayfaAdi.login]!: (c) => const LoginPage(),
  routeEnums[SayfaAdi.profilSec]!: (c) =>
      const ProfilSecPage([]), // Profil seçimi için boş liste
  routeEnums[SayfaAdi.kayitol]!: (c) => const RegisterPage(),
  routeEnums[SayfaAdi.qrKodKayit]!: (c) => const QRKodKayitPage(),
  routeEnums[SayfaAdi.qrKodDogrula]!: (c) => const QRKodDogrulaPage(),
  routeEnums[SayfaAdi.uyeAnasayfa]!: (c) => UyeHomePage(),
  routeEnums[SayfaAdi.profil]!: (c) => const ProfilePage(),
  routeEnums[SayfaAdi.muhasebe]!: (c) => const MuhasebePage(),
  routeEnums[SayfaAdi.dersler]!: (c) => const DersListesiPage(),
  routeEnums[SayfaAdi.uyelikPaket]!: (c) => const UyelikPaketPage(),
  routeEnums[SayfaAdi.antrenorAnasayfa]!: (c) => AntrenorHomePage(),
  routeEnums[SayfaAdi.antrenorProfil]!: (c) => AntrenorProfilPage(),
  routeEnums[SayfaAdi.antrenorDersler]!: (c) => AntrenorDerslerPage(),
  routeEnums[SayfaAdi.antrenorOgrenciler]!: (c) => AntrenorOgrencilerPage(),
  routeEnums[SayfaAdi.uyeDersTalepleri]!: (c) => const DersTalepPage(),
  routeEnums[SayfaAdi.uygunSaatler]!: (c) => const UygunSaatlerPage(),
  routeEnums[SayfaAdi.bildirimler]!: (c) => NotificationPage(notifications: []),
  routeEnums[SayfaAdi.yoneticiAnasayfa]!: (c) => YoneticiHomePage(),
  routeEnums[SayfaAdi.dersTeyit]!: (c) => const DersTeyitPage(),
};

/* ------------------ 3) Public rotalar ------------------ */
final Set<String> publicRoutes = {
  routeEnums[SayfaAdi.login]!,
  routeEnums[SayfaAdi.kayitol]!,
};

/* ------------------ 4) onGenerateRoute ------------------ */
Route<dynamic>? myRouteGenerator(RouteSettings settings) {
  final builder = routes[settings.name];

  if (builder == null) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text("404 - Sayfa bulunamadı")),
      ),
    );
  }

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
                  context, routeEnums[SayfaAdi.login]!);
            });
            return const Scaffold();
          }
          return builder(context);
        },
      );
    },
    settings: settings,
  );
}
