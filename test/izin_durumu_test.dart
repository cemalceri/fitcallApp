// İzin durumu eşlemesi: cihaz kaydına giden metinler.
//
// Kritik nokta `denied`: permission_handler iOS'ta "hiç sorulmadı" ile
// "reddedildi"ye aynı değeri veriyor, Android'de de ilk sorudan önce durum
// `denied`. Damga olmadan ikisi ayrılamıyor ve panelde hiç sorulmamış izinler
// "Reddedildi" görünüyordu.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:fitcall/services/core/izin_durumu.dart';

void main() {
  group('izinMetni', () {
    test('denied, izin daha önce sorulmamışsa "sorulmadi" olur', () {
      expect(
        izinMetni(PermissionStatus.denied, soruldu: false),
        IzinDurumu.sorulmadi,
      );
    });

    test('denied, izin sorulmuşsa "reddedildi" olur', () {
      expect(
        izinMetni(PermissionStatus.denied, soruldu: true),
        IzinDurumu.reddedildi,
      );
    });

    test('granted damgadan bağımsız "izinli" olur', () {
      for (final soruldu in [true, false]) {
        expect(
          izinMetni(PermissionStatus.granted, soruldu: soruldu),
          IzinDurumu.izinli,
        );
      }
    });

    test('permanentlyDenied "kalici_red" olur', () {
      expect(
        izinMetni(PermissionStatus.permanentlyDenied, soruldu: true),
        IzinDurumu.kaliciRed,
      );
    });

    test('restricted ve limited "kisitli" olur', () {
      expect(
        izinMetni(PermissionStatus.restricted, soruldu: true),
        IzinDurumu.kisitli,
      );
      expect(
        izinMetni(PermissionStatus.limited, soruldu: true),
        IzinDurumu.kisitli,
      );
    });

    test('provisional "gecici" olur', () {
      expect(
        izinMetni(PermissionStatus.provisional, soruldu: true),
        IzinDurumu.gecici,
      );
    });
  });

  group('bildirimIzniMetni', () {
    test('iOS notDetermined "sorulmadi" olur (denied ile karışmaz)', () {
      expect(
        bildirimIzniMetni(AuthorizationStatus.notDetermined),
        IzinDurumu.sorulmadi,
      );
      expect(
        bildirimIzniMetni(AuthorizationStatus.denied),
        IzinDurumu.reddedildi,
      );
    });

    test('authorized ve provisional ayrı değerler', () {
      expect(
        bildirimIzniMetni(AuthorizationStatus.authorized),
        IzinDurumu.izinli,
      );
      expect(
        bildirimIzniMetni(AuthorizationStatus.provisional),
        IzinDurumu.gecici,
      );
    });
  });

  test('damga anahtarları oturum temizliğinde korunanlarla aynı', () {
    expect(IzinAnahtari.tumu, [
      IzinAnahtari.bildirim,
      IzinAnahtari.kamera,
      IzinAnahtari.takvim,
    ]);
  });
}
