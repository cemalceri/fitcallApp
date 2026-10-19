// Uygulama genelinde taşma (RenderFlex overflow) taraması.
//
// Her widget küçük/normal/geniş ekran × 1.0/1.3/2.0 yazı ölçeği matrisinde
// render edilir; herhangi bir kombinasyonda taşma olursa test kırılır.
//
// Kapsam: ofis program ekranı ve üye listesi, yönetici liste/kart bileşenleri,
// antrenör takvimi ve üye takvimi/ana sayfa bileşenleri.
//
// NOT: sayfaların kendisi initState'te API çağırdığı için doğrudan render
// edilemiyor; bu yüzden veriyle beslenen sunum widget'ları test ediliyor.
// Ofis program sayfasının gövdesi bu amaçla ProgramGorunumu'na ayrıldı.

import 'dart:convert';

import 'package:fitcall/models/6_muhasebe/banka_hesabi_model.dart';
import 'package:fitcall/models/6_muhasebe/dekont_model.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/banka_hesabi_karti.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/dekont_detay.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/dekont_listesi.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/dekont_yukle_govdesi.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/havale_bilgi_satiri.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/hesaplar_gorunumu.dart';
import 'package:fitcall/models/2_uye/gecmis_ders_model.dart';
import 'package:fitcall/models/2_uye/uye_home_ozet_model.dart';
import 'package:fitcall/models/2_uye/uye_odul_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/5_etkinlik/misafir_model.dart';
import 'package:fitcall/models/8_urun/uye_urun_model.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/models/1_common/degerlendirme_models.dart';
import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:fitcall/models/1_common/surum_notu_model.dart';
import 'package:fitcall/screens/1_common/degerlendirmeler/widgets/degerlendirme_detayi.dart';
import 'package:fitcall/screens/1_common/degerlendirmeler/widgets/degerlendirmeler_gorunumu.dart';
import 'package:fitcall/screens/1_common/degerlendirmeler/widgets/puan_parcalari.dart';
import 'package:fitcall/models/1_common/duyuru_okuma_models.dart';
import 'package:fitcall/screens/1_common/duyurular/widgets/duyuru_yonetim_listesi.dart';
import 'package:fitcall/screens/1_common/duyurular/widgets/okuma_durumu_gorunumu.dart';
import 'package:fitcall/screens/1_common/acilis_popup/widgets/dogum_gunu_popup.dart';
import 'package:fitcall/screens/1_common/acilis_popup/widgets/duyuru_popup.dart';
import 'package:fitcall/screens/1_common/acilis_popup/widgets/surum_notu_popup.dart';
import 'package:fitcall/screens/1_common/neler_yeni_page.dart';
import 'package:fitcall/screens/1_common/widgets/duyuru_detay_sheet.dart';
import 'package:fitcall/screens/2_uye/home/widgets/duyuru_carousel.dart';
import 'package:fitcall/screens/1_common/1_notification/pages/bildirim_detay_sheet.dart';
import 'package:fitcall/screens/1_common/1_notification/widgets/bildirim_ortak_widgetlari.dart';
import 'package:fitcall/screens/1_common/1_notification/widgets/plan_disi_bildirim_ozeti.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/lesson_approval_dialog.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/models/4_auth/kayit_secenekleri_model.dart';
import 'package:fitcall/models/4_auth/sifre_sifirlama_model.dart';
import 'package:fitcall/screens/1_common/widgets/parlaklik_ipucu.dart';
import 'package:fitcall/screens/1_common/widgets/qr_kod_gorseli.dart';
import 'package:fitcall/screens/1_common/widgets/qr_sonuc_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/4_auth/widgets/hesap_secim_listesi.dart';
import 'package:fitcall/screens/4_auth/widgets/kayit_sihirbazi.dart';
import 'package:fitcall/screens/7_yonetici/antrenorler/widgets/antrenor_liste_item.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_filtre_sheet.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_siralama_sheet.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uyeler_gorunumu.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_models.dart';
import 'package:fitcall/screens/8_ofis/uyeler/widgets/ofis_uyeler_gorunumu.dart';
import 'package:fitcall/screens/8_ofis/widgets/ofis_bottom_bar.dart';
import 'package:fitcall/screens/8_ofis/widgets/ofis_drawer.dart';
import 'package:fitcall/screens/2_uye/gecmis_dersler/widgets/gecmis_dersler_listesi.dart';
import 'package:fitcall/screens/1_common/widgets/kabuk_alt_bar.dart';
import 'package:fitcall/screens/2_uye/home/widgets/uye_odul_sayaci.dart';
import 'package:fitcall/screens/2_uye/home/widgets/uye_ozet_serit.dart';
import 'package:fitcall/screens/2_uye/home/widgets/flutter_uye_next_lesson_card.dart';
import 'package:fitcall/screens/2_uye/widgets/uye_urun_list_view.dart';
import 'package:fitcall/models/3_antrenor/home_card_model.dart';
import 'package:fitcall/screens/1_common/yardim_page.dart';
import 'package:fitcall/screens/1_common/yonetim_yardim_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_yardim_page.dart';
import 'package:fitcall/screens/3_antrenor/home/widgets/info_cards_carousel.dart';
import 'package:fitcall/services/etkinlik/ders_teyit_service.dart';
import 'package:fitcall/screens/5_etkinlik/teyit_bekleyenler_page.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/misafir_ekle_sheet.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/yoklama_hizli_secim.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/daily_summary_card.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/period_filter_tabs.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/stat_card.dart';
import 'package:fitcall/models/9_yonetici/doluluk_haritasi_model.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/rapor_gruplari.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/donem_kutusu.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/stat_cards_grid.dart';
import 'package:fitcall/screens/1_common/ders_listesi/widgets/ders_liste_item.dart';
import 'package:fitcall/screens/8_ofis/program/widgets/ders_iptal_dialog.dart';
import 'package:fitcall/screens/8_ofis/program/widgets/ders_islem_sheet.dart';
import 'package:fitcall/screens/8_ofis/program/widgets/ders_sil_dialog.dart';
import 'package:fitcall/screens/8_ofis/program/widgets/etkinlik_form_sheet.dart';
import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:fitcall/screens/1_common/hakedis/widgets/hakedis_antrenor_listesi.dart';
import 'package:fitcall/screens/1_common/hakedis/widgets/hakedis_ay_panosu.dart';
import 'package:fitcall/screens/1_common/hakedis/widgets/hakedis_ay_izgarasi.dart';
import 'package:fitcall/screens/1_common/hakedis/widgets/hakedis_ders_karti.dart';
import 'package:fitcall/screens/1_common/program/program_gorunumu.dart';
import 'package:fitcall/screens/1_common/program/program_gun_seridi.dart';
import 'package:fitcall/screens/1_common/program/program_izgara.dart';
import 'package:fitcall/screens/8_ofis/program/widgets/uye_secim_sheet.dart';
import 'package:fitcall/screens/3_antrenor/program/widgets/ders_kayit_talebi_sheet.dart';
import 'package:fitcall/screens/3_antrenor/program/widgets/program_bilgi_sheet.dart';
import 'package:fitcall/screens/8_ofis/ders_kayit_talepleri/talep_islemleri.dart';
import 'package:fitcall/screens/8_ofis/ders_kayit_talepleri/widgets/ders_kayit_talepleri_gorunumu.dart';
import 'package:fitcall/screens/7_yonetici/widgets/yonetici_bottom_bar.dart';
import 'package:fitcall/screens/1_common/3_mobil_app/app_update_page.dart';
import 'package:fitcall/screens/7_yonetici/widgets/yonetici_drawer.dart';
import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/degerlendirme_ornekleri.dart';
import 'support/duyuru_ornekleri.dart';
import 'support/ofis_ornekleri.dart';
import 'support/tasma_yardimcisi.dart';

import 'package:fitcall/screens/3_antrenor/eksik_yoklama/widgets/eksik_yoklama_listesi.dart';
import 'package:fitcall/screens/2_uye/home/widgets/flutter_uye_header.dart';
import 'package:fitcall/screens/3_antrenor/home/widgets/antrenor_drawer.dart';
import 'package:fitcall/screens/3_antrenor/home/widgets/home_header.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/lesson_block.dart'
    as antrenor_blok;
import 'package:fitcall/screens/1_common/takvim/hafta_gun_secici.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_ajanda.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_zaman_cizelgesi.dart';
import 'package:fitcall/screens/2_uye/takvim/widgets/lesson_block.dart'
    as uye_blok;
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/profil_fotografi_secici.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';
import 'package:fitcall/screens/8_ofis/ana_sayfa/widgets/ofis_ana_sayfa_gorunumu.dart';
import 'package:fitcall/screens/8_ofis/dersler/onay_bekleyen_gunler_page.dart';
import 'package:fitcall/screens/8_ofis/dersler/widgets/ders_yonetim_sheet.dart';
import 'package:fitcall/screens/8_ofis/dersler/widgets/ofis_dersler_gorunumu.dart';
import 'package:fitcall/screens/8_ofis/plan_disi/plan_disi_kararlar_page.dart';
import 'package:fitcall/screens/8_ofis/plan_disi/widgets/plan_disi_karar_sheet.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';
import 'package:fitcall/screens/3_antrenor/home/widgets/next_lesson_card.dart';
import 'package:fitcall/screens/3_antrenor/home/widgets/info_card_item.dart';
import 'package:fitcall/screens/3_antrenor/home/widgets/gunluk_kokpit_card.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/screens/1_common/ders_listesi/widgets/ders_istatistik_kartlar.dart';
import 'package:fitcall/screens/1_common/widgets/erisim_kisitli.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/profile_header.dart';
import 'package:fitcall/screens/1_common/takvim/iptal_taramasi.dart';
import 'package:fitcall/screens/1_common/ayarlar/widgets/renk_temasi_secici.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/models/3_antrenor/gunluk_ozet_model.dart';

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

EtkinlikModel _etkinlik({
  bool iptal = false,
  int katilimci = 3,
  String bas = '2026-07-23T10:00:00+03:00',
  String bit = '2026-07-23T11:00:00+03:00',
}) =>
    EtkinlikModel.fromMap(_etkinlikJson(
      iptal: iptal,
      katilimciSayisi: katilimci,
      bas: bas,
      bit: bit,
    ));

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
          {
            'id': i,
            'adi': 'Kapalı Kort $i',
            'sira': i,
            'max_etkinlik_sayisi': 3
          }
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
            'baslangic_tarih_saat':
                '2026-07-23T${(8 + i).toString().padLeft(2, '0')}:00:00+03:00',
            'bitis_tarih_saat':
                '2026-07-23T${(9 + i).toString().padLeft(2, '0')}:00:00+03:00',
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
        {
          'id': 1,
          'adi': 'Grup Dersi',
          'urun_tipi': 'PAKET',
          'telafi_mi': false
        },
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
        {
          'kod': 'STANDART',
          'ad': 'Standart',
          'aciklama': '24 saat kuralı normal işler.'
        },
        {
          'kod': 'TELAFI_VER',
          'ad': 'Telafi ver',
          'aciklama': 'Abonelikte 24 saat şartı aranmaz.'
        },
        {
          'kod': 'HAKKI_IADE_ET',
          'ad': 'Paket hakkını iade et',
          'aciklama': 'Hak düşülmez.'
        },
        {
          'kod': 'BORC_YAZMA',
          'ad': 'Borç yazma',
          'aciklama': 'Borç yansıtılmaz.'
        },
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
      'ders': {
        'tarih': '23.07.2026',
        'saat': '10:00',
        'kort_adi': 'Kapalı Kort 1'
      },
    });

UyeListeItem _uyeListeItem({
  int no = 1,
  double bakiye = -1850,
  bool aktif = true,
  Map<String, dynamic> ek = const {},
}) =>
    UyeListeItem.fromJson({
      'id': no,
      'uye_no': 10400 + no,
      'adi': 'Deniz Ayşegül',
      'soyadi': 'Arslanoğulları $no',
      'ad_soyad': 'Deniz Ayşegül Arslanoğulları $no',
      'telefon': '5551112233',
      'seviye_rengi': 'Kirmizi',
      'seviye_rengi_hex': '#C2500B',
      'aktif_mi': aktif,
      'uye_tipi': 1,
      'uye_turu': 'Öğrenci (indirimli)',
      'yas': 14,
      'bakiye': bakiye,
      ...ek,
    });

UyeIstatistik _uyeIstatistik() => UyeIstatistik.fromJson({
      'toplam_uye': 184,
      'aktif_uye': 161,
      'pasif_uye': 23,
      'bu_ay_yeni_kayit': 7,
      'borclu_uye': 1234,
    });

OfisUyeListeItem _ofisUyeListeItem({int no = 1, bool aktif = true}) =>
    OfisUyeListeItem.fromJson({
      'id': no,
      'uye_no': 10400 + no,
      'adi': 'Deniz Ayşegül',
      'soyadi': 'Arslanoğulları $no',
      'ad_soyad': 'Deniz Ayşegül Arslanoğulları $no',
      'telefon': '5551112233',
      'seviye_rengi': 'Kirmizi',
      'seviye_rengi_hex': '#C2500B',
      'aktif_mi': aktif,
      'uye_tipi': 1,
      'uye_turu': 'Öğrenci (indirimli)',
      'yas': 14,
      'son_ders_tarihi': '2026-07-23T10:00:00+03:00',
    });

/// [OfisUyelerGorunumu] için ortak parametreler.
Widget _ofisUyelerGorunumu({
  required List<OfisUyeListeItem> uyeler,
  bool yukleniyor = false,
  String? hata,
  String arama = '',
  bool dahaYukleniyor = false,
  String? dahaHatasi,
}) {
  return OfisUyelerGorunumu(
    uyeler: uyeler,
    toplam: 248,
    yukleniyor: yukleniyor,
    hata: hata,
    dahaYukleniyor: dahaYukleniyor,
    dahaHatasi: dahaHatasi,
    onDahaFazla: () {},
    onDahaTekrarDene: () {},
    filtre: 'tumu',
    aramaDenetleyicisi: TextEditingController(text: arama),
    onFiltre: (_) {},
    onYenile: () async {},
    onYenidenDene: () {},
    onUyeSec: (_) {},
    onAra: (_) {},
    onWhatsapp: (_) {},
  );
}

/// Bütün filtreler dolu: çip şeridinin en kalabalık hali.
final _tumFiltreler = UyeFiltreleri(
  durum: UyeDurumFiltresi.pasif,
  borc: BorcDurumFiltresi.fazlaOdemis,
  borcMin: 125000,
  borcMax: 9999999,
  kesinlesti: false,
  kontrolSonra: DateTime(2026, 1, 1),
  kontrolOnce: DateTime(2026, 12, 31),
  odemeSonra: DateTime(2025, 11, 30),
  dersOnce: DateTime(2026, 9, 18),
  kayitSonra: DateTime(2026, 10, 1),
);

/// [UyelerGorunumu] için ortak parametreler; testler yalnız farkı yazar.
Widget _uyelerGorunumu({
  required List<UyeListeItem> uyeler,
  UyeIstatistik? istatistik,
  bool yukleniyor = false,
  String? hata,
  String arama = '',
  UyeFiltreleri filtreler = UyeFiltreleri.bos,
  UyeSiralama siralama = UyeSiralama.varsayilan,
  UyeOnAyari? seciliOnAyar = UyeOnAyari.tumu,
  UyeFiltreOzeti? ozet,
  bool dahaYukleniyor = false,
  String? dahaHatasi,
}) {
  return UyelerGorunumu(
    istatistik: istatistik,
    uyeler: uyeler,
    toplam: 248,
    yukleniyor: yukleniyor,
    hata: hata,
    dahaYukleniyor: dahaYukleniyor,
    dahaHatasi: dahaHatasi,
    onDahaFazla: () {},
    onDahaTekrarDene: () {},
    filtreler: filtreler,
    siralama: siralama,
    seciliOnAyar: seciliOnAyar,
    filtreOzeti: ozet,
    aramaDenetleyicisi: TextEditingController(text: arama),
    onOnAyar: (_) {},
    onFiltrele: () {},
    onSirala: () {},
    onFiltreDegistir: (_) {},
    onYenile: () async {},
    onYenidenDene: () {},
    onUyeSec: (_) {},
    onAra: (_) {},
    onWhatsapp: (_) {},
  );
}

AntrenorListeItem _antrenorListeItem({
  bool puanli = true,
  int degerlendirme = 123,
}) =>
    AntrenorListeItem.fromJson({
      'id': 1,
      'adi': 'Ayşe',
      'soyadi': 'Yılmaz Öğretmenoğulları',
      'ad_soyad': 'Ayşe Yılmaz Öğretmenoğulları',
      'e_posta': 'ayse@binay.fit',
      'telefon': '5550000000',
      'renk': '#2438C8',
      'aktif_mi': false,
      'bugun_ders_sayisi': 12,
      'haftalik_ders_sayisi': 48,
      'ortalama_puan': puanli ? 4.8 : null,
      'degerlendirme_sayisi': puanli ? degerlendirme : 0,
      'ogrenci_sayisi': 126,
    });

DersListeItem _dersListeItem(
        {String durum = 'planli', String onayDurumu = 'bekliyor'}) =>
    DersListeItem.fromJson({
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
          {
            'id': i + 1,
            'ad_soyad': 'Katılımcı $i Uzun Soyadı',
            'telefon': '5550000000'
          }
      ],
      'durum': durum,
      'onay_durumu': onayDurumu,
      'aciklama': 'Açıklama',
    });

void main() {
  // Renk temaları: kimlik yüzeyleri ve yeni ortak bileşenler. tasmaTesti her
  // bileşeni ayrıca uç takım temalarında da çizer (bkz. kUcTemalar).
  group('Renk temaları ve kimlik yüzeyleri', () {
    tasmaTesti(
      'KimlikBaslik (uzun ad + üç kapsül)',
      () => const KimlikBaslik(
        baslik: 'Deniz Ayşegül Arslanoğulları Kandemir',
        basHarfler: 'DK',
        altBaslik: 'Üye No: 104286 · Kartal · Sorumlu hocasısınız',
        kapsuller: ['Sarı top', 'Salı · Perşembe 17:00', 'Telafi hakkı var'],
      ),
    );
    // Üyenin kendi profilinde avatar dokunulabilir: rozet + yüklenirken halka.
    tasmaTesti(
      'KimlikBaslik (düzenlenebilir avatar, yükleniyor)',
      () => KimlikBaslik(
        baslik: 'Deniz Ayşegül Arslanoğulları Kandemir',
        basHarfler: 'DK',
        altBaslik: 'Üye No: 104286 · Öğrenci (indirimli)',
        onAvatarTap: () {},
        avatarYukleniyor: true,
      ),
    );
    tasmaTesti(
      'ProfilFotoSecenekleri (fotoğraf var)',
      () => ProfilFotoSecenekleri(fotoVar: true, onSec: (_) {}),
    );
    // Profil sayfasının fotoğraflı başlığı: KimlikBaslik'in yüzeysiz
    // varyantı, kendi yüzeyini çizmiyor.
    tasmaTesti(
      'KimlikBaslik (yüzeysiz)',
      () => const KimlikBaslik(
        baslik: 'Deniz Ayşegül Arslanoğulları Kandemir',
        basHarfler: 'DK',
        altBaslik: 'Üye No: 104286 · Kartal Şubesi · Sarı top',
        kapsuller: ['Telafi hakkı var'],
        yuzeysiz: true,
      ),
      sar: (w) => KimlikYuzeyi(child: w),
    );
    tasmaTesti(
      'ProfileHeader (uzun ad)',
      () => ProfileHeader(
        uye: _uyeModeli('Deniz Ayşegül', 'Arslanoğulları Kandemir'),
        seviyeRenk: const Color(0xFFE53935),
      ),
    );
    tasmaTesti(
      'ProfileHeader (düzenlenemez)',
      () => ProfileHeader(
        uye: _uyeModeli('Ali', 'Yıldız'),
        seviyeRenk: const Color(0xFF43A047),
        duzenlenebilir: false,
      ),
    );
    tasmaTesti(
      'GecisCubugu',
      () => const Column(
        children: [
          GecisCubugu(deger: 0),
          SizedBox(height: 8),
          GecisCubugu(deger: 0.42),
          SizedBox(height: 8),
          GecisCubugu(deger: 1),
        ],
      ),
    );
    tasmaTesti(
      'DersIstatistikKartlar',
      () => DersIstatistikKartlar(
        data: DersIstatistik(
          bugunDers: 128,
          tamamlanan: 96,
          devamEden: 12,
          bekleyen: 14,
          iptal: 6,
        ),
      ),
    );
    tasmaTesti('ErisimKisitli (kabuk içinde)',
        () => const ErisimKisitli(geriButonu: false));
    tasmaTesti('ErisimKisitli (geri butonlu)', () => const ErisimKisitli());
  });

  /* ======================= BAŞLIK BANDI PARÇALARI ======================= */

  group('Başlık bandı parçaları', () {
    tasmaTesti(
      'BaslikBandi + ikon butonları',
      () => BaslikBandi(
        child: Row(
          children: [
            BaslikIkonButonu(
                ikon: Icons.menu_rounded, ipucu: 'Menü', onTap: () {}),
            const Expanded(child: Text('Haftalık Program')),
            BaslikIkonButonu(
                ikon: Icons.refresh_rounded, ipucu: 'Yenile', onTap: () {}),
            BaslikIkonButonu(
                ikon: Icons.notifications_outlined,
                ipucu: 'Bildirimler',
                onTap: () {}),
          ],
        ),
      ),
    );
    // Çip şeridi her kullanımda yatay kaydırılabilir (dersler_page,
    // antrenorler_page): test de onu yansıtıyor.
    tasmaTesti(
      'BaslikCipi şeridi',
      () => BaslikBandi(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              BaslikCipi(etiket: 'Tümü', secili: true, onSec: () {}),
              const SizedBox(width: 8),
              BaslikCipi(etiket: 'Tamamlandı', secili: false, onSec: () {}),
              const SizedBox(width: 8),
              BaslikCipi(etiket: 'Bekliyor', secili: false, onSec: () {}),
              const SizedBox(width: 8),
              BaslikCipi(etiket: 'İptal', secili: false, onSec: () {}),
            ],
          ),
        ),
      ),
    );
    tasmaTesti(
      'RenkliDurumCubugu',
      () => const RenkliDurumCubugu(
        child: Center(child: Text('İçerikle kayan başlık')),
      ),
    );
    // Raporlar: sağda dönemin günleri, altta tam genişlik dönem seçici.
    tasmaTesti(
      'SekmeBasligi (tarih kapsülü + dönem seçici)',
      () => SekmeBasligi(
        baslik: 'Raporlar',
        sag: BaslikKapsulu(
          DonemFiltresi.buHafta.aralikMetni(DateTime(2026, 10, 2)),
          ikon: Icons.date_range_rounded,
        ),
        alt: PeriodFilterTabs(
          seciliDonem: DonemFiltresi.buHafta,
          onDonemChanged: (_) {},
        ),
      ),
    );
    tasmaTesti(
      'SekmeBasligi (sayı kapsülü + üçlü seçici)',
      () => SekmeBasligi(
        baslik: 'Antrenörler',
        sag: const BaslikKapsulu('128 antrenör'),
        alt: BaslikSecici<String>(
          secenekler: const [
            ('aktif', 'Aktif'),
            ('pasif', 'Pasif'),
            ('tumu', 'Tümü'),
          ],
          secili: 'aktif',
          onSec: (_) {},
        ),
      ),
    );
    tasmaTesti(
      'BaslikSecici (dört dilim)',
      () => BaslikBandi(
        child: BaslikSecici<int>(
          secenekler: const [
            (0, 'Tümü'),
            (1, 'Aktif'),
            (2, 'Pasif'),
            (3, 'Borçlular'),
          ],
          secili: 3,
          onSec: (_) {},
        ),
      ),
    );
    tasmaTesti(
      'KapaninciBaslik',
      () => const KapaninciBaslik(
        child: Text('Kapanınca küçülen başlık'),
      ),
    );
    tasmaTesti(
      'KimlikYuzeyi + KimlikKapsulu',
      () => const KimlikYuzeyi(
        child: Row(
          children: [
            Expanded(child: Text('Bugünün Özeti · çok uzun bir başlık')),
            Flexible(child: KimlikKapsulu('Salı 14 Ekim', ikon: Icons.event)),
          ],
        ),
      ),
    );
    tasmaTesti(
      'RenkTemasiSecici',
      () => RenkTemasiSecici(secili: TakimTemasi.mavi, onSec: (_) {}),
      sar: (w) => SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: w)),
    );
    tasmaTesti(
      'NextLessonCard (antrenör, kalabalık grup)',
      () => NextLessonCard(nextLesson: _etkinlik(katilimci: 6)),
      sar: (w) => SingleChildScrollView(child: w),
    );
    tasmaTesti('NextLessonCard (antrenör, ders yok)',
        () => const NextLessonCard(nextLesson: null));
    tasmaTesti(
      'GunlukKokpitCard (iptal + eksik yoklama)',
      () => GunlukKokpitCard(
        ozet: GunlukOzetModel(
          tarih: '2026-07-23',
          dersSayisi: 12,
          iptal: 2,
          tamamlanan: 5,
          kalan: 5,
          ogrenciSayisi: 34,
          ilkDers: '09:00',
          sonDers: '21:30',
          eksikYoklama: 2,
          eksikYoklamaDersler: const [],
          eksikYoklamaGecmis: 3,
        ),
      ),
    );
    for (final kart in _yapilacakKartlar()) {
      tasmaTesti('InfoCardItem (${kart.type.name})',
          () => InfoCardItem(card: kart, onTap: () {}));
    }
    tasmaTesti(
      'YikiciButon (uzun etiket, yükleniyor)',
      () => Row(
        children: [
          Expanded(
            child: YikiciButon(
                etiket: 'İptal talebini gönder ve öğrencilere bildir',
                onPressed: () {}),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                YikiciButon(etiket: 'Sil', onPressed: () {}, yukleniyor: true),
          ),
        ],
      ),
    );
    tasmaTesti(
      'IptalTaramasi (dar blok)',
      () => const SizedBox(
        width: 120,
        height: 48,
        child: IptalTaramasi(
          yaricap: BorderRadius.all(Radius.circular(8)),
          child: Text('İptal edilen ders başlığı', maxLines: 1),
        ),
      ),
    );
    tasmaTesti(
      'ProfilSecPage (dört profil, uzun adlar)',
      () => ProfilSecPage([
        _profil(1, 'yonetici', 'Selin', 'Arslanoğulları Kandemir',
            'Binay Tenis Akademisi Kartal Şubesi'),
        _profil(2, 'antrenor', 'Ahmet', 'Kaya', 'Binay Akademi'),
        _profil(3, 'uye', 'Deniz Ayşegül', 'Yılmaz', null),
        _profil(4, 'uye', 'Ece', 'Yılmaz', 'Binay Akademi Ataşehir'),
      ]),
    );
  });
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

    // Ofis kabuğundaki hâl: menülü.
    tasmaTesti('ProgramBaslik (menülü)', () {
      return ProgramBaslik(
        haftaBaslangic: DateTime(2026, 7, 20),
        haftaBitis: DateTime(2026, 7, 26),
        onOnceki: () {},
        onSonraki: () {},
        onBugun: () {},
        onMenu: () {},
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

  /* =================== DERS KAYIT TALEBİ (ANTRENÖR + OFİS) =================== */

  group('Ders kayıt talebi', () {
    // Antrenörün tüm programı: salt-okunur, geri oklu, kendi dersleri vurgulu,
    // bekleyen talep kesik çizgili blok olarak yerleşimde.
    HaftalikProgram talepliProgram() => HaftalikProgram.fromJson({
          ..._programJson(),
          'benim_antrenor_id': 1,
          'talepler': [
            ornekTalepJson(id: 1, kortId: 2),
            ornekTalepJson(id: 2, kortId: 3, saat: '09:00', bitisSaat: '09:30'),
          ],
        });

    tasmaTesti('ProgramGorunumu (antrenör, tüm program)', () {
      return ProgramGorunumu(
        program: talepliProgram(),
        secilenGun: DateTime(2026, 7, 23),
        baslik: 'Tüm Program',
        onGeri: () {},
        onOncekiHafta: () {},
        onSonrakiHafta: () {},
        onBugun: () {},
        onGunSec: (_) {},
        onDersTap: (_) {},
        onTalepTap: (_) {},
        vurgulaAntrenorId: 1,
      );
    });

    tasmaTesti('DersKayitTalebiSheet', () {
      final p = talepliProgram();
      return DersKayitTalebiSheet(
        kortlar: p.kortlar,
        varsayilan: TalepVarsayilani.hesapla(
          program: p,
          gun: DateTime(2026, 7, 23),
          simdi: DateTime(2026, 7, 23, 12, 10),
        ),
      );
    });

    tasmaTesti('ProgramDersBilgiSheet', () {
      final p = talepliProgram();
      return ProgramDersBilgiSheet(ders: p.dersler.first, benim: true);
    });

    tasmaTesti('ProgramDersBilgiSheet (iptal)', () {
      final p = talepliProgram();
      return ProgramDersBilgiSheet(ders: p.dersler[1]);
    });

    tasmaTesti('ProgramTalepBilgiSheet',
        () => ProgramTalepBilgiSheet(talep: ornekTalep()));

    tasmaTesti('DersKayitTalepleriGorunumu (dolu)', () {
      return DersKayitTalepleriGorunumu(
        talepler: [ornekTalep(id: 1), ornekTalep(id: 2, saat: '19:00')],
        yukleniyor: false,
        onGeri: () {},
        onYenile: () async {},
        onYenidenDene: () {},
        onKayitOlustur: (_) {},
        onReddet: (_) {},
        onProgramdaGoster: (_) {},
      );
    });

    tasmaTesti('DersKayitTalepleriGorunumu (boş)', () {
      return DersKayitTalepleriGorunumu(
        talepler: const [],
        yukleniyor: false,
        onYenile: () async {},
        onYenidenDene: () {},
        onKayitOlustur: (_) {},
        onReddet: (_) {},
        onProgramdaGoster: (_) {},
      );
    });

    tasmaTesti('DersKayitTalepleriGorunumu (hata)', () {
      return DersKayitTalepleriGorunumu(
        talepler: null,
        yukleniyor: false,
        hata: 'Sunucuya ulaşılamadı.',
        onYenile: () async {},
        onYenidenDene: () {},
        onKayitOlustur: (_) {},
        onReddet: (_) {},
        onProgramdaGoster: (_) {},
      );
    });

    tasmaTesti(
        'EtkinlikFormSheet (talepten)',
        () => EtkinlikFormSheet(
              veriler: _formVerileri(),
              onSecilenKortId: 2,
              onSecilenBaslangic: DateTime(2026, 7, 23, 17, 30),
              onSecilenBitis: DateTime(2026, 7, 23, 18, 30),
              talep: ornekTalep(),
            ));

    tasmaTesti(
        'TalepReddetDialog', () => TalepReddetDialog(talep: ornekTalep()));

    tasmaTesti('TalepEylemSheet', () => TalepEylemSheet(talep: ornekTalep()));
  });

  /* ===================== HAKEDİŞ SAATLERİ (ORTAK) ===================== */
  // Bu bileşenler yönetici ve antrenör ekranlarında ORTAK kullanılıyor
  // (screens/1_common/hakedis/), tek bir taşma taraması ikisini de kapsar.

  group('Hakediş saatleri', () {
    tasmaTesti('HakedisAyPanosu (dolu ay)', () {
      return HakedisAyPanosu(
        ozet: _hakedisOzet(),
        seciliIndex: 0,
        onAySec: (_) {},
        onGrupTap: (_, __, ___) {},
      );
    });

    tasmaTesti('HakedisAyPanosu (dersi olmayan ay)', () {
      // Boş ayda rol kartı yerine "ders yok" kutusu render edilir.
      return HakedisAyPanosu(
        ozet: _hakedisOzet(),
        seciliIndex: 2,
        onAySec: (_) {},
        onGrupTap: (_, __, ___) {},
      );
    });

    tasmaTesti('HakedisAyIzgarasi (4x3)', () {
      return HakedisAyIzgarasi(
        aylar: _hakedisOzet().aylar.map((a) => a.hucre).toList(),
        seciliIndex: 0,
        onAySec: (_) {},
      );
    });

    tasmaTesti('HakedisAntrenorListesiGorunumu (dolu ay)', () {
      final veri = _hakedisAntrenorListesi();
      return HakedisAntrenorListesiGorunumu(
        aylar: veri.aylar,
        seciliIndex: 0,
        onAySec: (_) {},
        antrenorler: veri.antrenorler,
        onAntrenorTap: (_) {},
      );
    });

    tasmaTesti('HakedisAntrenorListesiGorunumu (dersi olmayan ay)', () {
      // Seçili ayda kimsenin dersi yoksa satırlar "Bu ayda ders yok" der.
      final veri = _hakedisAntrenorListesi();
      return HakedisAntrenorListesiGorunumu(
        aylar: veri.aylar,
        seciliIndex: 5,
        onAySec: (_) {},
        antrenorler: veri.antrenorler,
        onAntrenorTap: (_) {},
      );
    });

    // Ders kartları gerçekte kaydırılabilir bir listede duruyor; çıplak
    // Scaffold'a konunca uzun kart ekran boyunu aştığı için dikey taşma
    // veriyor — bu gerçekte oluşmayan bir durum. Kaydırıcıyla sarılınca test
    // yine kartın kendi içindeki yatay/dikey taşmaları yakalar.
    Widget kaydirilabilir(Widget w) => SingleChildScrollView(child: w);

    tasmaTesti(
      'HakedisDersKarti (kalabalık grup)',
      () => HakedisDersKarti(ders: _hakedisDers()),
      sar: kaydirilabilir,
    );

    tasmaTesti(
      'HakedisDersKarti (yapılmadı, hakediş verildi)',
      () => HakedisDersKarti(ders: _hakedisDersYapilmadi()),
      sar: kaydirilabilir,
    );

    tasmaTesti(
      'HakedisDersKarti (iptal edilmiş ders)',
      () => HakedisDersKarti(ders: _hakedisDersIptal()),
      sar: kaydirilabilir,
    );

    tasmaTesti(
      'HakedisDersKarti (hakediş dışı, yönetici almaz dedi)',
      () => HakedisDersKarti(ders: _hakedisDersAlmaz()),
      sar: kaydirilabilir,
    );
  });

  /* ================= ORTAK — LİSTE VE İSKELET BİLEŞENLERİ ================= */

  group('Ortak liste bileşenleri', () {
    tasmaTesti(
      'ListeSatiri (tam dolu)',
      () => ListeSatiri(
        onGorsel: const ListeAvatari(basHarfler: 'EY', ton: ListeTonu.hata),
        baslik: 'Elif Yıldırım Karahanoğulları',
        altBaslik: 'Kırmızı seviye · Standart · 14 yaş',
        rozet: const Icon(Icons.circle, size: 10),
        deger: '-12.850 ₺',
        altDeger: '#10425',
        okGoster: true,
        onTap: () {},
      ),
    );

    tasmaTesti(
      'ListeSatiri (kaydırma eylemli)',
      () => ListeSatiri(
        onGorsel: const ListeAvatari(basHarfler: 'BD'),
        baslik: 'Burak Demir',
        altBaslik: 'Mavi seviye · Pazartesi',
        deger: '-320 ₺',
        onTap: () {},
        eylemler: [
          ListeEylemi(
            etiket: 'Ara',
            ikon: Icons.phone_rounded,
            ton: ListeTonu.basari,
            onSec: () {},
          ),
          ListeEylemi(
            etiket: 'WhatsApp',
            ikon: Icons.chat_rounded,
            ton: ListeTonu.bilgi,
            onSec: () {},
          ),
        ],
      ),
    );

    tasmaTesti(
      'ListeSatiri (yalın)',
      () => const ListeSatiri(baslik: 'Yalnızca başlık'),
    );

    tasmaTesti(
      'ListeGrupBasligi',
      () => const ListeGrupBasligi(baslik: 'Borçlu', sayi: 23),
    );

    tasmaTesti(
      'AntrenorListeItemWidget',
      () => AntrenorListeItemWidget(
        antrenor: _antrenorListeItem(),
        onHakedis: () {},
        onDegerlendirmeler: () {},
      ),
    );

    tasmaTesti(
      'AntrenorListeItemWidget (puansız)',
      () => AntrenorListeItemWidget(
        antrenor: _antrenorListeItem(puanli: false),
        onHakedis: () {},
        onDegerlendirmeler: () {},
      ),
    );
    // Hücredeki sayı en geniş hâlinde: "4.8 (7)" ve "4.8 (1B+)".
    for (final n in [7, 1500]) {
      tasmaTesti(
        'AntrenorListeItemWidget ($n değerlendirme)',
        () => AntrenorListeItemWidget(
          antrenor: _antrenorListeItem(degerlendirme: n),
          onHakedis: () {},
          onDegerlendirmeler: () {},
        ),
      );
    }
  });

  /* ================= YÖNETİCİ — ÜYE LİSTESİ (GÖVDE) ================= */

  // Yapışkan grup başlığı, bildirdiği yüksekliği tam doldurmazsa viewport
  // "SliverGeometry is not valid" atıp sayfayı komple boş bırakıyor. Bu grup
  // o regresyonu yakalar.
  group('Yönetici üye listesi', () {
    tasmaTesti(
      'UyelerGorunumu (harf grupları)',
      () => _uyelerGorunumu(
        istatistik: _uyeIstatistik(),
        uyeler: [
          _uyeListeItem(no: 1, bakiye: -1850),
          _uyeListeItem(no: 2, bakiye: -320),
          _uyeListeItem(no: 3, bakiye: 0),
          _uyeListeItem(no: 4, bakiye: 250, aktif: false),
        ],
      ),
    );

    tasmaTesti(
      'UyelerGorunumu (tek grup)',
      () => _uyelerGorunumu(
        istatistik: _uyeIstatistik(),
        uyeler: [_uyeListeItem(no: 1, bakiye: 0)],
      ),
    );

    // Kartlar hızlı ön ayar; istatistik gelmeden ("–") ve "Yeni" seçiliyken
    // de taşmamalı.
    tasmaTesti(
      'UyelerGorunumu (Yeni ön ayarı, istatistik yok)',
      () => _uyelerGorunumu(
        filtreler: UyeOnAyari.yeni.filtreler(DateTime(2026, 10, 18)),
        siralama: UyeOnAyari.yeni.siralama,
        seciliOnAyar: UyeOnAyari.yeni,
        uyeler: [_uyeListeItem(no: 1, bakiye: 0)],
      ),
    );

    tasmaTesti(
      'UyelerGorunumu (Borçlu ön ayarı, özetli)',
      () => _uyelerGorunumu(
        istatistik: _uyeIstatistik(),
        filtreler: const UyeFiltreleri(borc: BorcDurumFiltresi.borclu),
        siralama: UyeOnAyari.borclu.siralama,
        seciliOnAyar: UyeOnAyari.borclu,
        ozet: const UyeFiltreOzeti(uyeSayisi: 1234, toplamBorc: 2148750),
        uyeler: [
          _uyeListeItem(no: 1, bakiye: -1850),
          _uyeListeItem(no: 2, bakiye: -320),
        ],
      ),
    );

    // Bütün filtreler dolu: çipler alt alta sarmalı, "Tümünü temizle" ve
    // özet sığmalı. Tarihe göre sıralamada ikinci satır tarihi gösterir;
    // pasif + kesin iki rozet yan yana.
    tasmaTesti(
      'UyelerGorunumu (tüm filtreler, son ödeme sırası, iki rozet)',
      () => _uyelerGorunumu(
        istatistik: _uyeIstatistik(),
        filtreler: _tumFiltreler,
        siralama: const UyeSiralama(
            UyeSiralamaAlani.sonOdeme, SiralamaYonu.azalan),
        seciliOnAyar: null,
        ozet: const UyeFiltreOzeti(uyeSayisi: 1234, toplamBorc: 12148750),
        uyeler: [
          _uyeListeItem(no: 1, bakiye: -1850, ek: {
            'aktif_mi': false,
            'borc_kesinlesti': true,
            'son_odeme_tarihi': '2026-09-01',
          }),
          _uyeListeItem(no: 2, bakiye: -320),
        ],
      ),
    );

    tasmaTesti(
      'UyelerGorunumu (tüm filtreler, yükleniyor)',
      () => _uyelerGorunumu(
        uyeler: const [],
        yukleniyor: true,
        filtreler: _tumFiltreler,
        seciliOnAyar: null,
      ),
    );

    tasmaTesti(
      'UyelerGorunumu (filtreye uyan yok)',
      () => _uyelerGorunumu(
        uyeler: const [],
        filtreler: _tumFiltreler,
        seciliOnAyar: null,
        ozet: const UyeFiltreOzeti(uyeSayisi: 0, toplamBorc: 0),
      ),
    );

    // Filtre sayfası tam boy alt sayfa; burada en kalabalık hali (bütün
    // tarih bölümleri "Tarihe göre" açık, aralık hatası görünür).
    tasmaTesti(
      'UyeFiltreSheet (boş)',
      () => UyeFiltreSheet(
        baslangic: UyeFiltreleri.bos,
        sayac: (_) async => 1234,
        bugun: DateTime(2026, 10, 18),
      ),
    );

    tasmaTesti(
      'UyeFiltreSheet (hepsi dolu, aralık hatası)',
      () => UyeFiltreSheet(
        baslangic: _tumFiltreler.copyWith(
          borcMin: 9000,
          borcMax: 100,
          odemeOnce: DateTime(2026, 2, 1),
        ),
        sayac: (_) async => 0,
        bugun: DateTime(2026, 10, 18),
      ),
    );

    tasmaTesti(
      'UyeSiralamaSheet',
      () => const UyeSiralamaSheet(
        secili: UyeSiralama(UyeSiralamaAlani.sonKontrol, SiralamaYonu.azalan),
      ),
    );

    tasmaTesti(
      'UyelerGorunumu (sonraki sayfa yükleniyor)',
      () => _uyelerGorunumu(
        uyeler: [_uyeListeItem(no: 1, bakiye: 0)],
        dahaYukleniyor: true,
      ),
    );

    tasmaTesti(
      'UyelerGorunumu (sonraki sayfa hatası)',
      () => _uyelerGorunumu(
        uyeler: [_uyeListeItem(no: 1, bakiye: 0)],
        dahaHatasi: 'Sunucuya ulaşılamadı, lütfen bağlantını kontrol et.',
      ),
    );

    tasmaTesti(
      'UyelerGorunumu (yükleniyor)',
      () => _uyelerGorunumu(uyeler: const [], yukleniyor: true),
    );

    tasmaTesti(
      'UyelerGorunumu (hata)',
      () => _uyelerGorunumu(
        uyeler: const [],
        hata: 'Sunucuya ulaşılamadı, lütfen bağlantını kontrol et.',
      ),
    );

    tasmaTesti(
      'UyelerGorunumu (arama sonuçsuz)',
      () => _uyelerGorunumu(uyeler: const [], arama: 'zzz'),
    );
  });

  /* ============================ OFİS KABUĞU ============================ */

  group('Ofis üye listesi', () {
    tasmaTesti(
      'OfisUyelerGorunumu (harf grupları, pasif rozetli)',
      () => _ofisUyelerGorunumu(uyeler: [
        _ofisUyeListeItem(no: 1),
        _ofisUyeListeItem(no: 2),
        _ofisUyeListeItem(no: 3, aktif: false),
      ]),
    );

    tasmaTesti(
      'OfisUyelerGorunumu (tek grup)',
      () => _ofisUyelerGorunumu(uyeler: [_ofisUyeListeItem(no: 1)]),
    );

    tasmaTesti(
      'OfisUyelerGorunumu (sonraki sayfa yükleniyor)',
      () => _ofisUyelerGorunumu(
        uyeler: [_ofisUyeListeItem(no: 1)],
        dahaYukleniyor: true,
      ),
    );

    tasmaTesti(
      'OfisUyelerGorunumu (sonraki sayfa hatası)',
      () => _ofisUyelerGorunumu(
        uyeler: [_ofisUyeListeItem(no: 1)],
        dahaHatasi: 'Sunucuya ulaşılamadı, lütfen bağlantını kontrol et.',
      ),
    );

    tasmaTesti(
      'OfisUyelerGorunumu (yükleniyor)',
      () => _ofisUyelerGorunumu(uyeler: const [], yukleniyor: true),
    );

    tasmaTesti(
      'OfisUyelerGorunumu (hata)',
      () => _ofisUyelerGorunumu(
        uyeler: const [],
        hata: 'Sunucuya ulaşılamadı, lütfen bağlantını kontrol et.',
      ),
    );

    tasmaTesti(
      'OfisUyelerGorunumu (arama sonuçsuz)',
      () => _ofisUyelerGorunumu(uyeler: const [], arama: 'zzz'),
    );
  });

  group('Ofis ana sayfa, dersler ve plan dışı', () {
    Widget anaSayfa(
            {OfisBekleyenIsler? veri, bool yukleniyor = false, String? hata}) =>
        OfisAnaSayfaGorunumu(
          ofisAdi: 'Mehmet Yılmazoğulları Kandemir',
          profilDegistir: true,
          veri: veri,
          yukleniyor: yukleniyor,
          hata: hata,
          onMenu: () {},
          onYenile: () async {},
          onYenidenDene: () {},
          onOnay: () {},
          onPlanDisi: () {},
          onTeyit: () {},
          onBugununDersleri: () {},
          onDersKayitTalepleri: () {},
          zil: const SizedBox(width: 42, height: 42),
        );

    tasmaTesti('OfisAnaSayfaGorunumu (dolu)',
        () => anaSayfa(veri: ornekBekleyenIsler()));
    tasmaTesti('OfisAnaSayfaGorunumu (bekleyen yok)',
        () => anaSayfa(veri: ornekBekleyenIsler(bos: true)));
    tasmaTesti(
        'OfisAnaSayfaGorunumu (yükleniyor)', () => anaSayfa(yukleniyor: true));
    tasmaTesti(
        'OfisAnaSayfaGorunumu (hata)',
        () => anaSayfa(
            hata: 'Sunucuya ulaşılamadı, lütfen bağlantını kontrol et.'));

    Widget dersler(
            {bool geri = false, bool yukleniyor = false, bool toplu = false}) =>
        OfisDerslerGorunumu(
          tarih: DateTime(2026, 10, 12),
          gun: yukleniyor ? null : ornekGun(),
          yukleniyor: yukleniyor,
          hata: null,
          suzgec: DersSuzgeci.tumu,
          topluOnayDevam: toplu,
          geriVar: geri,
          onOnceki: () {},
          onSonraki: () {},
          onTarihSec: () {},
          onBugun: () {},
          onSuzgec: (_) {},
          onDersSec: (_) {},
          onTopluOnay: () {},
          onYenile: () async {},
          onYenidenDene: () {},
        );

    tasmaTesti('OfisDerslerGorunumu (dolu gün)', () => dersler());
    tasmaTesti('OfisDerslerGorunumu (geri oklu, toplu onay sürüyor)',
        () => dersler(geri: true, toplu: true));
    tasmaTesti(
        'OfisDerslerGorunumu (yükleniyor)', () => dersler(yukleniyor: true));

    DersYonetimGovdesi govde(int i) => DersYonetimGovdesi(
          ders: ornekGun().dersler[i],
          mesgul: false,
          onYapildi: () {},
          onYapilmadi: () {},
          onKarariKaldir: () {},
          onHakedis: (_, __) {},
          onKatilacak: (_) {},
          onHatirlat: (_) {},
          onPaketDusum: (_) {},
          onPlanDisi: () {},
        );

    tasmaTesti(
        'DersYonetimGovdesi (geçmiş, plan dışı bekliyor)', () => govde(0));
    tasmaTesti('DersYonetimGovdesi (onaylı, yardımcılı)', () => govde(2));
    tasmaTesti('DersYonetimGovdesi (iptal)', () => govde(3));
    tasmaTesti('DersYonetimGovdesi (gelecek, cevapsızlar)', () => govde(4));

    tasmaTesti(
      'OnayBekleyenGunlerGorunumu',
      () => OnayBekleyenGunlerGorunumu(
        veri: ornekBekleyenIsler(),
        yukleniyor: false,
        hata: null,
        onGunSec: (_) {},
        onYenile: () async {},
        onYenidenDene: () {},
      ),
    );
    tasmaTesti(
      'PlanDisiKararlarGorunumu',
      () => PlanDisiKararlarGorunumu(
        dersler: ornekPlanDisi(),
        yukleniyor: false,
        hata: null,
        onKisiSec: (_, __) {},
        onYenile: () async {},
        onYenidenDene: () {},
      ),
    );
    tasmaTesti(
      'PlanDisiKararFormu',
      () => PlanDisiKararFormu(
        ders: ornekPlanDisi().first,
        kisi: ornekPlanDisi().first.kisiler.first,
        secenekler: ornekSecenekler(),
        kaydediliyor: false,
        onKaydet: (_) {},
      ),
    );
  });

  group('Ders değerlendirmeleri', () {
    Widget liste({
      List<DersDegerlendirmesi>? veri,
      bool yukleniyor = false,
      String? hata,
      String filtre = 'tumu',
      String? altBaslik = 'Can Burak ALTINERoğulları',
      bool dahaYukleniyor = false,
    }) =>
        DegerlendirmelerGorunumu(
          baslik: 'Değerlendirmeler',
          altBaslik: altBaslik,
          degerlendirmeler: veri ??
              [
                ornekDegerlendirme(id: 1),
                ornekDegerlendirme(id: 2, puan: 2, yorum: null),
                ornekDegerlendirme(id: 3, puan: 4, digerSayisi: 0),
              ],
          ozet: const DegerlendirmeOzeti(ortalama: 4.57, adet: 1284),
          toplam: 1284,
          yukleniyor: yukleniyor,
          hata: hata,
          dahaYukleniyor: dahaYukleniyor,
          filtre: filtre,
          onFiltre: (_) {},
          onYenile: () async {},
          onYenidenDene: () {},
          onSec: (_) {},
        );

    tasmaTesti('DegerlendirmelerGorunumu (dolu)', () => liste());
    tasmaTesti(
      'DegerlendirmelerGorunumu (alt başlıksız, sonraki sayfa yükleniyor)',
      () => liste(altBaslik: null, dahaYukleniyor: true),
    );
    for (final f in ['tumu', 'yorumlu', 'dusuk']) {
      tasmaTesti('DegerlendirmelerGorunumu (boş, $f)',
          () => liste(veri: const [], filtre: f));
    }
    tasmaTesti('DegerlendirmelerGorunumu (yükleniyor)',
        () => liste(veri: const [], yukleniyor: true));
    tasmaTesti(
      'DegerlendirmelerGorunumu (hata)',
      () => liste(
          veri: const [],
          hata: 'Sunucuya ulaşılamadı, lütfen bağlantını kontrol et.'),
    );
    tasmaTesti(
      'DegerlendirmeDetayi (uzun yorum, yardımcı, iptal, misafir)',
      () => DegerlendirmeDetayi(
        degerlendirme: ornekDegerlendirme(
          yorum: 'Çok verimli geçti. ' * 12,
          yardimci: true,
          iptal: true,
          digerSayisi: 6,
        ),
      ),
    );
    tasmaTesti(
      'DegerlendirmeDetayi (yorumsuz, tek kişilik)',
      () => DegerlendirmeDetayi(
        degerlendirme: ornekDegerlendirme(yorum: null, digerSayisi: 0),
      ),
    );
    tasmaTesti(
      'PuanRozeti (sayılı, puansız, tam sayı)',
      () => const Column(
        children: [
          PuanRozeti(puan: 4.567, sayi: 1500),
          PuanRozeti(puan: 4.567, sayi: 0),
          PuanRozeti(puan: null),
          PuanRozeti(puan: 5, tamSayi: true),
          YildizSirasi(puan: 3, boyut: 22),
        ],
      ),
    );
  });

  group('Ofis kabuk bileşenleri', () {
    for (var i = 0; i < 4; i++) {
      tasmaTesti('OfisBottomBar (sekme $i)',
          () => OfisBottomBar(selectedIndex: i, onTabSelected: (_) {}));
    }

    tasmaTesti(
      'OfisDrawer',
      () => OfisDrawer(
        ofisAdi: 'Mehmet Yılmazoğulları',
        onTabSelected: (_) {},
      ),
    );
  });

  group('QR doğrulama sonucu', () {
    Widget sonuc(QrSonucu s) => QrSonucGorunumu(
          sonuc: s,
          onYenidenTara: () {},
          onBitir: () {},
        );

    tasmaTesti(
      'QrSonucGorunumu (başarılı, uzun ad)',
      () => sonuc(QrSonucu(
        tip: QrSonucTipi.basarili,
        mesaj: 'Hoşgeldiniz, Abdurrahman Çelebioğulları Karahisarlıoğlu',
        zaman: DateTime(2026, 7, 23, 14, 32),
      )),
    );

    tasmaTesti(
      'QrSonucGorunumu (süresi dolmuş)',
      () => sonuc(QrSonucu.hatadan(
        ApiException('QR_EXPIRED', 'QR kodun süresi dolmuş'),
        zaman: DateTime(2026, 7, 23, 14, 32),
      )),
    );

    tasmaTesti(
      'QrSonucGorunumu (bulunamadı)',
      () => sonuc(QrSonucu.hatadan(
        ApiException('QR_NOT_FOUND', 'QR kod bulunamadı'),
        zaman: DateTime(2026, 7, 23, 14, 32),
      )),
    );

    tasmaTesti(
      'QrSonucGorunumu (genel hata)',
      () => sonuc(QrSonucu.hatadan(
        ApiException('TIMEOUT', 'Sunucuya şu an ulaşılamıyor.'),
        zaman: DateTime(2026, 7, 23, 14, 32),
      )),
    );
  });

  group('İskelet bileşenleri', () {
    tasmaTesti('IskeletListe', () => const IskeletListe());
    // `kaydirilabilir: false` varyantı kendi yüksekliğini dayatıyor: sabit
    // yükseklikli bir kutuya konunca taşıyordu (ders onay dialoğu, 6 px).
    for (final n in [1, 2, 3, 5]) {
      tasmaTesti('IskeletListe (sarmalayıcısız, $n satır)',
          () => IskeletListe(satirSayisi: n, kaydirilabilir: false));
    }
    tasmaTesti('DersOnayYukleniyor', () => const DersOnayYukleniyor());
    tasmaTesti('IskeletKart', () => const IskeletKart());
    tasmaTesti('IskeletTakvim', () => const IskeletTakvim());
    tasmaTesti('IskeletDashboard', () => const IskeletDashboard());
  });

  /* ===================== YÖNETİCİ — MEVCUT BİLEŞENLER ===================== */

  group('Yönetici mevcut bileşenler', () {
    tasmaTesti('DersListeItemWidget',
        () => DersListeItemWidget(ders: _dersListeItem(), onTap: () {}));

    tasmaTesti(
        'DersListeItemWidget (Yapılmadı)',
        () => DersListeItemWidget(
            ders: _dersListeItem(
                durum: 'onay_bekliyor', onayDurumu: 'reddedildi'),
            onTap: () {}));

    tasmaTesti('DailySummaryCard', () {
      return DailySummaryCard(
        data: GununOzeti(yeniKayit: 12, telafiDers: 41, dolulukYuzdesi: 38.4),
        bugunkuDers: 148,
      );
    });

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

    // Sabit en-boy oranıyla (1.1) 360 dp'de gerçek fontla taşıyordu; yükseklik
    // artık içerikten.
    DashboardData buyukPano() => DashboardData.fromJson({
          'ciro': {
            'toplam_ciro': '12345678',
            'ders_sayisi': 1842,
            'degisim_yuzdesi': -12.5,
          },
          'tahsilat': {
            'toplam_tahsilat': '9876543',
            'islem_sayisi': 1204,
            'degisim_yuzdesi': 34.2,
          },
          'ders': {
            'toplam_ders': 1880,
            'tamamlanan_ders': 1842,
            'iptal_edilen_ders': 118,
            'doluluk_yuzdesi': 87.4,
            'onceki_donem_iptal': 1234,
          },
          'uye': {'aktif_uye_sayisi': 1234, 'degisim_yuzdesi': 4.1},
          'toplam_alacak': {'toplam_borc': '4567890', 'borclu_uye_sayisi': 321},
        });
    Widget kaydirmali(Widget w) => SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: w));

    // Sabit en-boy oranıyla (1.1) 360 dp'de gerçek fontla taşıyordu; yükseklik
    // artık içerikten. Pano iki grupta çizilir: dönem kartları ve "şu an".
    for (final grup in PanoKartGrubu.values) {
      tasmaTesti(
        'StatCardsGrid ${grup.name} (büyük tutarlar, uzun başlıklar)',
        () => StatCardsGrid(
          data: buyukPano(),
          grup: grup,
          onToplamAlacakTap: () {},
        ),
        sar: kaydirmali,
      );
    }

    // Seçici + tarih aralığı + 2×2 kart tek çerçevede; dönem değişirken
    // aynı yükseklikte iskelet.
    for (final yukleniyor in [false, true]) {
      tasmaTesti(
        'DonemKutusu (${yukleniyor ? 'yükleniyor' : 'dolu'})',
        () => DonemKutusu(
          seciliDonem: DonemFiltresi.buHafta,
          onDonemChanged: (_) {},
          yukleniyor: yukleniyor,
          child: StatCardsGrid(data: buyukPano(), grup: PanoKartGrubu.donem),
        ),
        sar: kaydirmali,
      );
    }
    // Raporlar "Bu Ay": 31 günlük ciro/tahsilat, çok kort ve antrenör —
    // listeler kendi kartında kayar, sayfayı uzatmaz. İki grup da dönem
    // çerçevesinde (kenar boşluğu bölümleri 24 px daraltır).
    RaporlarData ayRaporu() => RaporlarData.fromJson({
          'ozet_kartlar': [
            for (final b in ['Toplam Ciro', 'Toplam Tahsilat', 'Toplam Ders'])
              {
                'baslik': b,
                'deger': '₺12.345.678',
                'alt_baslik': '1842 ders',
                'ikon': 'event',
                'renk': '#FF9800'
              },
          ],
          'ciro_raporu': [
            for (var g = 1; g <= 31; g++)
              {
                'tarih': '2026-10-${g.toString().padLeft(2, '0')}',
                'ciro': '1234567',
                'ders_sayisi': 118
              },
          ],
          'tahsilat_raporu': [
            for (var g = 1; g <= 31; g++)
              {
                'tarih': '2026-10-${g.toString().padLeft(2, '0')}',
                'tahsilat': '987654',
                'islem_sayisi': 64
              },
          ],
          'doluluk_raporu': [
            for (var k = 1; k <= 9; k++)
              {
                'kort_adi': 'Tekli Kapalı Kort $k',
                'kort_id': k,
                'toplam_saat': 420,
                'dolu_saat': 388,
                'doluluk_yuzdesi': 92.4
              },
          ],
          'antrenor_performans': [
            for (var a = 1; a <= 12; a++)
              {
                'antrenor_id': a,
                'antrenor_adi': 'Ayşe Yılmaz Öğretmenoğulları',
                'toplam_ders': 188,
                'tamamlanan_ders': 174,
                'iptal_ders': 14,
                'ortalama_puan': 4.8
              },
          ],
        });
    DolulukHaritasi ayHaritasi() => DolulukHaritasi.fromJson({
          'donem': 'bu_ay',
          'gunler': ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'],
          'saatler': [for (var h = 7; h <= 22; h++) h],
          'hucreler': [
            for (var h = 7; h <= 22; h++)
              {
                'saat': h,
                'degerler': [12, 9, 14, 8, 11, 15, 6]
              },
          ],
          'max_sayi': 15,
          'toplam_ders': 1880,
        });
    for (final yukleniyor in [false, true]) {
      tasmaTesti(
        'Raporlar ciro ve tahsilat grubu (Bu Ay${yukleniyor ? ', yükleniyor' : ''})',
        () => RaporDonemGrubu(
          donem: DonemFiltresi.buAy,
          onDonemChanged: (_) {},
          yukleniyor: yukleniyor,
          data: ayRaporu(),
        ),
        sar: kaydirmali,
      );
      tasmaTesti(
        'Raporlar kort ve antrenör grubu (Bu Ay${yukleniyor ? ', yükleniyor' : ''})',
        () => RaporKortAntrenorGrubu(
          donem: DonemFiltresi.buAy,
          onDonemChanged: (_) {},
          yukleniyor: yukleniyor,
          data: ayRaporu(),
        ),
        sar: kaydirmali,
      );
    }
    // Ay dönen hafta: etiketin en uzun hâli ("29 Eyl – 5 Eki").
    tasmaTesti(
      'Raporlar haftalık yoğunluk (ısı haritası)',
      () => RaporHaftalikYogunluk(
        data: ayHaritasi(),
        bugun: DateTime(2026, 10, 1),
      ),
      sar: kaydirmali,
    );
    tasmaTesti(
      'Raporlar haftalık yoğunluk (ders yok)',
      () => RaporHaftalikYogunluk(
        data: DolulukHaritasi.fromJson(const {
          'gunler': ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'],
          'saatler': [],
          'hucreler': [],
          'max_sayi': 0,
          'toplam_ders': 0,
        }),
        bugun: DateTime(2026, 10, 16),
      ),
    );

    tasmaTesti(
      'PanoBolumEtiketi',
      () => const PanoBolumEtiketi(
          ikon: Icons.bar_chart_rounded, etiket: 'Bu haftanın günleri'),
    );

    // Alt bar 6 sekmelik NavigationBar iken "Antrenörler" etiketi alt satıra
    // taşıyordu; üye barıyla aynı 4 sekme + merkez QR düzenine geçildi.
    for (var i = 0; i < 4; i++) {
      tasmaTesti('YoneticiBottomBar (sekme $i)', () {
        return YoneticiBottomBar(selectedIndex: i, onTabSelected: (_) {});
      });
    }

    tasmaTesti('YoneticiDrawer', () {
      return YoneticiDrawer(
        yoneticiAdi: 'Mehmet Yılmazoğulları',
        onTabSelected: (_) {},
        onBorcluUyeler: () {},
      );
    });
  });

  /* ===================== ANTRENÖR ===================== */

  group('Antrenör takvimi', () {
    tasmaTesti('HaftaGunSecici', () {
      return HaftaGunSecici(
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
      () => antrenor_blok.LessonBlock(
          ders: _etkinlik(katilimci: 6), onTap: () {}),
      sar: (w) => Center(child: SizedBox(width: 300, height: 90, child: w)),
    );

    tasmaTesti(
      'LessonBlock (iptal, dar)',
      () =>
          antrenor_blok.LessonBlock(ders: _etkinlik(iptal: true), onTap: () {}),
      sar: (w) => Center(child: SizedBox(width: 140, height: 60, child: w)),
    );

    tasmaTesti('EksikYoklamaListesi', () {
      return EksikYoklamaListesi(
        dersler: [_etkinlik(katilimci: 6), _etkinlik(katilimci: 1)],
        onDersTap: (_) {},
      );
    });

    // Aynı saatte 3 ders olunca kart 3 kolona bölünür; en dar kart durum
    // rozetini sıkıştırıp taşıyordu (bkz. LessonBlock üst satırı).
    tasmaTesti('TimelineView (3 çakışan ders)', () {
      return TakvimZamanCizelgesi(
        blokYapici: (ders, onTap) =>
            antrenor_blok.LessonBlock(ders: ders, onTap: onTap),
        dersler: [
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T15:30:00+03:00'),
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T16:30:00+03:00'),
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T16:30:00+03:00'),
        ],
        selectedDay: DateTime(2026, 7, 23),
        onLessonTap: (_) {},
      );
    });

    // Kısa dersler kartı alçaltıp kompakt moda düşürür (ayrı düzen).
    tasmaTesti('TimelineView (3 çakışan kısa ders)', () {
      return TakvimZamanCizelgesi(
        blokYapici: (ders, onTap) =>
            antrenor_blok.LessonBlock(ders: ders, onTap: onTap),
        dersler: [
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T14:50:00+03:00'),
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T15:05:00+03:00'),
          _etkinlik(
              bas: '2026-07-23T14:35:00+03:00',
              bit: '2026-07-23T15:10:00+03:00'),
        ],
        selectedDay: DateTime(2026, 7, 23),
        onLessonTap: (_) {},
      );
    });

    // Misafir ekleme formu: iki metin alanı + iki buton. Uzun etiketler büyük
    // yazı ölçeğinde buton satırını taşırabilir.
    tasmaTesti('MisafirEkleSheet (yeni kayıt)', () => const MisafirEkleSheet());

    tasmaTesti(
      'MisafirEkleSheet (düzenleme, uzun not)',
      () => const MisafirEkleSheet(
        mevcut: MisafirModel(
          id: 12,
          adSoyad: 'Mehmet Kaya',
          notMetni:
              'Ayşe Demir’in arkadaşı, telefon 0532 000 00 00, ilk kez geldi',
        ),
      ),
    );

    // Yoklamanın açılış ekranı: üç kartın da başlık + açıklaması uzun, büyük
    // yazı ölçeğinde satırlar sarmalı. Dikeyde alt sayfadaki gibi kaydırma var
    // (küçük ekran + 1.3 ölçekte üç kart sığmıyor); aranan taşma, kart
    // içindeki ikon + metin + ok satırının yatayda taşması.
    tasmaTesti(
      'YoklamaHizliSecim',
      () => YoklamaHizliSecim(
        katilimcilar: const [
          'Ayşe Yılmaz',
          'Mehmet Şahinoğlu',
          'Zeynep Karaca',
          'Abdülkadir Küçükdağdelen',
        ],
        onHepsiGeldi: () {},
        onEksikFazla: () {},
        onYapilmadi: () {},
      ),
      sar: (w) => SingleChildScrollView(child: w),
    );

    tasmaTesti(
      'YoklamaHizliSecim (kaydediliyor, planlı yok)',
      () => YoklamaHizliSecim(
        katilimcilar: const [],
        kaydediliyor: true,
        onHepsiGeldi: () {},
        onEksikFazla: () {},
        onYapilmadi: () {},
      ),
      sar: (w) => SingleChildScrollView(child: w),
    );
  });

  /* ===================== ANTRENÖR — ANA SAYFA KABUĞU ===================== */

  group('Antrenör ana sayfa', () {
    tasmaTesti(
      'KabukAltBar (antrenör sekmeleri)',
      () => KabukAltBar(
        aktifIndeks: 1,
        onSekme: (_) {},
        onMerkez: () {},
        sekmeler: const [
          KabukSekmesi(
              ikon: Icons.home_outlined,
              seciliIkon: Icons.home_rounded,
              etiket: 'Ana Sayfa'),
          KabukSekmesi(
              ikon: Icons.calendar_month_outlined,
              seciliIkon: Icons.calendar_month_rounded,
              etiket: 'Takvim'),
          KabukSekmesi(
              ikon: Icons.groups_outlined,
              seciliIkon: Icons.groups_rounded,
              etiket: 'Öğrenciler'),
          KabukSekmesi(
              ikon: Icons.person_outline_rounded,
              seciliIkon: Icons.person_rounded,
              etiket: 'Bilgilerim'),
        ],
      ),
    );

    tasmaTesti('AntrenorDrawer',
        () => const AntrenorDrawer(antrenorAdi: 'Ayşe Yılmazoğulları'));

    // Header'lar üç aksiyon butonu + uzun ad taşıyor; profil değiştirme
    // butonu eklenip çıkarıldığında taşma riski buradaydı, kapsama alındı.
    // Sayfadaki gibi takım renginde başlık bandının içinde.
    tasmaTesti(
      'HomeHeader (çok profilli)',
      () => BaslikBandi(
        ustGuvenliAlan: false,
        padding: const EdgeInsets.only(bottom: 8),
        child: HomeHeader(
          antrenorAdi: 'Ayşe Yılmazoğulları Kandemir',
          hasMultipleProfiles: true,
          onMenuTap: () {},
        ),
      ),
    );

    // Yardım sayfası API çağırmadığı için doğrudan render edilebiliyor.
    // Kapsanan: başlık satırı, üst kart, bölüm başlıkları ve ekranda görünen
    // soru kartları — hepsi uzun Türkçe metinle dolu Row'lar taşıyor.
    tasmaTesti('AntrenorYardimPage', () => const AntrenorYardimPage());
    tasmaTesti('YardimPage (üye)', () => const YardimPage());
    tasmaTesti('YonetimYardimPage (yönetici)',
        () => const YonetimYardimPage(ofis: false));
    tasmaTesti(
        'YonetimYardimPage (ofis)', () => const YonetimYardimPage(ofis: true));
  });

  group('Zorunlu güncelleme sayfaları', () {
    // Zorunlu güncelleme / bakım sayfaları: sunucudan gelen başlık ve mesaj
    // uzunluğu bilinmiyor, dar ekran + büyük yazıda taşmamalılar.
    tasmaTesti(
      'BloklayanSayfa',
      () => BloklayanSayfa(
        title: 'Bu sürüm artık desteklenmiyor, lütfen güncelleyin',
        message:
            'Uygulamanın kullandığınız sürümü yeni kurallarla uyumlu değil.'
            ' Devam etmek için mağazadan son sürümü yükleyin; verileriniz korunur.',
        actionText: 'Güncelle',
        onAction: () async {},
      ),
    );
    tasmaTesti(
      'ZorunluGuncellemeSayfasi',
      () => const ZorunluGuncellemeSayfasi(
        appStoreUrl: 'https://apps.apple.com/app/id1',
        storeVersion: '3.10.12',
        currentVersion: '3.8.1',
        title: 'Güncelleme gerekli — yeni sürüm yayında',
        message:
            'Devam etmek için uygulamanın son sürümünü yüklemeniz gerekiyor.'
            ' Güncelleme birkaç dakika sürer, verileriniz korunur.',
      ),
    );
  });

  /* ===================== ÜYE ===================== */

  group('Üye ekranları', () {
    tasmaTesti(
      'LessonBlock',
      () => uye_blok.LessonBlock(ders: _etkinlik(katilimci: 6), onTap: () {}),
      sar: (w) => Center(child: SizedBox(width: 300, height: 90, child: w)),
    );

    // Antrenör takvimiyle aynı senaryo: çakışan dersler kartı daraltır.
    tasmaTesti('TimelineView (3 çakışan ders)', () {
      return TakvimZamanCizelgesi(
        blokYapici: (ders, onTap) =>
            uye_blok.LessonBlock(ders: ders, onTap: onTap),
        dersler: [
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T15:30:00+03:00'),
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T16:30:00+03:00'),
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T16:30:00+03:00'),
        ],
        selectedDay: DateTime(2026, 7, 23),
        onLessonTap: (_) {},
      );
    });

    tasmaTesti('TimelineView (3 çakışan kısa ders)', () {
      return TakvimZamanCizelgesi(
        blokYapici: (ders, onTap) =>
            uye_blok.LessonBlock(ders: ders, onTap: onTap),
        dersler: [
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T14:50:00+03:00'),
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T15:05:00+03:00'),
          _etkinlik(
              bas: '2026-07-23T14:35:00+03:00',
              bit: '2026-07-23T15:10:00+03:00'),
        ],
        selectedDay: DateTime(2026, 7, 23),
        onLessonTap: (_) {},
      );
    });

    tasmaTesti('TakvimAjanda (dolu hafta)', () {
      return TakvimAjanda(
        dersler: [
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T15:30:00+03:00',
              katilimci: 4),
          _etkinlik(
              bas: '2026-07-24T09:00:00+03:00',
              bit: '2026-07-24T10:00:00+03:00'),
        ],
        onLessonTap: (_) {},
        durumEtiketi: (_) => 'Onay bekliyor',
      );
    });

    // Antrenörün ajandasında alt satır katılımcı isimleri: uzun isim listesi
    // tek satıra sığmalı (kesilerek).
    tasmaTesti('TakvimAjanda (katılımcı adlı alt satır)', () {
      return TakvimAjanda(
        dersler: [
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T15:30:00+03:00',
              katilimci: 4),
        ],
        onLessonTap: (_) {},
        altSatir: (ders) => ders.uyeList.map((u) => u.adSoyad).join(', '),
      );
    });

    tasmaTesti(
      'TakvimAjanda (boş)',
      () => TakvimAjanda(dersler: const [], onLessonTap: (_) {}),
    );

    // Seçili günde ders yoksa başlık + "ders yok" satırı çizilir.
    tasmaTesti('TakvimAjanda (seçili gün boş)', () {
      return TakvimAjanda(
        dersler: [
          _etkinlik(
              bas: '2026-07-23T14:30:00+03:00',
              bit: '2026-07-23T15:30:00+03:00'),
        ],
        secilenGun: DateTime(2026, 7, 24),
        onLessonTap: (_) {},
        durumEtiketi: (_) => 'Onay bekliyor',
      );
    });

    tasmaTesti('UyeOzetSerit', () {
      return UyeOzetSerit(
        ozet: UyeOzetModel.fromJson(const {
          'bakiye': -12345.67,
          'kalan_paket_hak': 12,
          'aktif_telafi': 2,
        }),
      );
    });

    tasmaTesti(
        'UyeOzetSerit (yükleniyor)', () => const UyeOzetSerit(isLoading: true));

    tasmaTesti('UyeOdulSayaci (sayıyor)',
        () => UyeOdulSayaci(durum: _odul(sayac: 14)));

    tasmaTesti('UyeOdulSayaci (hak edildi)',
        () => UyeOdulSayaci(durum: _odul(sayac: 20), onOdulAl: () async {}));

    tasmaTesti('UyeOdulSayaci (kod hazır)',
        () => UyeOdulSayaci(durum: _odul(kod: true)));

    tasmaTesti('UyeOdulSayaci (yükleniyor)',
        () => const UyeOdulSayaci(isLoading: true));

    tasmaTesti('OdulBilgiSheet (açıklamalı, sayıyor)',
        () => OdulBilgiSheet(durum: _odul(sayac: 7)));

    tasmaTesti(
        'OdulBilgiSheet (açıklamasız, kahve olmayan, kod hazır)',
        () => OdulBilgiSheet(
              durum: OdulDurumModel.fromJson({
                'aktif': true,
                'odul_adi': 'Akademi logolu havlu ve su şişesi seti',
                'ikon': 'havlu',
                'esik': 30,
                'sayac': 30,
                'kalan': 0,
                'hak_edildi': true,
                'bekleyen_odul': const {
                  'kod': 'BK-7F3Q',
                  'durum': 'BEKLIYOR',
                  'son_kullanma_metin': '05.08.2026',
                },
              }),
            ));

    tasmaTesti(
        'UyeNextLessonCard', () => UyeNextLessonCard(nextLesson: _etkinlik()));

    tasmaTesti('UyeNextLessonCard (ders yok)',
        () => const UyeNextLessonCard(nextLesson: null));

    tasmaTesti(
      'KabukAltBar (üye sekmeleri)',
      () => KabukAltBar(
        aktifIndeks: 0,
        onSekme: (_) {},
        onMerkez: () {},
        sekmeler: const [
          KabukSekmesi(
              ikon: Icons.home_outlined,
              seciliIkon: Icons.home_rounded,
              etiket: 'Ana Sayfa'),
          KabukSekmesi(
              ikon: Icons.calendar_month_outlined,
              seciliIkon: Icons.calendar_month_rounded,
              etiket: 'Takvim'),
          KabukSekmesi(
              ikon: Icons.account_balance_wallet_outlined,
              seciliIkon: Icons.account_balance_wallet_rounded,
              etiket: 'Hareketler'),
          KabukSekmesi(
              ikon: Icons.person_outline_rounded,
              seciliIkon: Icons.person_rounded,
              etiket: 'Hesabım'),
        ],
      ),
    );

    // Sayfadaki gibi takım renginde başlık bandının içinde.
    tasmaTesti(
      'UyeHeader (çok profilli)',
      () => BaslikBandi(
        ustGuvenliAlan: false,
        padding: const EdgeInsets.only(bottom: 8),
        child: UyeHeader(
          uyeAdi: 'Mehmet Yılmazoğulları Kandemir',
          hasMultipleProfiles: true,
          onMenuTap: () {},
        ),
      ),
    );

    tasmaTesti(
        'UyeUrunListView', () => UyeUrunListView(urunler: _uyeUrunler()));

    tasmaTesti('GecmisDerslerListesi', () {
      return GecmisDerslerListesi(
        dersler: _gecmisDersler(),
        onDegerlendir: (_) {},
      );
    });

    tasmaTesti('YapilacaklarKartlari', () {
      return InfoCardsCarousel(
        cards: _yapilacakKartlar(),
        title: 'Yapılacaklar',
        onCardTap: (_) {},
      );
    });

    tasmaTesti('TeyitBekleyenListesi', () {
      return TeyitBekleyenListesi(
        dersler: _teyitBekleyenler(),
        onTap: (_) {},
      );
    });
  });

  /* ======================= GİRİŞ ÖNCESİ EKRANLAR ======================= */

  group('Kayıt ve şifre sıfırlama', () {
    // Sihirbazın ilk adımı: uzun kulüp adı + 1.3x yazıda açılır liste ve
    // ilerleme başlığı taşmamalı.
    tasmaTesti(
      'KayitSihirbazi (ilk adım)',
      () => KayitSihirbazi(
        secenekler: _kayitSecenekleri(),
        onGonder: (_) async {},
      ),
      sar: (w) => SingleChildScrollView(child: w),
    );

    tasmaTesti(
      'KayitSihirbazi (gönderiliyor)',
      () => KayitSihirbazi(
        secenekler: _kayitSecenekleri(),
        gonderiliyor: true,
        onGonder: (_) async {},
      ),
      sar: (w) => SingleChildScrollView(child: w),
    );

    tasmaTesti(
      'HesapSecimListesi (iki hesap)',
      () => HesapSecimListesi(
        hesaplar: const [
          SifirlamaHesabi(
            userId: 1,
            maskeliAd: 'Me**** Ka*********',
            maskeliEposta: 'me***@example.com',
            epostaVarMi: true,
          ),
          SifirlamaHesabi(
            userId: 2,
            maskeliAd: 'El** Ka*********',
            maskeliEposta: '',
            epostaVarMi: false,
          ),
        ],
        onSec: (_) {},
        onVazgec: () {},
      ),
      sar: (w) => SingleChildScrollView(child: w),
    );
  });

  group('QR sayfaları', () {
    // Metin iki durumda da farklı uzunlukta; ikisi de test edilir.
    tasmaTesti('ParlaklikIpucu (otomatik artırıldı)',
        () => ParlaklikIpucu(maksimumda: ValueNotifier<bool>(true)));

    tasmaTesti('ParlaklikIpucu (manuel yönerge)',
        () => ParlaklikIpucu(maksimumda: ValueNotifier<bool>(false)));

    // 260 px'lik kod dar ekranda yatay boşluğu taşırmamalı.
    tasmaTesti(
      'QrKodGorseli',
      () => const QrKodGorseli(kod: 'BINAY-TEST-0001', boyut: 260),
      sar: (w) => SingleChildScrollView(child: w),
    );
  });

  group('Bildirimler', () {
    tasmaTesti(
      'PlanDisiBildirimOzeti (ekleme)',
      () => PlanDisiBildirimOzeti(displayData: _planDisiVeri()),
    );

    tasmaTesti(
      'PlanDisiBildirimOzeti (ekleme + çıkarma)',
      () => PlanDisiBildirimOzeti(
        displayData: _planDisiVeri(
          cikarilanlar: 'Deniz Ayşegül Arslanoğulları (üye)',
        ),
      ),
    );

    tasmaTesti(
      'BildirimDetaySheet (plan dışı)',
      () => BildirimDetaySheetWidget(
        notification: _planDisiBildirimi(),
      ),
    );

    tasmaTesti(
      'BildirimDetaySheet (düz bildirim)',
      () => BildirimDetaySheetWidget(
        notification: _duzBildirim(),
      ),
    );

    // Ders teyit sayfasının tüm bitiş durumları bu widget'a düşüyor; en uzun
    // metin "Bildirim Süresi Doldu" hâli, dar ekran + 1.3x'te sınırı o zorluyor.
    tasmaTesti(
      'BildirimDurumGorunumu (süresi dolmuş bildirim)',
      () => BildirimDurumGorunumWidget(
        icon: Icons.timer_off_rounded,
        color: FitcallRenkleri.acik.uyari,
        title: 'Bildirim Süresi Doldu',
        subtitle: 'Bu bildirim üç günden eski. Uygulamaya giriş yapıp '
            'takviminizden katılım bildirebilirsiniz.',
        onClose: () {},
      ),
    );

    tasmaTesti(
      'BildirimDurumGorunumu (teyit verilmiş + ipucu)',
      () => BildirimDurumGorunumWidget(
        icon: Icons.check_circle_rounded,
        color: FitcallRenkleri.acik.basari,
        title: 'Katılacaksınız',
        subtitle: 'Bu ders için daha önce cevap verdiniz.',
        showChangeHint: true,
        onClose: () {},
      ),
    );
  });

  group('Yönetici/ofis duyurular', () {
    // Uzun başlık + uzun alt satır + üç grup; ölçülmeyen ve planlı satırlar.
    tasmaTesti('DuyuruYonetimListesi', () {
      DuyuruYonetimSatiri satir(int id, String durum,
              {int? goren, int? hedef, String kitle = 'herkes'}) =>
          DuyuruYonetimSatiri.fromJson({
            'id': id,
            'baslik': 'Eylül 2026 ücret artışı bilgilendirmesi ve yeni dönem '
                'kayıt takvimi',
            'hedef_kitle': kitle,
            'durum': durum,
            'onemli_mi': id.isOdd,
            'popup_goster': true,
            'aktif_mi': durum != 'gecmis',
            'yayin_baslangic': '2026-09-28T09:00:00+03:00',
            'yayin_bitis': '2026-10-17T23:59:00+03:00',
            'goren_sayisi': goren,
            'hedef_sayisi': hedef,
          });
      return DuyuruYonetimListesi(
        duyurular: [
          satir(1, 'yayinda', goren: 1027, hedef: 1027),
          satir(2, 'yayinda', goren: 1, hedef: 1027),
          satir(3, 'planli', goren: 0, hedef: 1027),
          satir(4, 'gecmis', kitle: 'antrenorler'),
        ],
        onSec: (_) {},
        onYenile: () async {},
      );
    });

    tasmaTesti(
      'OkumaDurumuGorunumu (gördü)',
      () => OkumaDurumuGorunumu(
        veri: DuyuruOkumaDurumu.fromJson(okumaDurumuJson()),
        onIcerikGor: () {},
        onYenile: () async {},
        onHesapSec: (_) {},
      ),
    );

    tasmaTesti(
      'OkumaDurumuGorunumu (ölçülmüyor)',
      () => OkumaDurumuGorunumu(
        veri: DuyuruOkumaDurumu.fromJson(okumaDurumuJson(olculuyor: false)),
        onIcerikGor: () {},
        onYenile: () async {},
      ),
    );

    tasmaTesti(
      'OkumaDurumuGorunumu (planlı)',
      () => OkumaDurumuGorunumu(
        veri: DuyuruOkumaDurumu.fromJson(okumaDurumuJson(durum: 'planli')),
        onIcerikGor: () {},
        onYenile: () async {},
      ),
    );
  });

  group("Açılış popup'ları", () {
    // Uzun ad iki satıra iner; içerik küçük ekranda FittedBox ile küçülür.
    tasmaTesti(
      'DogumGunuPopup (uzun ad + imza)',
      () => DogumGunuPopup(
        ad: 'Ayşegül Defne Nur',
        imza: 'Binay Akademi',
        onKapat: () {},
      ),
    );

    tasmaTesti(
      'DuyuruPopup (görselsiz, uzun başlık/özet, detaylı)',
      () => DuyuruPopup(
        duyuru: _popupDuyurusu(
          baslik: 'Kış kampı kayıtları açıldı: 22 Aralık – 5 Ocak arası '
              'yoğunlaştırılmış program',
          altBaslik: '7-14 yaş grubu için günde iki seans antrenman, kondisyon '
              've maç pratiği. Kontenjan sınırlı; kayıtlar ofisten ve '
              'uygulamadan alınır, erken kayıtta indirim uygulanır.',
        ),
        onKapat: () {},
        onDetay: () {},
      ),
    );

    // id 0: sayfa açılışta "okundu" isteği atmaz (testte ağ yok).
    tasmaTesti(
      'DuyuruDetaySheet (görselsiz, önemli, hedef kitleli)',
      () => DuyuruDetaySheet(
        duyuru: DuyuruModel.fromMap({
          'id': 0,
          'baslik': 'Kış kampı kayıtları açıldı: 22 Aralık – 5 Ocak arası '
              'yoğunlaştırılmış program',
          'alt_baslik': '7-14 yaş grubu, kontenjan sınırlı',
          'icerik': 'Günde iki seans antrenman, kondisyon ve maç pratiği.\n\n'
              'Kayıtlar ofisten alınır.',
          'onemli_mi': true,
          'hedef_kitle': 'uyeler',
          'hedef_kitle_display': 'Sadece Üyeler',
          'yayin_baslangic': '2026-10-01T09:00:00+03:00',
        }),
      ),
    );

    // Ana sayfa şeridi: görsel üstte, başlık altta. Görselsiz (poster),
    // önemli ve çok resimli rozetlerle en kalabalık hâl.
    tasmaTesti(
      'DuyuruCarousel (önemli, çok resimli, uzun başlık)',
      () => DuyuruCarousel(
        height: 210,
        duyurular: [
          DuyuruModel.fromMap({
            'id': 1,
            'baslik': 'Kış kampı kayıtları açıldı: 22 Aralık – 5 Ocak arası '
                'yoğunlaştırılmış program',
            'alt_baslik': '7-14 yaş grubu, kontenjan sınırlı, erken kayıtta '
                'indirim',
            'onemli_mi': true,
            'resim_sayisi': 4,
            'yayin_baslangic': '2026-10-01T09:00:00+03:00',
          }),
          _popupDuyurusu(baslik: 'Tesis Pazartesi kapalı'),
        ],
      ),
    );

    tasmaTesti(
      'DuyuruPopup (kısa, yalnız Tamam)',
      () => DuyuruPopup(
        duyuru: _popupDuyurusu(baslik: 'Tesis Pazartesi kapalı'),
        onKapat: () {},
      ),
    );

    // Sürüm notu popup'ı: tek madde (ilk madde açık gelir, liste kısa).
    tasmaTesti(
      'SurumNotuGovdesi (tek madde)',
      () => SurumNotuGovdesi(
        blok: _surumNotu(maddeSayisi: 1),
        onKapat: () {},
      ),
    );

    // Sınırdaki hâl: 4 madde + uzun açıklama + uzun yol metni.
    tasmaTesti(
      'SurumNotuGovdesi (4 madde, uzun metin)',
      () => SurumNotuGovdesi(
        blok: _surumNotu(maddeSayisi: 4, uzun: true),
        onKapat: () {},
      ),
    );

    // Sınır aşıldı: "Tümünü gör" butonu da çizilir, popup 4 madde gösterir.
    tasmaTesti(
      'SurumNotuGovdesi (7 madde, Tümünü gör)',
      () => SurumNotuGovdesi(
        blok: _surumNotu(maddeSayisi: 7),
        onKapat: () {},
        onTumunuGor: () {},
      ),
    );

    // Alt başlık ve yol yok (yalnız hata düzeltmesi maddesi), rozet de yok.
    tasmaTesti(
      'SurumNotuGovdesi (yolsuz madde, sürümsüz)',
      () => SurumNotuGovdesi(
        blok: SurumNotuBlogu.fromJson(const {
          'id': 3,
          'surum': '',
          'baslik': 'Neler yeni?',
          'maddeler': [
            {
              'id': 1,
              'baslik': 'Hata düzeltmeleri',
              'aciklama': 'Giriş ve ödeme ekranlarındaki hatalar düzeltildi.',
              'yol': '',
              'sira': 1,
            }
          ],
        }),
        onKapat: () {},
      ),
    );

    // Arşiv sayfası: API'ye çıkmadan, iki sürümlük liste.
    tasmaTesti(
      'NelerYeniPage (iki sürüm)',
      () => NelerYeniPage(
        surum: '3.12.0',
        yukleyici: (_) async => [
          _surumNotu(maddeSayisi: 3, uzun: true),
          SurumNotuBlogu.fromJson(const {
            'id': 9,
            'surum': '3.11.0',
            'baslik': 'Neler yeni?',
            'maddeler': [
              {
                'id': 90,
                'baslik': 'Profil fotoğrafı',
                'aciklama': 'Fotoğrafınıza dokunup kameradan çekebilirsiniz.',
                'yol': 'Hesabım › fotoğrafa dokun',
                'ikon': 'photo_camera_rounded',
                'sira': 1,
              }
            ],
          }),
        ],
      ),
    );

    tasmaTesti(
      'NelerYeniPage (boş)',
      () => NelerYeniPage(surum: '3.12.0', yukleyici: (_) async => const []),
    );
  });

  /* ===================== ÜYE — HAVALE / DEKONT ===================== */

  group('Havale / dekont', () {
    // Ağ görseli widget testinde yüklenemez: karekod yerine düz kutu.
    Widget karekod(BuildContext c, String url) => const SizedBox.expand();

    BankaHesabiModel hesap({bool karekodlu = true, bool uzun = false}) =>
        BankaHesabiModel(
          id: 1,
          etiket: uzun ? 'Şirket hesabı (fatura kesilen, KDV dahil)' : 'Şirket hesabı',
          bankaAdi: uzun ? 'Türkiye Cumhuriyeti Ziraat Bankası A.Ş.' : 'Örnek Bank',
          aliciAdi: uzun
              ? 'Binay Spor Eğitim Danışmanlık Sanayi ve Ticaret Limited Şirketi'
              : 'Binay Spor',
          iban: 'TR330006100519786457841326',
          ibanGruplu: 'TR33 0006 1005 1978 6457 8413 26',
          karekodUrl: karekodlu ? 'https://ornek/kare.png' : null,
        );

    DekontModel dekont(String durum,
            {String? beyan,
            String red = '',
            bool yeniden = false,
            List<String> uyeler = const []}) =>
        DekontModel.fromJson({
          'id': durum.hashCode + (yeniden ? 1 : 0),
          'durum': durum,
          'olusturulma_zamani': '2026-10-14T09:42:00+03:00',
          'beyan_tutar': beyan,
          'islenen_tutar': durum == 'ISLENDI' ? beyan : null,
          'red_nedeni': red,
          'aciklama': 'Ali ve Ayşe Ekim aidatı, kalan kısmı Kasım ayında',
          'dosya_adi': 'banka_uygulamasi_ekran_goruntusu_14_ekim_2026.jpg',
          'yeniden_kontrol': yeniden,
          'islenen_uyeler': [
            for (final u in uyeler) {'ad': u}
          ],
        });

    final dekontlar = [
      dekont('BEKLIYOR', beyan: '1250000.00'),
      dekont('BEKLIYOR', yeniden: true),
      dekont('ISLENDI',
          beyan: '20500.00', uyeler: ['Ali Yılmazoğlu', 'Zeynep Yılmazoğlu']),
      dekont('REDDEDILDI',
          red: 'Dekonttaki tutar ile yazdığın tutar uyuşmuyor, lütfen doğru '
              'dekontu yükleyin. Gerekirse kulüple iletişime geçin.'),
    ];

    tasmaTesti(
      'BankaHesabiKarti (karekod kapalı, uzun adlar)',
      () => Padding(
        padding: const EdgeInsets.all(16),
        child:
            BankaHesabiKarti(hesap: hesap(uzun: true), karekodYapici: karekod),
      ),
    );
    tasmaTesti(
      'BankaHesabiKarti (karekod açık, Paylaş)',
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BankaHesabiKarti(
          hesap: hesap(uzun: true),
          karekodAcikBaslasin: true,
          karekodYapici: karekod,
          onKarekodPaylas: (_) {},
        ),
      ),
    );
    tasmaTesti(
      'BankaHesabiKarti (karekodsuz)',
      () => Padding(
        padding: const EdgeInsets.all(16),
        child: BankaHesabiKarti(
            hesap: hesap(karekodlu: false), karekodYapici: karekod),
      ),
    );
    tasmaTesti(
      'HesaplarGorunumu (iki hesap)',
      () => HesaplarGorunumu(
        hesaplar: [hesap(uzun: true), hesap(karekodlu: false)],
        karekodYapici: karekod,
        onKarekodPaylas: (_) {},
      ),
    );
    tasmaTesti(
      'HesaplarGorunumu (hesap yok, iletişim)',
      () => HesaplarGorunumu(hesaplar: const [], onIletisim: () {}),
    );
    tasmaTesti(
      'DekontlarimGorunumu (her durum, uzun gerekçe, vurgulu)',
      () => DekontlarimGorunumu(
        dekontlar: dekontlar,
        vurgulananId: dekontlar.first.id,
        onTap: (_) {},
        onGeriCek: (_) {},
      ),
    );
    tasmaTesti(
      'DekontlarimGorunumu (boş)',
      () => DekontlarimGorunumu(
        dekontlar: const [],
        onTap: (_) {},
        onGeriCek: (_) {},
        onDekontYukle: () {},
      ),
    );
    for (final d in dekontlar) {
      tasmaTesti(
        'DekontDetayIcerik (${d.durumMetni})',
        () => SingleChildScrollView(
          child: DekontDetayIcerik(
            dekont: d,
            onDosyaGor: () {},
            onGeriCek: () {},
            dosyaAciliyor: d.yenidenKontrol,
          ),
        ),
      );
    }
    tasmaTesti(
      'DekontYukleGovdesi (dosya seçilmedi)',
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DekontYukleGovdesi(
          tutarController: TextEditingController(),
          aciklamaController: TextEditingController(),
          onDosyaSec: () {},
        ),
      ),
    );
    tasmaTesti(
      'DekontYukleGovdesi (PDF, 5 MB hatası, tutar hatası)',
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DekontYukleGovdesi(
          dosyaAdi: 'hesap_hareketleri_ekim_2026_tum_islemler_detayli.pdf',
          dosyaBoyutu: 7549747,
          pdfMi: true,
          hata: 'Dosya 7,2 MB; en fazla 5 MB olabilir. Dekontun ekran '
              'görüntüsünü yükleyebilirsin.',
          tutarHatasi: 'Tutarı rakamla yaz, ör. 12.500',
          tutarController: TextEditingController(text: 'on iki bin'),
          aciklamaController: TextEditingController(),
          onDosyaSec: () {},
        ),
      ),
    );
    tasmaTesti(
      'DekontYukleGovdesi (fotoğraf seçili, gönderiliyor)',
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DekontYukleGovdesi(
          dosyaAdi: 'dekont.jpg',
          dosyaBoyutu: 840000,
          onizleme: base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=='),
          tutarController: TextEditingController(text: '12.500'),
          aciklamaController: TextEditingController(text: 'Ekim aidatı'),
          onDosyaSec: () {},
          etkin: false,
        ),
      ),
    );
    tasmaTesti(
      'DosyaKaynagiSecenekleri',
      () => SingleChildScrollView(
          child: DosyaKaynagiSecenekleri(onSec: (_) {})),
    );
    tasmaTesti(
      'HavaleBilgiSatiri (çok dekont)',
      () => Padding(
        padding: const EdgeInsets.all(12),
        child: HavaleBilgiSatiri(bekleyenSayisi: 12, onTap: () {}),
      ),
    );
  });
}

/// [maddeSayisi] kadar maddeli sürüm notu bloğu; [uzun] ise sözleşme
/// sınırındaki metinler (başlık 42, açıklama 180 karakter) kullanılır.
SurumNotuBlogu _surumNotu({required int maddeSayisi, bool uzun = false}) {
  final baslik = uzun
      ? 'Üye listesi artık çok daha hızlı açılıyor' // 42 karakter
      : 'Profil fotoğrafı';
  final aciklama = uzun
      ? 'Liste yirmişer yükleniyor, arama ve filtre sunucuda çalışıyor; uzun '
          'listede takılma yok. Arama birden çok kelime kabul ediyor ve Türkçe '
          'büyük İ ile küçük ı harflerini ayırt ediyor.'
      : 'Fotoğrafınıza dokunup kameradan çekebilirsiniz.';
  final yol = uzun
      ? 'Menü › Üye Listesi › arama kutusu › filtre simgesi'
      : 'Hesabım › fotoğrafa dokun';

  return SurumNotuBlogu.fromJson({
    'id': 7,
    'surum': '3.12.0',
    'rol': 'uye',
    'baslik': 'Neler yeni?',
    'alt_baslik': '',
    'maddeler': [
      for (var i = 1; i <= maddeSayisi; i++)
        {
          'id': i,
          'baslik': baslik,
          'aciklama': aciklama,
          'yol': yol,
          'ikon': i.isEven ? 'manage_search_rounded' : 'photo_camera_rounded',
          'sira': i,
        }
    ],
  });
}

DuyuruModel _popupDuyurusu({
  required String baslik,
  String altBaslik = '',
}) =>
    DuyuruModel.fromMap({
      'id': 7,
      'baslik': baslik,
      'alt_baslik': altBaslik,
      'icerik': 'Ayrıntılar detay sayfasında.',
      'yayin_baslangic': '2026-10-01T09:00:00+03:00',
      'yayin_bitis': '2026-10-31T23:59:00+03:00',
    });

/* ========================== BİLDİRİM ÖRNEK VERİ ========================== */

Map<String, dynamic> _planDisiVeri({String cikarilanlar = ''}) => {
      'etkinlik_id': 42,
      'tarih': '07.08.2026',
      'saat': '14:00',
      'kort_adi': 'Kapalı Kort 3 (Kuzey)',
      'antrenor_adi': 'Ahmet Kandemiroğulları',
      'eklenenler':
          'Deniz Ayşegül Arslanoğulları (üye), Mehmet Kaya Yılmazoğlu (misafir)',
      'cikarilanlar': cikarilanlar,
    };

NotificationModel _planDisiBildirimi() => NotificationModel(
      id: 1,
      notificationType: NotificationType.ofisPlanDisiKatilim,
      title: 'Plan Dışı Katılımcı',
      body: 'Ahmet Kandemiroğulları, 7 Ağustos 2026 Cuma saat 14:00 Kapalı '
          'Kort 3 (Kuzey) kortundaki ders için plan dışı Deniz Ayşegül '
          'Arslanoğulları (üye), Mehmet Kaya Yılmazoğlu (misafir) ekledi.',
      actionType: ActionType.navigateToScreen,
      actionScreen: 'bildirim_detay',
      displayData: _planDisiVeri(),
      isRead: false,
      timestamp: DateTime(2026, 8, 7, 14, 5),
    );

NotificationModel _duzBildirim() => NotificationModel(
      id: 2,
      notificationType: NotificationType.genel,
      title: 'Bildirim',
      body: 'Kulüp 15 Ağustos Pazar günü bakım nedeniyle kapalı olacaktır.',
      actionType: ActionType.noAction,
      isRead: true,
      timestamp: DateTime(2026, 8, 7, 9, 0),
    );

/* ============================== ÜYE ÖRNEK VERİ ============================== */

List<UyeUrunModel> _uyeUrunler() => [
      UyeUrunModel.fromJson(const {
        'id': 1,
        'uye': 1,
        'urun': 1,
        'urun_adi': 'Yetişkin Grup Paketi (12 Ders) Uzun Ad',
        'urun_tipi': 'PAKET',
        'toplam_hak': 12,
        'kalan_hak': 8,
        'baslangic': '2026-01-01',
        'bitis': '2026-07-01',
        'aktif_mi': true,
      }),
      UyeUrunModel.fromJson(const {
        'id': 2,
        'uye': 1,
        'urun': 2,
        'urun_adi': 'Aylık Aidat Aboneliği',
        'urun_tipi': 'ABONELIK',
        'baslangic': '2026-01-01',
        'bitis': '2026-12-31',
        'aktif_mi': true,
      }),
      UyeUrunModel.fromJson(const {
        'id': 3,
        'uye': 1,
        'urun': 3,
        'urun_adi': 'Yetişkin-Tek-Ders-Üçlü',
        'urun_tipi': 'TEK_SEFERLIK',
        'baslangic': '2026-07-20',
        'aktif_mi': false,
        'dersler': [
          {
            'etkinlik_id': 10,
            'tarih': '2026-07-24T10:00:00+03:00',
            'kort_adi': 'Kapalı Kort 1',
            'antrenor_adi': 'Ayşe Yılmaz Öğretmen',
          },
        ],
      }),
    ];

List<HomeCardModel> _yapilacakKartlar() => [
      // Değer + başlık + alt başlık + aksiyon dolu, en yüksek içerikli kart.
      HomeCardModel.fromJson(const {
        'id': 1,
        'type': 'teyit_bekleyen',
        'title': 'Katılım geri bildirimi bekleniyor',
        'subtitle': '2 ders için katılım durumunu bildirin',
        'action_text': 'Katılım durumunu bildir',
        'action_route': '/teyitBekleyen',
        'value': 2,
      }),
      HomeCardModel.fromJson(const {
        'id': 2,
        'type': 'borc',
        'title': 'Ödenmemiş bakiyeniz var',
        'subtitle': 'Hesap hareketlerinizi görüntüleyin',
        'action_text': 'Hesap hareketleri',
        'value': 1250,
      }),
    ];

List<TeyitBekleyenDers> _teyitBekleyenler() => [
      TeyitBekleyenDers.fromJson(const {
        'etkinlik_id': 1,
        'uye_id': 364,
        'baslangic_tarih_saat': '2026-07-24T18:30:00+03:00',
        'bitis_tarih_saat': '2026-07-24T20:00:00+03:00',
        'kort_adi': 'İkili Kapalı Kort B Çok Uzun Ad',
        'antrenor_adi': 'Ayşe Yılmaz Öğretmen Uzun Soyadıyla',
      }),
      TeyitBekleyenDers.fromJson(const {
        'etkinlik_id': 2,
        'uye_id': 364,
        'baslangic_tarih_saat': '2026-07-26T09:00:00+03:00',
        'bitis_tarih_saat': '2026-07-26T10:00:00+03:00',
        'kort_adi': '',
        'antrenor_adi': '',
      }),
    ];

List<GecmisDersModel> _gecmisDersler() => [
      GecmisDersModel.fromJson(const {
        'id': 1,
        'baslangic_tarih_saat': '2026-07-20T10:00:00+03:00',
        'bitis_tarih_saat': '2026-07-20T11:00:00+03:00',
        'kort_adi': 'Kapalı Kort 1',
        'antrenor_adi': 'Ayşe Yılmaz Öğretmen',
        'urun_adi': 'Grup Dersi Paketi',
        'seviye': 'Kirmizi',
        'iptal_mi': false,
        'katilim': {
          'katildi': true,
          'plan_disi_mi': false,
          'not_metni': 'İyi bir ders oldu, forehand çalışıldı.'
        },
        'puanim': {'puan': 4, 'yorum': 'Teşekkürler'},
      }),
      GecmisDersModel.fromJson(const {
        'id': 2,
        'baslangic_tarih_saat': '2026-06-18T13:00:00+03:00',
        'bitis_tarih_saat': '2026-06-18T14:00:00+03:00',
        'kort_adi': 'Açık Kort 3',
        'antrenor_adi': 'Mehmet Demir',
        'urun_adi': 'Özel Ders',
        'seviye': 'Mavi',
        'iptal_mi': false,
        'katilim': {'katildi': false, 'plan_disi_mi': false},
      }),
    ];

/* ---------------------- HAKEDİŞ SAATLERİ FIXTURE'LARI --------------------- */

Map<String, dynamic> _hakedisGrup(String durum, int sayi, int dakika) => {
      'durum': durum,
      'ders_sayisi': sayi,
      'dakika': dakika,
    };

/// Üç ayı da kapsayan özet: dolu ay, kısmi ay, hiç dersi olmayan ay.
HakedisOzet _hakedisOzet() => HakedisOzet.fromJson({
      'antrenor': {
        'id': 7,
        'ad_soyad': 'Abdurrahman Çelebioğlu Karahanoğulları',
        'aktif_mi': true,
      },
      'aylar': [
        {
          'yil': 2026,
          'ay': 7,
          'etiket': 'Temmuz 2026',
          'kisa_etiket': 'Tem 2026',
          'ders_sayisi': 31,
          'dakika': 2310,
          'hakedis_ders_sayisi': 27,
          'hakedis_dakika': 2040,
          'bekleyen_ders_sayisi': 3,
          'bekleyen_dakika': 210,
          'disi_ders_sayisi': 1,
          'disi_dakika': 60,
          'roller': [
            {
              'rol': 'ana',
              'ders_sayisi': 24,
              'dakika': 1680,
              'gruplar': [
                _hakedisGrup('hakedis', 20, 1410),
                _hakedisGrup('bekliyor', 3, 210),
                _hakedisGrup('disi', 1, 60),
              ],
            },
            {
              'rol': 'yardimci',
              'ders_sayisi': 7,
              'dakika': 630,
              'gruplar': [
                _hakedisGrup('hakedis', 7, 630),
                _hakedisGrup('bekliyor', 0, 0),
                _hakedisGrup('disi', 0, 0),
              ],
            },
          ],
        },
        {
          'yil': 2026,
          'ay': 6,
          'etiket': 'Haziran 2026',
          'kisa_etiket': 'Haz 2026',
          'ders_sayisi': 12,
          'dakika': 720,
          'hakedis_ders_sayisi': 12,
          'hakedis_dakika': 720,
          'bekleyen_ders_sayisi': 0,
          'bekleyen_dakika': 0,
          'disi_ders_sayisi': 0,
          'disi_dakika': 0,
          'roller': [
            {
              'rol': 'ana',
              'ders_sayisi': 12,
              'dakika': 720,
              'gruplar': [
                _hakedisGrup('hakedis', 12, 720),
                _hakedisGrup('bekliyor', 0, 0),
                _hakedisGrup('disi', 0, 0),
              ],
            },
            {
              'rol': 'yardimci',
              'ders_sayisi': 0,
              'dakika': 0,
              'gruplar': [
                _hakedisGrup('hakedis', 0, 0),
                _hakedisGrup('bekliyor', 0, 0),
                _hakedisGrup('disi', 0, 0),
              ],
            },
          ],
        },
        {
          'yil': 2026,
          'ay': 5,
          'etiket': 'Mayıs 2026',
          'kisa_etiket': 'May 2026',
          'ders_sayisi': 0,
          'dakika': 0,
          'hakedis_ders_sayisi': 0,
          'hakedis_dakika': 0,
          'bekleyen_ders_sayisi': 0,
          'bekleyen_dakika': 0,
          'disi_ders_sayisi': 0,
          'disi_dakika': 0,
          'roller': [
            {
              'rol': 'ana',
              'ders_sayisi': 0,
              'dakika': 0,
              'gruplar': [
                _hakedisGrup('hakedis', 0, 0),
                _hakedisGrup('bekliyor', 0, 0),
                _hakedisGrup('disi', 0, 0),
              ],
            },
            {
              'rol': 'yardimci',
              'ders_sayisi': 0,
              'dakika': 0,
              'gruplar': [
                _hakedisGrup('hakedis', 0, 0),
                _hakedisGrup('bekliyor', 0, 0),
                _hakedisGrup('disi', 0, 0),
              ],
            },
          ],
        },
      ],
    });

/// Bir antrenörün 12 aylık dizisi — ilk ay dolu, ikincisi bekleyenli, gerisi boş.
List<Map<String, dynamic>> _hakedisAylikDizi({
  required int hakedisDakika,
  required int bekleyenDers,
}) =>
    [
      for (var i = 0; i < 12; i++)
        {
          'yil': i == 0 ? 2026 : 2025,
          'ay': 12 - i,
          'ders_sayisi': i == 0 ? 24 : (i == 1 ? 8 : 0),
          'dakika': i == 0 ? hakedisDakika : (i == 1 ? 480 : 0),
          'hakedis_ders_sayisi': i == 0 ? 20 : 0,
          'hakedis_dakika': i == 0 ? hakedisDakika : 0,
          'bekleyen_ders_sayisi': i == 1 ? bekleyenDers : 0,
          'bekleyen_dakika': i == 1 ? 480 : 0,
          'disi_ders_sayisi': 0,
          'disi_dakika': 0,
        }
    ];

/// Ay ızgarası + antrenör listesi tek yanıtta — yönetici seçim ekranının verisi.
HakedisAntrenorListesi _hakedisAntrenorListesi() =>
    HakedisAntrenorListesi.fromJson({
      'ay_sayisi': 12,
      'aylar': [
        for (var i = 0; i < 12; i++)
          {
            'yil': i == 0 ? 2026 : 2025,
            'ay': 12 - i,
            'etiket': 'Ay ${12 - i} ${i == 0 ? 2026 : 2025}',
            'kisa_etiket': 'Ağu ${i == 0 ? 2026 : 2025}',
            'ders_sayisi': i < 2 ? 32 : 0,
            'dakika': i < 2 ? 2880 : 0,
            'hakedis_ders_sayisi': i == 0 ? 28 : 0,
            'hakedis_dakika': i == 0 ? 2400 : 0,
            'bekleyen_ders_sayisi': i == 1 ? 8 : 0,
            'bekleyen_dakika': i == 1 ? 480 : 0,
            'disi_ders_sayisi': 0,
            'disi_dakika': 0,
          }
      ],
      'antrenorler': [
        {
          'antrenor_id': 7,
          'ad_soyad': 'Abdurrahman Çelebioğlu Karahanoğulları',
          'aktif_mi': true,
          'ders_sayisi': 296,
          'dakika': 26580,
          'hakedis_ders_sayisi': 284,
          'hakedis_dakika': 25680,
          'bekleyen_ders_sayisi': 12,
          'bekleyen_dakika': 900,
          'disi_ders_sayisi': 0,
          'disi_dakika': 0,
          'aylar': _hakedisAylikDizi(hakedisDakika: 25680, bekleyenDers: 12),
        },
        {
          'antrenor_id': 8,
          'ad_soyad': 'Ali Vural',
          'aktif_mi': false,
          'ders_sayisi': 96,
          'dakika': 5760,
          'hakedis_ders_sayisi': 96,
          'hakedis_dakika': 5760,
          'bekleyen_ders_sayisi': 0,
          'bekleyen_dakika': 0,
          'disi_ders_sayisi': 0,
          'disi_dakika': 0,
          'aylar': _hakedisAylikDizi(hakedisDakika: 5760, bekleyenDers: 0),
        },
      ],
    });

/// Uzun isimli, plan dışı katılımcı içeren kalabalık grup dersi.
/// Kayıt formunun açılır listeleri — uzun kulüp/okul adları bilinçli.
KayitSecenekleri _kayitSecenekleri() => const KayitSecenekleri(
      isletmeler: [
        Secenek(deger: '1', etiket: 'Binay Tenis Akademi Spor Kulübü Derneği'),
      ],
      okullar: [
        Secenek(deger: '7', etiket: 'Şehit Öğretmen Cumhuriyet Ortaokulu'),
      ],
      cinsiyetler: [
        Secenek(deger: 'Erkek', etiket: 'Erkek'),
        Secenek(deger: 'Kadın', etiket: 'Kadın'),
      ],
      tenisGecmisi: [
        Secenek(deger: 'Var', etiket: 'Var'),
        Secenek(deger: 'Yok', etiket: 'Yok'),
      ],
      programTercihleri: [
        Secenek(deger: 'Altyapı', etiket: 'Altyapı'),
        Secenek(deger: 'Hobi', etiket: 'Hobi'),
      ],
    );

HakedisDers _hakedisDers() => HakedisDers.fromJson(const {
      'id': 41,
      'baslangic': '2026-07-14T18:00:00+03:00',
      'bitis': '2026-07-14T19:30:00+03:00',
      'dakika': 90,
      'rol': 'ana',
      'durum': 'hakedis',
      'kort_adi': 'Kapalı Kort 1',
      'urun_adi': 'Performans Grup Dersi Paketi',
      'urun_tipi': 'PAKET',
      'iptal_mi': false,
      'yonetici_tamamlandi': true,
      'onay_nedeni': null,
      'onay_aciklamasi': null,
      'katilimcilar': [
        {
          'uye_id': 1,
          'ad_soyad': 'Deniz Ayşegül Arslanoğulları',
          'katilim_durum': 'katildi',
          'plan_disi_mi': false,
        },
        {
          'uye_id': 2,
          'ad_soyad': 'Ece Bulut',
          'katilim_durum': 'katilmadi',
          'plan_disi_mi': false,
        },
        {
          'uye_id': 3,
          'ad_soyad': 'Kaan Özdemir',
          'katilim_durum': 'katildi',
          'plan_disi_mi': true,
          'not_metni': 'Arkadaşıyla geldi',
        },
        {
          'uye_id': 4,
          'ad_soyad': 'Mehmet Ali Şahin',
          'katilim_durum': null,
          'plan_disi_mi': false,
        },
      ],
    });

/// İptal edilmiş ders — "hakediş dışı" grubunda çıkar, iptal paneli render edilir.
HakedisDers _hakedisDersIptal() => HakedisDers.fromJson(const {
      'id': 43,
      'baslangic': '2026-07-21T20:00:00+03:00',
      'bitis': '2026-07-21T21:00:00+03:00',
      'dakika': 60,
      'rol': 'ana',
      'durum': 'disi',
      'kort_adi': 'Kapalı Kort 2',
      'urun_adi': 'Performans Grup Dersi Paketi',
      'urun_tipi': 'PAKET',
      'iptal_mi': true,
      'yonetici_tamamlandi': false,
      'onay_nedeni': 'Hava koşulları',
      'onay_aciklamasi': null,
      'iptal_eden': 'Mehmet Ali Şahinoğulları Yönetici',
      'iptal_tarihi': '2026-07-20T14:35:00+03:00',
      'iptal_sebebi': 'Hava koşulları',
      'iptal_aciklamasi':
          'Sağanak yağış nedeniyle kortlar kullanılamadı, tüm akşam programı '
              'iptal edildi ve üyelere telafi hakkı tanındı.',
      'katilimcilar': [
        {
          'uye_id': 1,
          'ad_soyad': 'Deniz Ayşegül Arslanoğulları',
          'katilim_durum': null,
          'plan_disi_mi': false,
        },
      ],
    });

/// Ders yapılmamış ama hakediş verilmiş kayıt — onay notu satırı render edilir.
HakedisDers _hakedisDersYapilmadi() => HakedisDers.fromJson(const {
      'id': 42,
      'baslangic': '2026-07-19T09:00:00+03:00',
      'bitis': '2026-07-19T10:30:00+03:00',
      'dakika': 90,
      'rol': 'yardimci',
      'durum': 'hakedis',
      'kort_adi': 'Açık Kort 3',
      'urun_adi': 'Özel Ders',
      'urun_tipi': 'TEK_SEFERLIK',
      'iptal_mi': false,
      'yonetici_tamamlandi': false,
      'hakedis_bayragi': true,
      'onay_nedeni': 'Hava muhalefeti',
      'onay_aciklamasi':
          'Yağmur nedeniyle ders yapılamadı, antrenör kortta hazır bekledi.',
      'katilimcilar': [
        {
          'uye_id': 1,
          'ad_soyad': 'Deniz Ayşegül Arslanoğulları',
          'katilim_durum': null,
          'plan_disi_mi': false,
        },
      ],
    });

/// İptal değil, yönetici açıkça "hakediş almaz" demiş — sebep paneli yazılır.
HakedisDers _hakedisDersAlmaz() => HakedisDers.fromJson(const {
      'id': 44,
      'baslangic': '2026-07-23T07:30:00+03:00',
      'bitis': '2026-07-23T08:30:00+03:00',
      'dakika': 60,
      'rol': 'ana',
      'durum': 'disi',
      'kort_adi': 'Açık Kort 5',
      'urun_adi': 'Sabah Kondisyon Grubu',
      'urun_tipi': 'ABONELIK',
      'iptal_mi': false,
      'yonetici_tamamlandi': true,
      'hakedis_bayragi': false,
      'onay_nedeni': 'Diğer',
      'onay_aciklamasi':
          'Ders başka bir antrenörle birlikte yürütüldü, hakediş ana antrenöre '
              'yazıldı.',
      'katilimcilar': [
        {
          'uye_id': 1,
          'ad_soyad': 'Deniz Ayşegül Arslanoğulları',
          'katilim_durum': 'katildi',
          'plan_disi_mi': false,
        },
      ],
    });

OdulDurumModel _odul({int sayac = 14, bool kod = false}) =>
    OdulDurumModel.fromJson({
      'aktif': true,
      'odul_adi': 'Kahve',
      'aciklama': 'Kafede sıcak ya da soğuk kahve seçebilirsin. '
          'Tatlı ve atıştırmalıklar ödüle dahil değildir.',
      'ikon': 'kahve',
      'esik': 20,
      'gecerlilik_gun': 7,
      'sayac': sayac,
      'kalan': 20 - sayac,
      'hak_edildi': sayac >= 20 || kod,
      'bekleyen_odul': kod
          ? const {
              'kod': 'BK-7F3Q',
              'durum': 'BEKLIYOR',
              'kazanma_zamani': '2026-07-29T14:32:00+03:00',
              'son_kullanma': '2026-08-05T14:32:00+03:00',
              'son_kullanma_metin': '05.08.2026',
            }
          : null,
    });

KullaniciProfilModel _profil(
        int id, String rol, String ad, String soyad, String? isletme) =>
    KullaniciProfilModel.fromJson({
      'id': id,
      'user': {
        'id': id,
        'password': '',
        'is_superuser': false,
        'username': 'kullanici$id',
        'first_name': ad,
        'last_name': soyad,
        'email': 'k$id@ornek.com',
        'is_staff': false,
        'is_active': true,
        'date_joined': '2026-01-01T00:00:00+03:00',
        'groups': <int>[],
        'user_permissions': <dynamic>[],
      },
      'rol': rol,
      'uye': null,
      'antrenor': null,
      'ana_hesap_mi': true,
      'isletme_id': isletme == null ? null : 1,
      'isletme_adi': isletme,
    });

/// Taşma testleri için sade bir üye: fotoğraf YOK (ağ görseli widget
/// testinde yüklenemez, baş harfler çizilir).
UyeModel _uyeModeli(String adi, String soyadi) => UyeModel.fromJson({
      'id': 1,
      'adi': adi,
      'soyadi': soyadi,
      'uye_no': 104286,
      'seviye_rengi': 'Sari',
      'uye_turu': 'Öğrenci',
      'aktif_mi': true,
      'onaylandi_mi': true,
      'uye_tipi': 1,
      'cinsiyet': 'Kadın',
      'telefon': '5551234567',
      'email': 'ornek@ornek.com',
      'adres': 'İstanbul',
      'referansi': 'Belirtilmedi',
      'dogum_tarihi': '1998-04-12',
    });
