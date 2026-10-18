// test/dekont_test.dart
//
// Havale / dekont (2026-10-18): model çözümleme, istemci tarafı dosya
// denetimi (sunucuyla aynı 5 MB ve tür kuralı), tutar ayrıştırma ve ofis
// bildiriminin üye detayına yönlenmesi.

import 'package:fitcall/common/dekont_dosya_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/6_muhasebe/banka_hesabi_model.dart';
import 'package:fitcall/models/6_muhasebe/dekont_model.dart';
import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/services/notification/notification_router.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationModel _bildirim({
  required String tur,
  String? ekran,
  Map<String, dynamic>? params,
  Map<String, dynamic>? display,
}) =>
    NotificationModel(
      id: 1,
      notificationType: tur,
      title: 'Dekont Yüklendi',
      body: 'Ali YILMAZ ödeme dekontu yükledi.',
      actionType: ActionType.navigateToScreen,
      actionScreen: ekran,
      actionParams: params,
      displayData: display,
      isRead: false,
      timestamp: DateTime(2026, 10, 18),
    );

void main() {
  group('DekontModel', () {
    test('sunucu yanıtını çözer (tutar metin ya da sayı)', () {
      final d = DekontModel.fromJson(const {
        'id': 7,
        'durum': 'ISLENDI',
        'durum_etiketi': 'İşlendi',
        'olusturulma_zamani': '2026-10-14T09:42:00+03:00',
        'beyan_tutar': '20500.00',
        'islenen_tutar': 20500,
        'islenen_uyeler': [
          {'uye_id': 1, 'ad': 'Ali YILMAZ'},
          {'uye_id': 2, 'ad': 'Zeynep YILMAZ'},
        ],
        'pdf_mi': true,
        'dosya_adi': 'dekont.pdf',
      });
      expect(d.id, 7);
      expect(d.durum, DekontDurumu.islendi);
      expect(d.beyanTutar, 20500);
      expect(d.islenenTutar, 20500);
      expect(d.islenenUyeler, ['Ali YILMAZ', 'Zeynep YILMAZ']);
      expect(d.pdfMi, isTrue);
      expect(d.ton, ListeTonu.basari);
      expect(d.durumMetni, 'İşlendi');
      expect(d.yuklenme?.hour, 9); // kulüp saati, cihaz saat dilimi değil
    });

    test('durum kelimesi ve ton', () {
      DekontModel d(String durum, {bool yeniden = false}) =>
          DekontModel.fromJson({'id': 1, 'durum': durum, 'yeniden_kontrol': yeniden});
      expect(d('BEKLIYOR').durumMetni, 'Kontrol bekliyor');
      expect(d('BEKLIYOR', yeniden: true).durumMetni, 'Yeniden kontrol ediliyor');
      expect(d('BEKLIYOR').ton, ListeTonu.uyari);
      expect(d('REDDEDILDI').ton, ListeTonu.hata);
      expect(d('GERI_CEKILDI').durum, DekontDurumu.geriCekildi);
      expect(d('YENI_BIR_DURUM').durum, DekontDurumu.bilinmiyor);
    });

    test('gösterilen tutar: işlenmişse işlenen, değilse beyan', () {
      final bekleyen = DekontModel.fromJson(
          const {'id': 1, 'durum': 'BEKLIYOR', 'beyan_tutar': '100.00'});
      expect(bekleyen.gosterilenTutar, 100);
      final tutarsiz = DekontModel.fromJson(const {'id': 2, 'durum': 'BEKLIYOR'});
      expect(tutarsiz.gosterilenTutar, isNull);
    });

    test('Dekontlarım sonucu: bekleyen sayısı yoksa listeden sayılır', () {
      final s = DekontlarimSonucu.fromJson(const {
        'dekontlar': [
          {'id': 1, 'durum': 'BEKLIYOR'},
          {'id': 2, 'durum': 'REDDEDILDI'},
          {'id': 3, 'durum': 'BEKLIYOR'},
        ],
      });
      expect(s.dekontlar.length, 3);
      expect(s.bekleyenSayisi, 2);
      final t = DekontlarimSonucu.fromJson(const {'dekontlar': [], 'bekleyen_sayisi': 5});
      expect(t.bekleyenSayisi, 5);
    });
  });

  group('BankaHesabiModel', () {
    test('liste ve gruplu IBAN', () {
      final liste = BankaHesabiModel.listFromJson(const {
        'hesaplar': [
          {
            'id': 1,
            'etiket': 'Şirket hesabı',
            'banka_adi': 'Örnek Bank',
            'alici_adi': 'Binay Spor',
            'iban': 'TR330006100519786457841326',
            'iban_gruplu': 'TR33 0006 1005 1978 6457 8413 26',
            'karekod_url': 'https://ornek/kare.png',
          },
          {
            'id': 2,
            'etiket': 'Şahıs hesabı',
            'banka_adi': 'Diğer',
            'alici_adi': 'Ad Soyad',
            'iban': 'TR32 0010 0099 9990 1234 5678 90',
            'karekod_url': '',
          },
        ],
      });
      expect(liste.length, 2);
      expect(liste[0].ibanGruplu, 'TR33 0006 1005 1978 6457 8413 26');
      expect(liste[1].iban, 'TR320010009999901234567890'); // kopyalanan boşluksuz
      expect(liste[1].ibanGruplu, 'TR32 0010 0099 9990 1234 5678 90');
      expect(liste[1].karekodUrl, isNull);
    });

    test('ibanGrupla', () {
      expect(ibanGrupla('tr330006100519786457841326'),
          'TR33 0006 1005 1978 6457 8413 26');
    });
  });

  group('Dosya denetimi', () {
    final pdf = '%PDF-1.4'.codeUnits;
    final jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0, 0];
    final png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

    test('tür içerikten anlaşılır', () {
      expect(dekontTuru(pdf), 'application/pdf');
      expect(dekontTuru(jpeg), 'image/jpeg');
      expect(dekontTuru(png), 'image/png');
      expect(dekontTuru('merhaba'.codeUnits), isNull);
    });

    test('5 MB sınırı ve hata cümleleri', () {
      expect(dekontDosyasiHatasi(pdf), isNull);
      expect(dekontDosyasiHatasi(const []), 'Dosya boş.');
      expect(dekontDosyasiHatasi('merhaba'.codeUnits), contains('fotoğraf'));
      final buyuk = List<int>.filled(dekontEnBuyukBayt + 1, 0)..setAll(0, pdf);
      final hata = dekontDosyasiHatasi(buyuk)!;
      expect(hata, contains('en fazla 5 MB'));
      expect(hata, contains('5,0 MB'));
      final sinirda = List<int>.filled(dekontEnBuyukBayt, 0)..setAll(0, pdf);
      expect(dekontDosyasiHatasi(sinirda), isNull);
    });

    test('tutar ayrıştırma (Türkçe biçim)', () {
      expect(tutarCoz(''), isNull);
      expect(tutarCoz('12.500,50'), 12500.5);
      expect(tutarCoz('12500,5'), 12500.5);
      expect(tutarCoz('12500.50'), 12500.5);
      expect(tutarCoz('12.500'), 12500);
      expect(tutarCoz('1.250.000'), 1250000);
      expect(tutarCoz('₺ 300'), 300);
      expect(tutarCoz('abc')!.isNaN, isTrue);
    });
  });

  group('Ofis dekont bildirimi', () {
    test('üye detayına yönlenir; tutar taşımaz', () {
      expect(
        ofisDekontUyeId(_bildirim(
          tur: NotificationType.ofisDekontYuklendi,
          ekran: 'ofis_uye_detay',
          params: {'uye_id': 42},
        )),
        42,
      );
      // Uygulama kapalıyken tür eksik gelebilir: ekran adı yeter.
      expect(
        ofisDekontUyeId(_bildirim(tur: '', ekran: 'ofis_uye_detay', params: {'uye_id': '43'})),
        43,
      );
      expect(
        ofisDekontUyeId(_bildirim(
            tur: NotificationType.ofisDekontYuklendi, display: {'uye_id': 44})),
        44,
      );
    });

    test('başka bildirim ya da üye id yoksa null', () {
      expect(
        ofisDekontUyeId(_bildirim(
            tur: NotificationType.ofisDersKayitTalebi,
            ekran: 'ders_kayit_talepleri',
            params: {'uye_id': 1})),
        isNull,
      );
      expect(ofisDekontUyeId(_bildirim(tur: NotificationType.ofisDekontYuklendi)), isNull);
    });
  });
}
