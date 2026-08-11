// Profil seçim ekranı: aynı kullanıcının farklı işletmelerdeki profilleri
// işletme adıyla ayırt edilebilmeli.

import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

KullaniciProfilModel _yoneticiProfil({
  required int id,
  String? isletmeAdi,
  int? isletmeId,
}) {
  return KullaniciProfilModel.fromJson({
    'id': id,
    'user': {
      'id': 1,
      'password': '',
      'is_superuser': false,
      'username': 'admin',
      'first_name': 'Ahmet',
      'last_name': 'Yönetici',
      'email': 'a@b.c',
      'is_staff': false,
      'is_active': true,
      'date_joined': '2026-01-01T00:00:00+03:00',
      'groups': <int>[],
      'user_permissions': <dynamic>[],
    },
    'rol': 'yonetici',
    'uye': null,
    'antrenor': null,
    'ana_hesap_mi': true,
    'isletme_id': isletmeId,
    'isletme_adi': isletmeAdi,
  });
}

void main() {
  group('KullaniciProfilModel', () {
    test('isletme alanlarını parse eder', () {
      final p =
          _yoneticiProfil(id: 1, isletmeAdi: 'Binay Akademi', isletmeId: 1);
      expect(p.isletmeAdi, 'Binay Akademi');
      expect(p.isletmeId, 1);
    });

    test('isletme adı boşlukları temizlenir', () {
      final p =
          _yoneticiProfil(id: 1, isletmeAdi: '  Datça Akademi  ', isletmeId: 2);
      expect(p.isletmeAdi, 'Datça Akademi');
    });

    test('isletme yoksa null', () {
      final p = _yoneticiProfil(id: 1);
      expect(p.isletmeAdi, isNull);
      expect(p.isletmeId, isNull);
    });

    test('toJson isletme alanlarını içerir', () {
      final p =
          _yoneticiProfil(id: 1, isletmeAdi: 'Binay Akademi', isletmeId: 1);
      final j = p.toJson();
      expect(j['isletme_id'], 1);
      expect(j['isletme_adi'], 'Binay Akademi');
    });
  });

  group('ProfilSecPage', () {
    testWidgets('aynı isim farklı işletmeler işletme adıyla ayrışır',
        (tester) async {
      final profiller = [
        _yoneticiProfil(id: 1, isletmeAdi: 'Binay Akademi', isletmeId: 1),
        _yoneticiProfil(id: 2, isletmeAdi: 'Datça Akademi', isletmeId: 2),
      ];

      await tester.pumpWidget(MaterialApp(home: ProfilSecPage(profiller)));
      await tester.pump();

      // Her iki işletme adı da görünür; kullanıcı hangi işletme olduğunu görür
      expect(find.text('Binay Akademi'), findsOneWidget);
      expect(find.text('Datça Akademi'), findsOneWidget);
      // İki profil kartı da "Ahmet Yönetici" ismini taşır
      expect(find.text('Ahmet Yönetici'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('işletme adı yoksa rol etiketine düşer', (tester) async {
      // Tek profilde otomatik login akışı tetiklenmesin diye iki profil ver
      final profiller = [
        _yoneticiProfil(id: 1),
        _yoneticiProfil(id: 2),
      ];

      await tester.pumpWidget(MaterialApp(home: ProfilSecPage(profiller)));
      await tester.pump();

      // İşletme adı olmayınca alt satırda rol etiketi görünür (bölüm başlığı + kartlar)
      expect(find.text('Yönetici'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
