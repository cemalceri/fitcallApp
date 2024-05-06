import 'package:fitcall/screens/dersler/dersler_screen.dart';
import 'package:fitcall/screens/home_page.dart';
import 'package:fitcall/screens/login/login_screen.dart';
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
}

final Map<String, WidgetBuilder> routes = {
  '/': (context) => LoginPage(),
  '/anasayfa': (context) => HomePage(),
  '/profil': (context) => const ProfilePage(),
  '/borcalacak': (context) => const BorcAlacakPage(),
  '/dersler': (context) => const DersListesiPage(),
  '/uyelikPaket': (context) => const UyelikPaketPage(),
};

final Map<SayfaAdi, String> routeEnums = {
  SayfaAdi.login: '/',
  SayfaAdi.anasayfa: '/anasayfa',
  SayfaAdi.profil: '/profil',
  SayfaAdi.borcAlacak: '/borcalacak',
  SayfaAdi.dersler: '/dersler',
  SayfaAdi.uyelikPaket: '/uyelikPaket',
};
