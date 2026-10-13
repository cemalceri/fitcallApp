// Üyenin kendi profil fotoğrafı: cihazdaki kopyaların güncellenmesi, seçenek
// sayfası, düzenlenebilir avatar ve fotoğraflı liste avatarı.

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/profil_fotografi_secici.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

Widget _uygulama(Widget govde) => MaterialApp(
      theme: FitcallTema.acik,
      home: Scaffold(body: govde),
    );

/// Galeride/kamerada vazgeçen kullanıcı.
class _VazgecenSecici extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async =>
      null;
}

void main() {
  group('profilFotografiIslemi', () {
    Future<void> baslat(
      WidgetTester tester,
      ProfilFotoSecimi secim,
      List<bool> yukleniyor,
      List<ProfilFotoSonucu> sonuclar,
    ) async {
      await tester.pumpWidget(_uygulama(Builder(
        builder: (c) => TextButton(
          onPressed: () async => sonuclar.add(await profilFotografiIslemi(
            c,
            secim,
            yukleniyor: yukleniyor.add,
            secici: _VazgecenSecici(),
          )),
          child: const Text('başla'),
        ),
      )));
      await tester.tap(find.text('başla'));
      await tester.pumpAndSettle();
    }

    testWidgets('seçimden vazgeçilince istek yok, halka yanmaz',
        (tester) async {
      final yukleniyor = <bool>[];
      final sonuclar = <ProfilFotoSonucu>[];
      await baslat(tester, ProfilFotoSecimi.galeri, yukleniyor, sonuclar);
      expect(sonuclar.single.degisti, isFalse);
      expect(yukleniyor, isNot(contains(true)));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('kaldırma onay ister; vazgeçilince dokunulmaz', (tester) async {
      final yukleniyor = <bool>[];
      final sonuclar = <ProfilFotoSonucu>[];
      await baslat(tester, ProfilFotoSecimi.kaldir, yukleniyor, sonuclar);
      expect(find.text('Fotoğraf kaldırılsın mı?'), findsOneWidget);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(sonuclar.single.degisti, isFalse);
      expect(yukleniyor, isNot(contains(true)));
    });
  });

  group('StorageService.profilFotografiniGuncelle', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({
        'uye': jsonEncode({'id': 7, 'adi': 'Deniz', 'profil_fotografi': null}),
        'uye_profil': jsonEncode({
          'id': 70,
          'rol': 'uye',
          'uye': {'id': 7, 'profil_fotografi': null},
        }),
        'kullanici_profiller': jsonEncode([
          {
            'id': 70,
            'rol': 'uye',
            'uye': {'id': 7, 'profil_fotografi': null},
          },
          {
            'id': 71,
            'rol': 'uye',
            'uye': {'id': 8, 'profil_fotografi': 'https://x/profil/8/k.jpg'},
          },
          {'id': 72, 'rol': 'antrenor', 'uye': null},
        ]),
      });
    });

    Future<Map<String, dynamic>> oku(String anahtar) async {
      final s = await SecureStorageService.getValue<String>(anahtar);
      return Map<String, dynamic>.from(jsonDecode(s!) as Map);
    }

    test('profil sayfası, aktif profil ve profil listesi birlikte güncellenir',
        () async {
      await StorageService.profilFotografiniGuncelle(
          'https://x/profil/7/y.jpg');

      expect(
          (await oku('uye'))['profil_fotografi'], 'https://x/profil/7/y.jpg');
      expect((await oku('uye_profil'))['uye']['profil_fotografi'],
          'https://x/profil/7/y.jpg');
      final liste = jsonDecode((await SecureStorageService.getValue<String>(
          'kullanici_profiller'))!) as List;
      expect(liste[0]['uye']['profil_fotografi'], 'https://x/profil/7/y.jpg');
      // Hesaptaki diğer üye profiline (kardeş) dokunulmaz.
      expect(liste[1]['uye']['profil_fotografi'], 'https://x/profil/8/k.jpg');
      expect(liste[2]['uye'], isNull);
    });

    test('kaldırılınca null yazılır', () async {
      await StorageService.profilFotografiniGuncelle('https://x/a.jpg');
      await StorageService.profilFotografiniGuncelle(null);
      expect((await oku('uye'))['profil_fotografi'], isNull);
      expect((await oku('uye_profil'))['uye']['profil_fotografi'], isNull);
    });
  });

  group('ProfilFotoSecenekleri', () {
    testWidgets('fotoğraf yoksa kaldır seçeneği çıkmaz', (tester) async {
      await tester.pumpWidget(
          _uygulama(ProfilFotoSecenekleri(fotoVar: false, onSec: (_) {})));
      expect(find.text('Fotoğraf çek'), findsOneWidget);
      expect(find.text('Galeriden seç'), findsOneWidget);
      expect(find.text('Fotoğrafı kaldır'), findsNothing);
    });

    testWidgets('fotoğraf varsa kaldır seçilebilir', (tester) async {
      ProfilFotoSecimi? secilen;
      await tester.pumpWidget(_uygulama(
          ProfilFotoSecenekleri(fotoVar: true, onSec: (s) => secilen = s)));
      await tester.tap(find.text('Fotoğrafı kaldır'));
      expect(secilen, ProfilFotoSecimi.kaldir);
    });
  });

  group('KimlikBaslik düzenlenebilir avatar', () {
    testWidgets('dokununca geri çağırım, kamera rozeti görünür',
        (tester) async {
      var dokunuldu = 0;
      await tester.pumpWidget(_uygulama(KimlikBaslik(
        baslik: 'Deniz Yılmaz',
        basHarfler: 'DY',
        onAvatarTap: () => dokunuldu++,
      )));
      expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
      expect(
          find.byWidgetPredicate((w) =>
              w is Semantics &&
              w.properties.label == 'Profil fotoğrafını değiştir' &&
              w.properties.button == true),
          findsOneWidget);
      await tester.tap(find.text('DY'));
      expect(dokunuldu, 1);
    });

    testWidgets('fotoğraf yokken etiket "ekle"', (tester) async {
      await tester.pumpWidget(_uygulama(KimlikBaslik(
        baslik: 'Deniz Yılmaz',
        basHarfler: 'DY',
        onAvatarTap: () {},
        avatarEtiketi: 'Profil fotoğrafı ekle',
      )));
      expect(
          find.byWidgetPredicate((w) =>
              w is Semantics && w.properties.label == 'Profil fotoğrafı ekle'),
          findsOneWidget);
    });

    testWidgets('yüklenirken ikinci dokunuş yok sayılır', (tester) async {
      var dokunuldu = 0;
      await tester.pumpWidget(_uygulama(KimlikBaslik(
        baslik: 'Deniz Yılmaz',
        basHarfler: 'DY',
        onAvatarTap: () => dokunuldu++,
        avatarYukleniyor: true,
      )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('DY'), warnIfMissed: false);
      expect(dokunuldu, 0);
    });

    testWidgets('başkasının başlığında rozet yok', (tester) async {
      await tester.pumpWidget(_uygulama(
          const KimlikBaslik(baslik: 'Deniz Yılmaz', basHarfler: 'DY')));
      expect(find.byIcon(Icons.photo_camera_rounded), findsNothing);
    });
  });

  group('ListeAvatari fotoğrafı', () {
    testWidgets('adres yoksa baş harfler', (tester) async {
      await tester.pumpWidget(_uygulama(const ListeAvatari(basHarfler: 'AB')));
      expect(find.text('AB'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('adres varsa ağ görüntüsü, yüklenene kadar baş harfler',
        (tester) async {
      await tester.pumpWidget(_uygulama(const ListeAvatari(
          basHarfler: 'AB', fotoUrl: 'https://x/profil/1/a.jpg')));
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('boş adres fotoğraf sayılmaz', (tester) async {
      await tester.pumpWidget(
          _uygulama(const ListeAvatari(basHarfler: 'AB', fotoUrl: '')));
      expect(find.byType(CachedNetworkImage), findsNothing);
    });
  });
}
