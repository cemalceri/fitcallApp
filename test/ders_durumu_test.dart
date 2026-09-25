// Ders durumu: yönetici "Yapılmadı" dediyse ekranda "Onay Bekliyor" değil
// "Yapılmadı" görünür.
//
// Backend `durum`u bu dersler için geriye uyum gereği 'onay_bekliyor'
// gönderiyor (eski sürüm bilmediği değeri "Planlı" gösterirdi); karar
// `onay_durumu` = 'reddedildi' ile geliyor. Kural iki modelde aynı: yönetici
// Dersler listesi (DersListeItem) ve ofis programı (ProgramDersi).

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/ders_listesi/widgets/ders_liste_item.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/8_ofis/program/widgets/program_constants.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _dersJson(String durum, String? onayDurumu) => {
      'id': 1,
      'baslangic_tarih_saat': '2026-07-23T10:00:00+03:00',
      'bitis_tarih_saat': '2026-07-23T11:00:00+03:00',
      'tarih': '2026-07-23',
      'saat': '10:00',
      'iptal_mi': durum == 'iptal',
      'durum': durum,
      if (onayDurumu != null) 'onay_durumu': onayDurumu,
    };

void main() {
  group('DersListeItem (yönetici Dersler listesi)', () {
    test('reddedilen geçmiş ders "Yapılmadı" görünür', () {
      final ders =
          DersListeItem.fromJson(_dersJson('onay_bekliyor', 'reddedildi'));

      expect(ders.gorunenDurum, 'yapilmadi');
      expect(ders.durumText, 'Yapılmadı');
      expect(DersListeItemWidget.tonu(ders.gorunenDurum), ListeTonu.hata);
    });

    test('kararı verilmemiş geçmiş ders "Onay Bekliyor" kalır', () {
      final ders =
          DersListeItem.fromJson(_dersJson('onay_bekliyor', 'bekliyor'));

      expect(ders.gorunenDurum, 'onay_bekliyor');
      expect(ders.durumText, 'Onay Bekliyor');
    });

    test('iptal ve tamamlanan dersin durumu değişmez', () {
      expect(
          DersListeItem.fromJson(_dersJson('iptal', 'reddedildi')).durumText,
          'İptal');
      expect(
          DersListeItem.fromJson(_dersJson('tamamlandi', 'onaylandi'))
              .durumText,
          'Tamamlandı');
    });
  });

  group('ProgramDersi (ofis programı)', () {
    test('reddedilen geçmiş ders "Yapılmadı" görünür', () {
      final ders =
          ProgramDersi.fromJson(_dersJson('onay_bekliyor', 'reddedildi'));

      expect(ders.onayDurumu, 'reddedildi');
      expect(ders.gorunenDurum, 'yapilmadi');
      expect(ProgramRenkleri.durumMetni(ders.gorunenDurum), 'Yapılmadı');
      expect(ProgramRenkleri.durumRengi(ders.gorunenDurum),
          ProgramRenkleri.iptal);
    });

    test('onay_durumu göndermeyen eski backend: "Onay bekliyor" kalır', () {
      final ders = ProgramDersi.fromJson(_dersJson('onay_bekliyor', null));

      expect(ders.onayDurumu, 'bekliyor');
      expect(ProgramRenkleri.durumMetni(ders.gorunenDurum), 'Onay bekliyor');
    });
  });
}
