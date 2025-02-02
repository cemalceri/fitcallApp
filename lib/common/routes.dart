import 'package:fitcall/screens/antrenor/antrenor_dersler_page.dart';
import 'package:fitcall/screens/antrenor/antrenor_ogrenciler_page.dart';
import 'package:fitcall/screens/antrenor/antrenor_profil_page.dart';
import 'package:fitcall/screens/antrenor_home_page.dart';
import 'package:fitcall/screens/auth/qr_kod_page.dart';
import 'package:fitcall/screens/auth/register_screen.dart';
import 'package:fitcall/screens/dersler/dersler_screen.dart';
import 'package:fitcall/screens/home_page.dart';
import 'package:fitcall/screens/auth/login_screen.dart';
import 'package:fitcall/screens/muhasebe/borc_alacak_screen.dart';
import 'package:fitcall/screens/profil/profil_screen.dart';
import 'package:fitcall/screens/uyelik/uyelik_paket_screen.dart';
import 'package:flutter/material.dart';

enum SayfaAdi {
  anasayfa,
  login,
  profil,
  odemeler,
  borcAlacak,
  dersler,
  uyelikPaket,
  kayitol,
  qrKod,
  antrenorAnasayfa,
  antrenorProfil,
  antrenorDersler,
  antrenorOgrenciler,
}

final Map<String, WidgetBuilder> routes = {
  '/': (context) => const LoginPage(),
  '/anasayfa': (context) => HomePage(),
  '/profil': (context) => const ProfilePage(),
  '/borcalacak': (context) => const BorcAlacakPage(),
  '/dersler': (context) => const DersListesiPage(),
  '/uyelikPaket': (context) => const UyelikPaketPage(),
  '/kayitol': (context) => const RegisterPage(),
  '/qrKod': (context) => const QRKodPage(),
  '/antrenorAnasayfa': (context) => AntrenorHomePage(),
  '/antrenor_profil': (context) => AntrenorProfilPage(),
  '/antrenor_dersler': (context) => AntrenorDerslerPage(),
  '/antrenor_ogrenciler': (context) => AntrenorOgrencilerPage(),
};

final Map<SayfaAdi, String> routeEnums = {
  SayfaAdi.login: '/',
  SayfaAdi.anasayfa: '/anasayfa',
  SayfaAdi.profil: '/profil',
  SayfaAdi.borcAlacak: '/borcalacak',
  SayfaAdi.dersler: '/dersler',
  SayfaAdi.uyelikPaket: '/uyelikPaket',
  SayfaAdi.kayitol: '/kayitol',
  SayfaAdi.qrKod: '/qrKod',
  SayfaAdi.antrenorAnasayfa: '/antrenorAnasayfa',
  SayfaAdi.antrenorProfil: '/antrenor_profil',
  SayfaAdi.antrenorDersler: '/antrenor_dersler',
  SayfaAdi.antrenorOgrenciler: '/antrenor_ogrenciler',
};
