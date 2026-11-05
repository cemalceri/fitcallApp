// lib/models/10_ofis/ofis_uye_talep_models.dart
//
// Ofisin gördüğü üye ders / kort kiralama talebi. Ofis para ve paket kalanını
// görmez: sunucu yalnız "Paket yeterli / yetmiyor", "Telafi geçerli" gibi bir
// metin gönderir (uye_talep_service.ofis_talep_sozlugu); burada da tutar yok.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';

int _int(dynamic v, [int varsayilan = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? varsayilan;
}

int? _intN(dynamic v) => v == null ? null : int.tryParse(v.toString());

String _str(dynamic v) => v?.toString() ?? '';

bool _bool(dynamic v) => v == true || v == 1 || v == 'true';

List<Map<String, dynamic>> _liste(dynamic v) => (v as List? ?? const [])
    .whereType<Map>()
    .map((e) => e.cast<String, dynamic>())
    .toList();

class OfisTalepEylemleri {
  final bool hocayaSor;
  final bool telefonOnay;
  final bool kaydet;
  final bool oneri;
  final bool reddet;
  final bool oneriGeriCek;

  const OfisTalepEylemleri({
    this.hocayaSor = false,
    this.telefonOnay = false,
    this.kaydet = false,
    this.oneri = false,
    this.reddet = false,
    this.oneriGeriCek = false,
  });

  factory OfisTalepEylemleri.fromJson(dynamic json) {
    final j = (json as Map?)?.cast<String, dynamic>() ?? const {};
    return OfisTalepEylemleri(
      hocayaSor: _bool(j['hocaya_sor']),
      telefonOnay: _bool(j['telefon_onay']),
      kaydet: _bool(j['kaydet']),
      oneri: _bool(j['oneri']),
      reddet: _bool(j['reddet']),
      oneriGeriCek: _bool(j['oneri_geri_cek']),
    );
  }
}

class OfisTalepOnerisi {
  final DateTime baslangic;
  final String dersTanimi;
  final String notu;
  final String sonCevapMetni;
  final String? ekstraUcret;

  const OfisTalepOnerisi({
    required this.baslangic,
    required this.dersTanimi,
    this.notu = '',
    this.sonCevapMetni = '',
    this.ekstraUcret,
  });

  static OfisTalepOnerisi? fromJsonN(dynamic json) {
    if (json is! Map) return null;
    final j = json.cast<String, dynamic>();
    return OfisTalepOnerisi(
      baslangic: parseApiTarihOrNow(j['baslangic_tarih_saat']),
      dersTanimi: _str(j['ders_tanimi']),
      notu: _str(j['notu']),
      sonCevapMetni: _str(j['son_cevap_metni']),
      ekstraUcret: j['ekstra_ucret']?.toString(),
    );
  }
}

class OfisUyeTalep {
  final int id;
  final String tur;
  final String turAdi;
  final String durum;
  final String sekme;
  final String etiketMetni;
  final String kapanisMetni;
  final int? uyeId;
  final String uyeAdi;
  final int? antrenorId;
  final String antrenorAdi;
  final bool hocaFarkEtmez;
  final int? kortId;
  final String kortAdi;
  final bool kortFarkEtmez;
  final String tarih;
  final DateTime baslangic;
  final DateTime bitis;
  final String saat;
  final String bitisSaat;
  final int sureDk;
  final String dersTanimi;
  final bool esneme;
  final int esnemeSaat;
  final int? kisiSayisi;
  final String aciklama;
  final String hakDurumu;
  final bool hakUygun;
  final String hocaOnay;
  final String hocaOnayMetni;
  final int? hocaOnayAntrenorId;
  final String hocaOnayAntrenorAdi;
  final String hocaNotu;
  final OfisTalepOnerisi? oneri;
  final bool acil;
  final int? beklemeDk;
  final int ayniSaate;
  final String inceleyenAdi;
  final String cakisma;
  final String redNedeni;
  final String islemYapanAdi;
  final String beklemeMetni;

  /// Kaydedilen dersin gerçek günü/saati/hocası (talepten farklı olabilir).
  final String olusanDersTanimi;
  final OfisTalepEylemleri eylemler;

  const OfisUyeTalep({
    required this.id,
    required this.tur,
    this.turAdi = '',
    required this.durum,
    this.sekme = 'bende',
    this.etiketMetni = '',
    this.kapanisMetni = '',
    this.uyeId,
    this.uyeAdi = '',
    this.antrenorId,
    this.antrenorAdi = '',
    this.hocaFarkEtmez = false,
    this.kortId,
    this.kortAdi = '',
    this.kortFarkEtmez = false,
    this.tarih = '',
    required this.baslangic,
    required this.bitis,
    this.saat = '',
    this.bitisSaat = '',
    this.sureDk = 60,
    this.dersTanimi = '',
    this.esneme = false,
    this.esnemeSaat = 1,
    this.kisiSayisi,
    this.aciklama = '',
    this.hakDurumu = '',
    this.hakUygun = true,
    this.hocaOnay = '',
    this.hocaOnayMetni = '',
    this.hocaOnayAntrenorId,
    this.hocaOnayAntrenorAdi = '',
    this.hocaNotu = '',
    this.oneri,
    this.acil = false,
    this.beklemeDk,
    this.ayniSaate = 1,
    this.inceleyenAdi = '',
    this.cakisma = '',
    this.redNedeni = '',
    this.islemYapanAdi = '',
    this.beklemeMetni = '',
    this.olusanDersTanimi = '',
    this.eylemler = const OfisTalepEylemleri(),
  });

  factory OfisUyeTalep.fromJson(Map<String, dynamic> j) => OfisUyeTalep(
        id: _int(j['id']),
        tur: _str(j['tur']),
        turAdi: _str(j['tur_adi']),
        durum: _str(j['durum']),
        sekme: _str(j['sekme']),
        etiketMetni: _str(j['etiket_metni']),
        kapanisMetni: _str(j['kapanis_metni']),
        uyeId: _intN(j['uye_id']),
        uyeAdi: _str(j['uye_adi']),
        antrenorId: _intN(j['antrenor_id']),
        antrenorAdi: _str(j['antrenor_adi']),
        hocaFarkEtmez: _bool(j['hoca_fark_etmez']),
        kortId: _intN(j['kort_id']),
        kortAdi: _str(j['kort_adi']),
        kortFarkEtmez: _bool(j['kort_fark_etmez']),
        tarih: _str(j['tarih']),
        baslangic: parseApiTarihOrNow(j['baslangic_tarih_saat']),
        bitis: parseApiTarihOrNow(j['bitis_tarih_saat']),
        saat: _str(j['saat']),
        bitisSaat: _str(j['bitis_saat']),
        sureDk: _int(j['sure_dk'], 60),
        dersTanimi: _str(j['ders_tanimi']),
        esneme: _bool(j['esneme']),
        esnemeSaat: _int(j['esneme_saat'], 1),
        kisiSayisi: _intN(j['kisi_sayisi']),
        aciklama: _str(j['aciklama']),
        hakDurumu: _str(j['hak_durumu']),
        hakUygun: j['hak_uygun'] == null || _bool(j['hak_uygun']),
        hocaOnay: _str(j['hoca_onay']),
        hocaOnayMetni: _str(j['hoca_onay_metni']),
        hocaOnayAntrenorId: _intN(j['hoca_onay_antrenor_id']),
        hocaOnayAntrenorAdi: _str(j['hoca_onay_antrenor_adi']),
        hocaNotu: _str(j['hoca_notu']),
        oneri: OfisTalepOnerisi.fromJsonN(j['oneri']),
        acil: _bool(j['acil']),
        beklemeDk: _intN(j['bekleme_dk']),
        ayniSaate: _int(j['ayni_saate'], 1),
        inceleyenAdi: _str(j['inceleyen_adi']),
        cakisma: _str(j['cakisma']),
        redNedeni: _str(j['red_nedeni']),
        islemYapanAdi: _str(j['islem_yapan_adi']),
        beklemeMetni: _str(j['bekleme_metni']),
        olusanDersTanimi: _str(j['olusan_ders_tanimi']),
        eylemler: OfisTalepEylemleri.fromJson(j['eylemler']),
      );

  bool get hocali => tur != 'KORT';

  bool get hocaOnayli => hocaOnay == 'EVET' || hocaOnay == 'TELEFON';
}

/// Detay ekranının seçim listesi satırı (hoca, kort, ürün). `bos`: o saatte boş.
class OfisSecimOgesi {
  final int id;
  final String ad;
  final bool bos;

  const OfisSecimOgesi({required this.id, required this.ad, this.bos = true});
}

class OfisTalepDetay {
  final OfisUyeTalep talep;
  final DateTime secimBaslangic;
  final int secimSureDk;
  final bool uyeBos;
  final List<OfisSecimOgesi> hocalar;
  final List<OfisSecimOgesi> kortlar;
  final List<OfisSecimOgesi> urunler;
  final List<int> surelerDk;
  final int maxKisi;

  const OfisTalepDetay({
    required this.talep,
    required this.secimBaslangic,
    required this.secimSureDk,
    this.uyeBos = true,
    this.hocalar = const [],
    this.kortlar = const [],
    this.urunler = const [],
    this.surelerDk = const [60, 90, 120],
    this.maxKisi = 4,
  });

  factory OfisTalepDetay.fromJson(Map<String, dynamic> j) {
    final secim = (j['secim'] as Map?)?.cast<String, dynamic>() ?? const {};
    return OfisTalepDetay(
      talep: OfisUyeTalep.fromJson(j),
      secimBaslangic: parseApiTarihOrNow(secim['baslangic_tarih_saat']),
      secimSureDk: _int(secim['sure_dk'], 60),
      uyeBos: secim['uye_bos'] == null || _bool(secim['uye_bos']),
      hocalar: _liste(j['hocalar'])
          .map((h) => OfisSecimOgesi(
              id: _int(h['id']), ad: _str(h['ad']), bos: _bool(h['bos'])))
          .toList(),
      kortlar: _liste(j['kortlar'])
          .map((k) => OfisSecimOgesi(
              id: _int(k['id']), ad: _str(k['adi']), bos: _bool(k['bos'])))
          .toList(),
      urunler: _liste(j['urunler'])
          .map((u) => OfisSecimOgesi(id: _int(u['id']), ad: _str(u['adi'])))
          .toList(),
      surelerDk: (j['sureler_dk'] as List? ?? const [60, 90, 120])
          .map((e) => _int(e, 60))
          .toList(),
      maxKisi: _int(j['max_kisi'], 4),
    );
  }
}

class OfisTalepListesi {
  final List<OfisUyeTalep> talepler;

  /// Bende sekmesinde antrenörün ders kayıt talepleri (eski akış).
  final List<DersKayitTalebi> antrenorTalepleri;
  final int bendeSayisi;
  final int beklemedeSayisi;

  const OfisTalepListesi({
    this.talepler = const [],
    this.antrenorTalepleri = const [],
    this.bendeSayisi = 0,
    this.beklemedeSayisi = 0,
  });

  factory OfisTalepListesi.fromJson(Map<String, dynamic> j) {
    final sayilar = (j['sayilar'] as Map?)?.cast<String, dynamic>() ?? const {};
    return OfisTalepListesi(
      talepler: _liste(j['talepler']).map(OfisUyeTalep.fromJson).toList(),
      antrenorTalepleri: _liste(j['antrenor_talepleri'])
          .map(DersKayitTalebi.fromJson)
          .toList(),
      bendeSayisi: _int(sayilar['bende']),
      beklemedeSayisi: _int(sayilar['beklemede']),
    );
  }
}

/// Antrenörün "Ofis soruyor" kartı.
class HocaTalepSorusu {
  final int id;
  final String turAdi;
  final String uyeAdi;
  final String kortAdi;
  final DateTime baslangic;
  final String dersTanimi;
  final String aciklama;
  final bool bekliyor;
  final String cevap; // EVET | HAYIR | ''
  final String hocaNotu;
  final String sonCevapMetni;
  final String esnemeMetni;

  /// Cevaplanan soruda talebin sonucu ("Ders kaydedildi: …", "Talep ders
  /// olmadan kapandı"); bekleyen soruda boş.
  final String sonuc;

  const HocaTalepSorusu({
    required this.id,
    this.turAdi = '',
    this.uyeAdi = '',
    this.kortAdi = '',
    required this.baslangic,
    this.dersTanimi = '',
    this.aciklama = '',
    this.bekliyor = true,
    this.cevap = '',
    this.hocaNotu = '',
    this.sonCevapMetni = '',
    this.esnemeMetni = '',
    this.sonuc = '',
  });

  factory HocaTalepSorusu.fromJson(Map<String, dynamic> j) => HocaTalepSorusu(
        id: _int(j['id']),
        turAdi: _str(j['tur_adi']),
        uyeAdi: _str(j['uye_adi']),
        kortAdi: _str(j['kort_adi']),
        baslangic: parseApiTarihOrNow(j['baslangic_tarih_saat']),
        dersTanimi: _str(j['ders_tanimi']),
        aciklama: _str(j['aciklama']),
        bekliyor: _bool(j['bekliyor']),
        cevap: _str(j['cevap']),
        hocaNotu: _str(j['hoca_notu']),
        sonCevapMetni: _str(j['son_cevap_metni']),
        esnemeMetni: _str(j['esneme_metni']),
        sonuc: _str(j['sonuc']),
      );
}
