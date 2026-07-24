// Uygulama genelinde taşma (RenderFlex overflow) taraması.
//
// Her widget küçük/normal/geniş ekran × 1.0/1.3/2.0 yazı ölçeği matrisinde
// render edilir; herhangi bir kombinasyonda taşma olursa test kırılır.
//
// Kapsam: yönetici program ekranı (yeni), yönetici liste/kart bileşenleri,
// antrenör takvimi ve üye takvimi/ana sayfa bileşenleri.
//
// NOT: sayfaların kendisi initState'te API çağırdığı için doğrudan render
// edilemiyor; bu yüzden veriyle beslenen sunum widget'ları test ediliyor.
// Yönetici program sayfasının gövdesi bu amaçla ProgramGorunumu'na ayrıldı.

import 'package:fitcall/models/2_uye/uye_home_ozet_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/2_uye/home/widgets/uye_ozet_serit.dart';
import 'package:fitcall/screens/2_uye/home/widgets/flutter_uye_next_lesson_card.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/stat_card.dart';
import 'package:fitcall/screens/7_yonetici/dersler/widgets/ders_liste_item.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/ders_iptal_dialog.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/ders_islem_sheet.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/ders_sil_dialog.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/etkinlik_form_sheet.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/program_gorunumu.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/program_gun_seridi.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/program_izgara.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/uye_secim_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/tasma_yardimcisi.dart';

import 'package:fitcall/screens/3_antrenor/takvim/widgets/lesson_block.dart'
    as antrenor_blok;
import 'package:fitcall/screens/3_antrenor/takvim/widgets/week_day_selector.dart'
    as antrenor_serit;
import 'package:fitcall/screens/2_uye/takvim/widgets/lesson_block.dart'
    as uye_blok;
import 'package:fitcall/screens/2_uye/takvim/widgets/week_day_selector.dart'
    as uye_serit;

/* ============================== ÖRNEK VERİ ============================== */

Map<String, dynamic> _etkinlikJson({
  String bas = '2026-07-23T10:00:00+03:00',
  String bit = '2026-07-23T11:00:00+03:00',
  int katilimciSayisi = 3,
  bool iptal = false,
}) {
  return {
    'id': 1,
    'kort': 1,
    'kort_adi': 'Kapalı Kort 1',
    'baslangic_tarih_saat': bas,
    'bitis_tarih_saat': bit,
    'seviye': 'Kirmizi',
    'iptal_mi': iptal,
    'is_active': true,
    'is_deleted': false,
    'olusturulma_zamani': bas,
    'guncellenme_zamani': bas,
    'urun': 1,
    'urun_adi': 'Grup Dersi',
    'antrenor': 1,
    'antrenor_adi': 'Ayşe Yılmaz Öğretmen',
    'ucret': 0,
    'uyeler': [
      for (var i = 0; i < katilimciSayisi; i++)
        {'id': i + 1, 'adi': 'Katılımcı $i', 'soyadi': 'Uzun Soyadı Buraya'}
    ],
  };
}

EtkinlikModel _etkinlik({bool iptal = false, int katilimci = 3}) =>
    EtkinlikModel.fromMap(
        _etkinlikJson(iptal: iptal, katilimciSayisi: katilimci));

Map<String, dynamic> _programJson({int kortSayisi = 6, int dersSayisi = 6}) => {
      'hafta_baslangic': '2026-07-20',
      'hafta_bitis': '2026-07-26',
      'bugun': '2026-07-23',
      'gunler': [
        for (var i = 0; i < 7; i++)
          {
            'tarih': '2026-07-${(20 + i).toString().padLeft(2, '0')}',
            'gun_adi': 'Gün',
            'gun_kisa': 'Pt',
            'ders_sayisi': 12,
          }
      ],
      'kortlar': [
        for (var i = 1; i <= kortSayisi; i++)
          {'id': i, 'adi': 'Kapalı Kort $i', 'sira': i, 'max_etkinlik_sayisi': 3}
      ],
      'dersler': [
        for (var i = 1; i <= dersSayisi; i++)
          {
            'id': i,
            'tarih': '2026-07-23',
            'kort_id': (i % kortSayisi) + 1,
            'kort_adi': 'Kapalı Kort',
            'antrenor_id': 1,
            'antrenor_adi': 'Ayşe Yılmaz Öğretmen',
            'antrenor_renk': '#2563EB',
            'urun_id': 1,
            'urun_adi': 'Grup Dersi',
            'seviye': 'Kirmizi',
            'seviye_renk': '#e74c3c',
            'baslangic_tarih_saat': '2026-07-23T${(8 + i).toString().padLeft(2, '0')}:00:00+03:00',
            'bitis_tarih_saat': '2026-07-23T${(9 + i).toString().padLeft(2, '0')}:00:00+03:00',
            'saat': '${(8 + i).toString().padLeft(2, '0')}:00',
            'bitis_saat': '${(9 + i).toString().padLeft(2, '0')}:00',
            'iptal_mi': i == 2,
            'sabit_plan_mi': true,
            'durum': 'planli',
            'katilimci_sayisi': 4,
            'katilimcilar': [
              for (var k = 0; k < 4; k++)
                {'id': k + 1, 'ad_soyad': 'Katılımcı $k Uzun Soyadı'}
            ],
            'aciklama': 'Açıklama metni',
          }
      ],
    };

HaftalikProgram _program({int kortSayisi = 6}) =>
    HaftalikProgram.fromJson(_programJson(kortSayisi: kortSayisi));

EtkinlikFormVerileri _formVerileri({bool duzenleme = false}) =>
    EtkinlikFormVerileri.fromJson({
      'kortlar': [
        {'id': 1, 'adi': 'Kapalı Kort 1 Çok Uzun Ad', 'sira': 1},
      ],
      'antrenorler': [
        {'id': 1, 'ad_soyad': 'Ayşe Yılmaz', 'renk': '#2563EB', 'pasif': false},
      ],
      'urunler': [
        {'id': 1, 'adi': 'Grup Dersi', 'urun_tipi': 'PAKET', 'telafi_mi': false},
      ],
      'seviyeler': [
        {'kod': 'Kirmizi', 'ad': 'Kırmızı', 'renk': '#e74c3c'},
      ],
      'uyeler': [
        for (var i = 1; i <= 8; i++)
          {
            'id': i,
            'ad_soyad': 'Üye $i Çok Uzun Soyadıyla Birlikte',
            'uye_no': 'U-$i',
            'telefon': '555000000$i',
            'pasif': i == 8,
          }
      ],
      'iptal_sebepleri': [
        {'kod': 'HASTALIK', 'ad': 'Hastalık'},
        {'kod': 'DIGER', 'ad': 'Diğer'},
      ],
      'iptal_modlari': [
        {'kod': 'STANDART', 'ad': 'Standart', 'aciklama': '24 saat kuralı normal işler.'},
        {'kod': 'TELAFI_VER', 'ad': 'Telafi ver', 'aciklama': 'Abonelikte 24 saat şartı aranmaz.'},
        {'kod': 'HAKKI_IADE_ET', 'ad': 'Paket hakkını iade et', 'aciklama': 'Hak düşülmez.'},
        {'kod': 'BORC_YAZMA', 'ad': 'Borç yazma', 'aciklama': 'Borç yansıtılmaz.'},
      ],
      'secili_uye_idler': duzenleme ? [1, 2, 3, 4, 5] : <int>[],
      'etkinlik': duzenleme
          ? {
              'id': 7,
              'urun_id': 1,
              'kort_id': 1,
              'antrenor_id': 1,
              'seviye': 'Kirmizi',
              'antrenor_katsayisi': '1.50',
              'ucret': '25',
              'aciklama': 'Not',
              'baslangic_tarih_saat': '2026-07-23T10:00:00+03:00',
              'bitis_tarih_saat': '2026-07-23T11:00:00+03:00',
              'iptal_mi': false,
              'sabit_plan_mi': true,
              'urun_kilitli_mi': true,
            }
          : null,
    });

SilmeEtkisi _silmeEtkisi() => SilmeEtkisi.fromJson({
      'katilimci_sayisi': 12,
      'paket_kullanimi': 12,
      'telafi_kaybolacak': 5,
      'telafi_serbest_kalacak': 4,
      'teyit_sayisi': 12,
      'onay_sayisi': 2,
      'degerlendirme_sayisi': 9,
      'ders': {'tarih': '23.07.2026', 'saat': '10:00', 'kort_adi': 'Kapalı Kort 1'},
    });

DersListeItem _dersListeItem() => DersListeItem.fromJson({
      'id': 1,
      'baslangic_tarih_saat': '2026-07-23T10:00:00+03:00',
      'bitis_tarih_saat': '2026-07-23T11:00:00+03:00',
      'tarih': '23.07.2026',
      'saat': '10:00',
      'antrenor': 1,
      'antrenor_adi': 'Ayşe Yılmaz Öğretmen',
      'kort': 1,
      'kort_adi': 'Kapalı Kort 1',
      'urun': 1,
      'urun_adi': 'Grup Dersi Paketi',
      'seviye': 'Kirmizi',
      'iptal_mi': false,
      'katilimci_sayisi': 4,
      'katilimcilar': [
        for (var i = 0; i < 4; i++)
          {'id': i + 1, 'ad_soyad': 'Katılımcı $i Uzun Soyadı', 'telefon': '5550000000'}
      ],
      'durum': 'planli',
      'onay_durumu': 'bekliyor',
      'aciklama': 'Açıklama',
    });

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr', null);
  });

  /* ===================== YÖNETİCİ — PROGRAM (YENİ) ===================== */

  group('Yönetici program', () {
    tasmaTesti('ProgramGorunumu (tam ekran)', () {
      return ProgramGorunumu(
        program: _program(),
        secilenGun: DateTime(2026, 7, 23),
        onGunSec: (_) {},
        onDersTap: (_) {},
        onBosSlotTap: (_, __) {},
      );
    });

    tasmaTesti('ProgramGorunumu (çok kortlu)', () {
      return ProgramGorunumu(
        program: _program(kortSayisi: 12),
        secilenGun: DateTime(2026, 7, 23),
        islemDevamEdiyor: true,
        onGunSec: (_) {},
        onDersTap: (_) {},
      );
    });

    tasmaTesti('ProgramBaslik', () {
      return ProgramBaslik(
        haftaBaslangic: DateTime(2026, 7, 20),
        haftaBitis: DateTime(2026, 7, 26),
        onOnceki: () {},
        onSonraki: () {},
        onBugun: () {},
      );
    });

    tasmaTesti('ProgramGunSeridi', () {
      final p = _program();
      return ProgramGunSeridi(
        gunler: p.gunler,
        seciliTarih: '2026-07-23',
        bugunTarih: '2026-07-23',
        onGunSec: (_) {},
      );
    });

    tasmaTesti('ProgramIzgara', () {
      final p = _program(kortSayisi: 10);
      return ProgramIzgara(
        kortlar: p.kortlar,
        dersler: p.gununDersleri(DateTime(2026, 7, 23)),
        secilenGun: DateTime(2026, 7, 23),
        onDersTap: (_) {},
        onBosSlotTap: (_, __) {},
      );
    });

    tasmaTesti('EtkinlikFormSheet (yeni)',
        () => EtkinlikFormSheet(veriler: _formVerileri()));

    tasmaTesti('EtkinlikFormSheet (düzenleme)',
        () => EtkinlikFormSheet(veriler: _formVerileri(duzenleme: true)));

    tasmaTesti('UyeSecimSheet', () {
      final v = _formVerileri(duzenleme: true);
      return UyeSecimSheet(uyeler: v.uyeler, seciliIdler: v.seciliUyeIdler);
    });

    tasmaTesti('DersIptalDialog', () {
      final v = _formVerileri();
      return DersIptalDialog(
        sebepler: v.iptalSebepleri,
        modlar: v.iptalModlari,
        dersOzeti: '23.07.2026 10:00 · Kapalı Kort 1',
      );
    });

    tasmaTesti('DersSilDialog', () => DersSilDialog(etki: _silmeEtkisi()));

    tasmaTesti('DersIslemSheet', () {
      final p = _program();
      return DersIslemSheet(ders: p.dersler.first);
    });
  });

  /* ===================== YÖNETİCİ — MEVCUT BİLEŞENLER ===================== */

  group('Yönetici mevcut bileşenler', () {
    tasmaTesti('DersListeItemWidget',
        () => DersListeItemWidget(ders: _dersListeItem(), onTap: () {}));

    tasmaTesti('StatCard', () {
      return const StatCard(
        baslik: 'Bu Ayın Toplam Cirosu',
        deger: '1.234.567 ₺',
        altBaslik: 'Geçen aya göre',
        ikon: Icons.trending_up,
        ikonRenk: Colors.green,
        degisimYuzdesi: 12.5,
      );
    });
  });

  /* ===================== ANTRENÖR ===================== */

  group('Antrenör takvimi', () {
    tasmaTesti('WeekDaySelector', () {
      return antrenor_serit.WeekDaySelector(
        selectedDay: DateTime(2026, 7, 23),
        focusedDay: DateTime(2026, 7, 23),
        lessonCounts: {
          for (var i = 20; i <= 26; i++) DateTime(2026, 7, i): 12,
        },
        onDaySelected: (_) {},
        onPageChanged: (_) {},
      );
    });

    tasmaTesti(
      'LessonBlock',
      () => antrenor_blok.LessonBlock(ders: _etkinlik(katilimci: 6), onTap: () {}),
      sar: (w) => Center(child: SizedBox(width: 300, height: 90, child: w)),
    );

    tasmaTesti(
      'LessonBlock (iptal, dar)',
      () => antrenor_blok.LessonBlock(ders: _etkinlik(iptal: true), onTap: () {}),
      sar: (w) => Center(child: SizedBox(width: 140, height: 60, child: w)),
    );
  });

  /* ===================== ÜYE ===================== */

  group('Üye ekranları', () {
    tasmaTesti('WeekDaySelector', () {
      return uye_serit.WeekDaySelector(
        selectedDay: DateTime(2026, 7, 23),
        focusedDay: DateTime(2026, 7, 23),
        lessonCounts: {
          for (var i = 20; i <= 26; i++) DateTime(2026, 7, i): 12,
        },
        onDaySelected: (_) {},
        onPageChanged: (_) {},
      );
    });

    tasmaTesti(
      'LessonBlock',
      () => uye_blok.LessonBlock(ders: _etkinlik(katilimci: 6), onTap: () {}),
      sar: (w) => Center(child: SizedBox(width: 300, height: 90, child: w)),
    );

    tasmaTesti('UyeOzetSerit', () {
      return UyeOzetSerit(
        ozet: UyeOzetModel.fromJson(const {
          'bakiye': -12345.67,
          'kalan_paket_hak': 12,
          'aktif_telafi': 2,
        }),
      );
    });

    tasmaTesti('UyeOzetSerit (yükleniyor)',
        () => const UyeOzetSerit(isLoading: true));

    tasmaTesti('UyeNextLessonCard',
        () => UyeNextLessonCard(nextLesson: _etkinlik()));

    tasmaTesti('UyeNextLessonCard (ders yok)',
        () => const UyeNextLessonCard(nextLesson: null));
  });
}
