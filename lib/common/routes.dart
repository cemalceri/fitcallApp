import 'package:fitcall/screens/home_page.dart';
import 'package:fitcall/screens/login/login_screen.dart';
import 'package:fitcall/screens/muhasebe/borc_alacak_screen.dart';
import 'package:fitcall/screens/profil/profil_screen.dart';
import 'package:flutter/material.dart';

enum SayfaAdi {
  anasayfa,
  login,
  profil,
  odemeler,
  borcAlacak,
}

final Map<String, WidgetBuilder> routes = {
  '/': (context) => LoginPage(),
  '/anasayfa': (context) => HomePage(),
  '/profil': (context) => ProfilePage(),
  '/borcalacak': (context) => BorcAlacakPage(),
};

final Map<SayfaAdi, String> routeEnums = {
  SayfaAdi.login: '/',
  SayfaAdi.anasayfa: '/anasayfa',
  SayfaAdi.profil: '/profil',
  SayfaAdi.borcAlacak: '/borcalacak',
};
