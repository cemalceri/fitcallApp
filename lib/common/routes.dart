import 'package:fitcall/screens/1_common/yardim_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_yardim_page.dart';
import 'package:fitcall/screens/2_uye/home/uye_home_page.dart';
import 'package:fitcall/screens/2_uye/takvim/uye_takvim_page.dart';
import 'package:fitcall/screens/3_antrenor/takvim/antrenor_takvim_page.dart';
import 'package:fitcall/screens/4_auth/forgot_password_page.dart';
import 'package:fitcall/screens/5_etkinlik/ders_teyit_page.dart';
import 'package:fitcall/screens/5_etkinlik/teyit_bekleyenler_page.dart';
import 'package:fitcall/screens/7_yonetici/yonetici_main_page.dart';
import 'package:fitcall/screens/3_antrenor/hakedis/antrenor_hakedis_page.dart';
import 'package:fitcall/screens/7_yonetici/hakedis/hakedis_antrenor_secim_page.dart';
import 'package:fitcall/screens/7_yonetici/program/yonetici_program_page.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';

/* ------------------ Ekranlar ------------------ */
import 'package:fitcall/screens/4_auth/login_page.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';
import 'package:fitcall/screens/4_auth/register_page.dart';
import 'package:fitcall/screens/4_auth/qr_kod_kayit_page.dart';
import 'package:fitcall/screens/1_common/qr_kod_dogrula_page.dart';

import 'package:fitcall/screens/2_uye/gecmis_dersler/gecmis_dersler_page.dart';
import 'package:fitcall/screens/2_uye/profil/profil_page.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/telafi_haklari_page.dart';
import 'package:fitcall/screens/2_uye/widgets/uye_urun_list_page.dart';
import 'package:fitcall/screens/6_muhasebe/muhasebe_page.dart';
import 'package:fitcall/screens/5_etkinlik/ders_talep_page.dart';

import 'package:fitcall/screens/3_antrenor/home/antrenor_home_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_profil_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_ogrenciler_page.dart';
import 'package:fitcall/screens/3_antrenor/eksik_yoklama/antrenor_eksik_yoklama_page.dart';

import 'package:fitcall/screens/1_common/1_notification/notification_page.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/common/tarih_util.dart';

/// Uygulama genelinde kullanacağımız sayfaların enum değerleri
enum SayfaAdi {
  login,
  profilSec,
  kayitol,
  sifremiUnuttum,
  qrKodKayit,
  qrKodDogrula,
  uyeAnasayfa,
  profil,
  uyelikPaket,
  telafiHaklari,
  muhasebe,
  dersler,
  uyeGecmisDersler,
  antrenorAnasayfa,
  antrenorProfil,
  antrenorDersler,
  antrenorEksikYoklama,
  antrenorHakedis,
  antrenorOgrenciler,
  antrenorYardim,
  uyeDersTalepleri,
  bildirimler,
  yoneticiAnasayfa,
  yoneticiProgram,
  yoneticiHakedis,
  dersTeyit,
  teyitBekleyen,
  yardim,
}

/* ------------------ 1) Enum -> String ------------------ */
final Map<SayfaAdi, String> routeEnums = {
  SayfaAdi.login: '/',
  SayfaAdi.profilSec: '/profilSec',
  SayfaAdi.kayitol: '/kayitol',
  SayfaAdi.sifremiUnuttum: '/sifremiUnuttum',
  SayfaAdi.qrKodKayit: '/qrKodKayit',
  SayfaAdi.qrKodDogrula: '/qrKodDogrula',
  SayfaAdi.uyeAnasayfa: '/uyeAnasayfa',
  SayfaAdi.profil: '/profil',
  SayfaAdi.uyelikPaket: '/uyelikPaket',
  SayfaAdi.telafiHaklari: '/telafiHaklari',
  SayfaAdi.muhasebe: '/muhasebe',
  SayfaAdi.dersler: '/dersler',
  SayfaAdi.uyeGecmisDersler: '/uyeGecmisDersler',
  SayfaAdi.antrenorAnasayfa: '/antrenorAnasayfa',
  SayfaAdi.antrenorProfil: '/antrenor_profil',
  SayfaAdi.antrenorDersler: '/antrenor_dersler',
  SayfaAdi.antrenorEksikYoklama: '/antrenor_eksik_yoklama',
  SayfaAdi.antrenorHakedis: '/antrenorHakedis',
  SayfaAdi.antrenorOgrenciler: '/antrenor_ogrenciler',
  SayfaAdi.antrenorYardim: '/antrenor_yardim',
  SayfaAdi.uyeDersTalepleri: '/uyeDersTalepleri',
  SayfaAdi.bildirimler: '/bildirimler',
  SayfaAdi.yoneticiAnasayfa: '/yoneticiAnasayfa',
  SayfaAdi.yoneticiProgram: '/yoneticiProgram',
  SayfaAdi.yoneticiHakedis: '/yoneticiHakedis',
  SayfaAdi.dersTeyit: '/dersTeyit',
  SayfaAdi.teyitBekleyen: '/teyitBekleyen',
  SayfaAdi.yardim: '/yardim',
};

/* ------------------ 2) String -> Widget ------------------ */
final Map<String, WidgetBuilder> routes = {
  routeEnums[SayfaAdi.login]!: (c) => const LoginPage(),
  routeEnums[SayfaAdi.profilSec]!: (c) => const ProfilSecPage([]),
  routeEnums[SayfaAdi.kayitol]!: (c) => const RegisterPage(),
  routeEnums[SayfaAdi.sifremiUnuttum]!: (c) => const ForgotPasswordPage(),
  routeEnums[SayfaAdi.qrKodKayit]!: (c) => const QRKodKayitPage(),
  routeEnums[SayfaAdi.qrKodDogrula]!: (c) => const QRKodDogrulaPage(),
  routeEnums[SayfaAdi.uyeAnasayfa]!: (c) => UyeHomePage(),
  routeEnums[SayfaAdi.profil]!: (c) => const ProfilePage(),
  routeEnums[SayfaAdi.uyelikPaket]!: (c) => const UyeUrunListPage(),
  routeEnums[SayfaAdi.telafiHaklari]!: (c) => const TelafiHaklariPage(),
  routeEnums[SayfaAdi.muhasebe]!: (c) => const MuhasebePage(),
  routeEnums[SayfaAdi.dersler]!: (c) => const DersListesiPage(),
  routeEnums[SayfaAdi.uyeGecmisDersler]!: (c) => const GecmisDerslerPage(),
  routeEnums[SayfaAdi.antrenorAnasayfa]!: (c) => AntrenorHomePage(),
  routeEnums[SayfaAdi.antrenorProfil]!: (c) => AntrenorProfilPage(),
  routeEnums[SayfaAdi.antrenorDersler]!: (c) => AntrenorTakvimPage(),
  routeEnums[SayfaAdi.antrenorEksikYoklama]!: (c) =>
      const AntrenorEksikYoklamaPage(),
  routeEnums[SayfaAdi.antrenorHakedis]!: (c) => const AntrenorHakedisPage(),
  routeEnums[SayfaAdi.antrenorOgrenciler]!: (c) => AntrenorOgrencilerPage(),
  routeEnums[SayfaAdi.antrenorYardim]!: (c) => const AntrenorYardimPage(),
  routeEnums[SayfaAdi.uyeDersTalepleri]!: (context) => DersTalepPage(
        secimJson: const {
          "kort_id": 0,
          "antrenor_id": 0,
          "kort_adi": "",
          "antrenor_adi": ""
        },
        baslangic: simdiKulup(),
      ),
  routeEnums[SayfaAdi.bildirimler]!: (c) => NotificationPage(),
  routeEnums[SayfaAdi.yoneticiAnasayfa]!: (c) => YoneticiMainPage(),
  routeEnums[SayfaAdi.yoneticiProgram]!: (c) => const YoneticiProgramPage(),
  routeEnums[SayfaAdi.yoneticiHakedis]!: (c) =>
      const HakedisAntrenorSecimPage(),
  routeEnums[SayfaAdi.dersTeyit]!: (c) => const DersTeyitPage(),
  routeEnums[SayfaAdi.teyitBekleyen]!: (c) => const TeyitBekleyenlerPage(),
  routeEnums[SayfaAdi.yardim]!: (c) => const YardimPage(),
};

/* ------------------ 3) Public rotalar ------------------ */
final Set<String> publicRoutes = {
  routeEnums[SayfaAdi.login]!,
  routeEnums[SayfaAdi.kayitol]!,
  routeEnums[SayfaAdi.sifremiUnuttum]!,
  routeEnums[SayfaAdi.profilSec]!,
};

/* ------------------ 3.1 Ana hesap erişim kuralları ------------------ */
enum AccessRule { anyone, anaHesapOnly }

/// Hangi rotanın ana hesap zorunlu olacağını buradan yönet.
final Map<String, AccessRule> accessPolicies = {
  routeEnums[SayfaAdi.profil]!: AccessRule.anaHesapOnly,
  routeEnums[SayfaAdi.uyelikPaket]!: AccessRule.anaHesapOnly,
  routeEnums[SayfaAdi.telafiHaklari]!: AccessRule.anaHesapOnly,
  routeEnums[SayfaAdi.muhasebe]!: AccessRule.anaHesapOnly,
  routeEnums[SayfaAdi.uyeDersTalepleri]!: AccessRule.anaHesapOnly,
  routeEnums[SayfaAdi.bildirimler]!: AccessRule.anaHesapOnly,

  // Örnekler (şimdilik serbest):
  routeEnums[SayfaAdi.dersler]!: AccessRule.anyone,
  routeEnums[SayfaAdi.uyeGecmisDersler]!: AccessRule.anyone,
  routeEnums[SayfaAdi.qrKodKayit]!: AccessRule.anyone,
  routeEnums[SayfaAdi.qrKodDogrula]!: AccessRule.anyone,
  routeEnums[SayfaAdi.yardim]!: AccessRule.anyone,
  routeEnums[SayfaAdi.antrenorYardim]!: AccessRule.anyone,
  routeEnums[SayfaAdi.yoneticiProgram]!: AccessRule.anyone,
  routeEnums[SayfaAdi.yoneticiHakedis]!: AccessRule.anyone,
  routeEnums[SayfaAdi.antrenorHakedis]!: AccessRule.anyone,
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

  // Public sayfalar: doğrudan aç
  if (publicRoutes.contains(settings.name)) {
    return MaterialPageRoute(builder: builder, settings: settings);
  }

  // Private sayfalar: önce token, sonra ana hesap guard
  return MaterialPageRoute(
    builder: (context) {
      return FutureBuilder<bool>(
        future: StorageService.tokenGecerliMi(),
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

          // 🔽 Ana hesap kontrolü (sade guard)
          final rule = accessPolicies[settings.name] ?? AccessRule.anyone;
          if (rule == AccessRule.anyone) {
            return builder(context);
          }

          // anaHesapOnly ise aktif profili oku
          return FutureBuilder<KullaniciProfilModel?>(
            future: StorageService.uyeProfilBilgileriniGetir(),
            builder: (context, profSnap) {
              if (profSnap.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final isAna = (profSnap.data?.anaHesap ?? false);
              if (isAna) {
                return builder(context);
              }

              // Yetkisiz görünüm (yalın mesaj)
              return Scaffold(
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Geri',
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6)
                      ], // indigo → mor
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6)
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.verified_user,
                                        size: 40, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Erişim Kısıtlı',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Bu sayfayı ana hesap kullanıcısı görmeye yetkilidir.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Geri'),
                                    onPressed: () =>
                                        Navigator.maybePop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
    settings: settings,
  );
}
