import 'package:fitcall/screens/1_common/duyurular/duyuru_yonetim_page.dart';
import 'package:fitcall/screens/1_common/yardim_page.dart';
import 'package:fitcall/screens/1_common/yonetim_yardim_page.dart';
import 'package:fitcall/screens/2_uye/uye_kabuk.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_kabuk.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_yardim_page.dart';
import 'package:fitcall/screens/2_uye/takvim/uye_takvim_page.dart';
import 'package:fitcall/screens/3_antrenor/takvim/antrenor_takvim_page.dart';
import 'package:fitcall/screens/4_auth/forgot_password_page.dart';
import 'package:fitcall/screens/5_etkinlik/ders_teyit_page.dart';
import 'package:fitcall/screens/5_etkinlik/teyit_bekleyenler_page.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uye_detay_page.dart';
import 'package:fitcall/screens/7_yonetici/yonetici_main_page.dart';
import 'package:fitcall/screens/3_antrenor/hakedis/antrenor_hakedis_page.dart';
import 'package:fitcall/screens/7_yonetici/hakedis/hakedis_antrenor_secim_page.dart';
import 'package:fitcall/screens/8_ofis/program/ofis_program_page.dart';
import 'package:fitcall/screens/8_ofis/ofis_main_page.dart';
import 'package:fitcall/screens/8_ofis/uyeler/ofis_uye_detay_page.dart';
import 'package:fitcall/screens/8_ofis/uyeler/ofis_uyeler_page.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/screens/1_common/widgets/erisim_kisitli.dart';
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
import 'package:fitcall/screens/6_muhasebe/havale/dekont_yukle_page.dart';
import 'package:fitcall/screens/6_muhasebe/havale/havale_eft_page.dart';
import 'package:fitcall/screens/6_muhasebe/muhasebe_page.dart';

import 'package:fitcall/screens/3_antrenor/antrenor_profil_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_ogrenciler_page.dart';
import 'package:fitcall/screens/3_antrenor/eksik_yoklama/antrenor_eksik_yoklama_page.dart';

import 'package:fitcall/screens/1_common/1_notification/notification_page.dart';
import 'package:fitcall/screens/1_common/ayarlar/ayarlar_page.dart';
import 'package:fitcall/screens/3_antrenor/program/antrenor_program_page.dart';
import 'package:fitcall/screens/8_ofis/ders_kayit_talepleri/ofis_ders_kayit_talepleri_page.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';

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
  havaleEft,
  dekontYukle,
  dersler,
  uyeGecmisDersler,
  antrenorAnasayfa,
  antrenorProfil,
  antrenorDersler,
  antrenorEksikYoklama,
  antrenorHakedis,
  antrenorTumProgram,
  antrenorOgrenciler,
  antrenorYardim,
  yoneticiYardim,
  ofisYardim,
  bildirimler,
  yoneticiAnasayfa,
  yoneticiHakedis,
  ofisAnasayfa,
  ofisProgram,
  ofisDersKayitTalepleri,
  ofisUyeler,
  yoneticiDuyurular,
  ofisDuyurular,
  dersTeyit,
  teyitBekleyen,
  yardim,
  ayarlar,
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
  SayfaAdi.havaleEft: '/havaleEft',
  SayfaAdi.dekontYukle: '/dekontYukle',
  SayfaAdi.dersler: '/dersler',
  SayfaAdi.uyeGecmisDersler: '/uyeGecmisDersler',
  SayfaAdi.antrenorAnasayfa: '/antrenorAnasayfa',
  SayfaAdi.antrenorProfil: '/antrenor_profil',
  SayfaAdi.antrenorDersler: '/antrenor_dersler',
  SayfaAdi.antrenorEksikYoklama: '/antrenor_eksik_yoklama',
  SayfaAdi.antrenorHakedis: '/antrenorHakedis',
  SayfaAdi.antrenorTumProgram: '/antrenorTumProgram',
  SayfaAdi.antrenorOgrenciler: '/antrenor_ogrenciler',
  SayfaAdi.antrenorYardim: '/antrenor_yardim',
  SayfaAdi.yoneticiYardim: '/yonetici_yardim',
  SayfaAdi.ofisYardim: '/ofis_yardim',
  SayfaAdi.bildirimler: '/bildirimler',
  SayfaAdi.yoneticiAnasayfa: '/yoneticiAnasayfa',
  SayfaAdi.yoneticiHakedis: '/yoneticiHakedis',
  SayfaAdi.ofisAnasayfa: '/ofisAnasayfa',
  SayfaAdi.ofisProgram: '/ofisProgram',
  SayfaAdi.ofisDersKayitTalepleri: '/ofisDersKayitTalepleri',
  SayfaAdi.ofisUyeler: '/ofisUyeler',
  SayfaAdi.yoneticiDuyurular: '/yoneticiDuyurular',
  SayfaAdi.ofisDuyurular: '/ofisDuyurular',
  SayfaAdi.dersTeyit: '/dersTeyit',
  SayfaAdi.teyitBekleyen: '/teyitBekleyen',
  SayfaAdi.yardim: '/yardim',
  SayfaAdi.ayarlar: '/ayarlar',
};

/* ------------------ 2) String -> Widget ------------------ */
final Map<String, WidgetBuilder> routes = {
  routeEnums[SayfaAdi.login]!: (c) => const LoginPage(),
  routeEnums[SayfaAdi.profilSec]!: (c) => const ProfilSecPage([]),
  routeEnums[SayfaAdi.kayitol]!: (c) => const RegisterPage(),
  routeEnums[SayfaAdi.sifremiUnuttum]!: (c) => const ForgotPasswordPage(),
  routeEnums[SayfaAdi.qrKodKayit]!: (c) => const QRKodKayitPage(),
  routeEnums[SayfaAdi.qrKodDogrula]!: (c) => const QRKodDogrulaPage(),
  routeEnums[SayfaAdi.uyeAnasayfa]!: (c) => const UyeKabuk(),
  routeEnums[SayfaAdi.profil]!: (c) => const ProfilePage(),
  routeEnums[SayfaAdi.uyelikPaket]!: (c) => const UyeUrunListPage(),
  routeEnums[SayfaAdi.telafiHaklari]!: (c) => const TelafiHaklariPage(),
  routeEnums[SayfaAdi.muhasebe]!: (c) => const MuhasebePage(),
  routeEnums[SayfaAdi.havaleEft]!: (c) => const HavaleEftPage(),
  routeEnums[SayfaAdi.dekontYukle]!: (c) => const DekontYuklePage(),
  routeEnums[SayfaAdi.dersler]!: (c) => const DersListesiPage(),
  routeEnums[SayfaAdi.uyeGecmisDersler]!: (c) => const GecmisDerslerPage(),
  routeEnums[SayfaAdi.antrenorAnasayfa]!: (c) => const AntrenorKabuk(),
  routeEnums[SayfaAdi.antrenorProfil]!: (c) => const AntrenorProfilPage(),
  routeEnums[SayfaAdi.antrenorDersler]!: (c) => const AntrenorTakvimPage(),
  routeEnums[SayfaAdi.antrenorEksikYoklama]!: (c) =>
      const AntrenorEksikYoklamaPage(),
  routeEnums[SayfaAdi.antrenorHakedis]!: (c) => const AntrenorHakedisPage(),
  routeEnums[SayfaAdi.antrenorTumProgram]!: (c) => const AntrenorProgramPage(),
  routeEnums[SayfaAdi.antrenorOgrenciler]!: (c) => AntrenorOgrencilerPage(),
  routeEnums[SayfaAdi.antrenorYardim]!: (c) => const AntrenorYardimPage(),
  routeEnums[SayfaAdi.yoneticiYardim]!: (c) =>
      const YonetimYardimPage(ofis: false),
  routeEnums[SayfaAdi.ofisYardim]!: (c) => const YonetimYardimPage(ofis: true),
  routeEnums[SayfaAdi.bildirimler]!: (c) => NotificationPage(),
  routeEnums[SayfaAdi.yoneticiAnasayfa]!: (c) => YoneticiMainPage(),
  routeEnums[SayfaAdi.yoneticiHakedis]!: (c) =>
      const HakedisAntrenorSecimPage(),
  routeEnums[SayfaAdi.ofisAnasayfa]!: (c) => const OfisMainPage(),
  routeEnums[SayfaAdi.ofisProgram]!: (c) => const OfisProgramPage(),
  routeEnums[SayfaAdi.ofisDersKayitTalepleri]!: (c) =>
      const OfisDersKayitTalepleriPage(),
  routeEnums[SayfaAdi.ofisUyeler]!: (c) => const OfisUyelerPage(),
  // Aynı ekran; kabuklar yalnız üye satırının açtığı detay sayfasında ayrılır.
  routeEnums[SayfaAdi.yoneticiDuyurular]!: (c) => DuyuruYonetimPage(
        uyeDetayAc: (ctx, p) => Navigator.of(ctx).push(MaterialPageRoute(
          builder: (_) => UyeDetayPage(uyeId: p.uyeId!, baslangicAdSoyad: p.ad),
        )),
      ),
  routeEnums[SayfaAdi.ofisDuyurular]!: (c) => DuyuruYonetimPage(
        uyeDetayAc: (ctx, p) => Navigator.of(ctx).push(MaterialPageRoute(
          builder: (_) =>
              OfisUyeDetayPage(uyeId: p.uyeId!, baslangicAdSoyad: p.ad),
        )),
      ),
  routeEnums[SayfaAdi.dersTeyit]!: (c) => const DersTeyitPage(),
  routeEnums[SayfaAdi.teyitBekleyen]!: (c) => const TeyitBekleyenlerPage(),
  routeEnums[SayfaAdi.yardim]!: (c) => const YardimPage(),
  routeEnums[SayfaAdi.ayarlar]!: (c) => const AyarlarPage(),
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
  routeEnums[SayfaAdi.havaleEft]!: AccessRule.anaHesapOnly,
  routeEnums[SayfaAdi.dekontYukle]!: AccessRule.anaHesapOnly,
  routeEnums[SayfaAdi.bildirimler]!: AccessRule.anaHesapOnly,

  // Örnekler (şimdilik serbest):
  routeEnums[SayfaAdi.dersler]!: AccessRule.anyone,
  routeEnums[SayfaAdi.uyeGecmisDersler]!: AccessRule.anyone,
  routeEnums[SayfaAdi.qrKodKayit]!: AccessRule.anyone,
  routeEnums[SayfaAdi.qrKodDogrula]!: AccessRule.anyone,
  routeEnums[SayfaAdi.yardim]!: AccessRule.anyone,
  routeEnums[SayfaAdi.antrenorYardim]!: AccessRule.anyone,
  routeEnums[SayfaAdi.yoneticiYardim]!: AccessRule.anyone,
  routeEnums[SayfaAdi.ofisYardim]!: AccessRule.anyone,
  routeEnums[SayfaAdi.ayarlar]!: AccessRule.anyone,
  routeEnums[SayfaAdi.yoneticiHakedis]!: AccessRule.anyone,
  routeEnums[SayfaAdi.ofisProgram]!: AccessRule.anyone,
  routeEnums[SayfaAdi.ofisUyeler]!: AccessRule.anyone,
  routeEnums[SayfaAdi.antrenorHakedis]!: AccessRule.anyone,
  routeEnums[SayfaAdi.antrenorTumProgram]!: AccessRule.anyone,
  routeEnums[SayfaAdi.ofisDersKayitTalepleri]!: AccessRule.anyone,
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
              // Ana hesap kuralı yalnız üye profilleri için: velinin alt
              // profilleri (çocuklar) bu sayfaları göremez. Ofis, yönetici ve
              // antrenör profillerinde ana_hesap_mi sunucuda hep false;
              // kural onlara uygulanınca ofis Bildirimler'e giremiyordu.
              final profil = profSnap.data;
              final isAna = profil?.anaHesap ?? false;
              final uyeDegil = profil != null && profil.rol != 'uye';
              if (isAna || uyeDegil) {
                return builder(context);
              }

              return const ErisimKisitli();
            },
          );
        },
      );
    },
    settings: settings,
  );
}
