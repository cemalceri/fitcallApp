// lib/models/2_uye/uye_talep_models.dart
//
// Üye ders / kort kiralama talebi modelleri.
// Backend: api/uye_talep/metots.py, kurallar
// calendarapp/services/uye_talep_service.py.

import 'package:fitcall/common/tarih_util.dart';

int _int(dynamic v, [int varsayilan = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? varsayilan;
}

int? _intN(dynamic v) => v == null ? null : int.tryParse(v.toString());

String _str(dynamic v) => v?.toString() ?? '';

bool _bool(dynamic v) => v == true || v == 1 || v == 'true';

List<String> _metinler(dynamic v) =>
    (v as List? ?? const []).map((e) => e.toString()).toList();

List<Map<String, dynamic>> _liste(dynamic v) => (v as List? ?? const [])
    .whereType<Map>()
    .map((e) => e.cast<String, dynamic>())
    .toList();

/// "Neyle?" seçimi — sunucudaki UyeTalepTuruEnum.
class TalepTuru {
  static const telafi = 'TELAFI';
  static const paket = 'PAKET';
  static const tekDers = 'TEK_DERS';
  static const kort = 'KORT';

  /// Kort kiralamada hoca seçilmez.
  static bool hocali(String tur) => tur != kort;
}

class TalepSecenegi {
  final String tur;
  final String baslik;
  final bool uygun;
  final String aciklama;

  /// Telafide süre iptal edilen ders kadardır, değişmez.
  final int? sabitSureDk;
  final DateTime? sonGun;

  const TalepSecenegi({
    required this.tur,
    required this.baslik,
    required this.uygun,
    this.aciklama = '',
    this.sabitSureDk,
    this.sonGun,
  });

  factory TalepSecenegi.fromJson(Map<String, dynamic> j) => TalepSecenegi(
        tur: _str(j['tur']),
        baslik: _str(j['baslik']),
        uygun: _bool(j['uygun']),
        aciklama: _str(j['aciklama']),
        sabitSureDk: _intN(j['sabit_sure_dk']),
        sonGun: parseApiGun(j['son_gun']),
      );
}

class TalepKisi {
  final int id;
  final String ad;

  const TalepKisi({required this.id, required this.ad});
}

class TalepBaslangic {
  final bool acikMi;
  final List<TalepKisi> kiminIcin;
  final int uyeId;
  final String uyeAdi;
  final List<TalepSecenegi> secenekler;
  final List<TalepKisi> hocalar;
  final List<int> surelerDk;
  final int maxKisi;
  final int esnemeSaat;
  final int acikTalepSayisi;
  final int maxAcik;
  final bool limitDoldu;
  final String mesaiNotu;
  final String iptalKurali;

  const TalepBaslangic({
    required this.acikMi,
    required this.kiminIcin,
    required this.uyeId,
    required this.uyeAdi,
    required this.secenekler,
    required this.hocalar,
    required this.surelerDk,
    this.maxKisi = 4,
    this.esnemeSaat = 1,
    this.acikTalepSayisi = 0,
    this.maxAcik = 3,
    this.limitDoldu = false,
    this.mesaiNotu = '',
    this.iptalKurali = '',
  });

  factory TalepBaslangic.fromJson(Map<String, dynamic> j) => TalepBaslangic(
        acikMi: _bool(j['acik_mi']),
        kiminIcin: _liste(j['kimin_icin'])
            .map((e) => TalepKisi(id: _int(e['uye_id']), ad: _str(e['ad'])))
            .toList(),
        uyeId: _int(j['uye_id']),
        uyeAdi: _str(j['uye_adi']),
        secenekler:
            _liste(j['secenekler']).map(TalepSecenegi.fromJson).toList(),
        hocalar: _liste(j['hocalar'])
            .map((e) => TalepKisi(id: _int(e['id']), ad: _str(e['ad'])))
            .toList(),
        surelerDk: (j['sureler_dk'] as List? ?? const [60])
            .map((e) => _int(e, 60))
            .toList(),
        maxKisi: _int(j['max_kisi'], 4),
        esnemeSaat: _int(j['esneme_saat'], 1),
        acikTalepSayisi: _int(j['acik_talep_sayisi']),
        maxAcik: _int(j['max_acik'], 3),
        limitDoldu: _bool(j['limit_doldu']),
        mesaiNotu: _str(j['mesai_notu']),
        iptalKurali: _str(j['iptal_kurali']),
      );

  TalepSecenegi? secenek(String tur) {
    for (final s in secenekler) {
      if (s.tur == tur) return s;
    }
    return null;
  }
}

/// Haritadaki bir başlangıç saati: uygun / dolu / benim / kapali.
class HaritaSaat {
  final String saat;
  final String durum;

  const HaritaSaat(this.saat, this.durum);

  bool get uygun => durum == 'uygun';
}

class HaritaGun {
  final DateTime tarih;
  final String gunAdi;
  final List<HaritaSaat> saatler;

  const HaritaGun(
      {required this.tarih, required this.gunAdi, required this.saatler});

  int get uygunSayisi => saatler.where((s) => s.uygun).length;
}

class TalepHarita {
  final DateTime haftaBaslangic;
  final bool oncekiHafta;
  final bool sonrakiHafta;
  final int sureDk;
  final List<HaritaGun> gunler;

  const TalepHarita({
    required this.haftaBaslangic,
    required this.oncekiHafta,
    required this.sonrakiHafta,
    required this.sureDk,
    required this.gunler,
  });

  factory TalepHarita.fromJson(Map<String, dynamic> j) => TalepHarita(
        haftaBaslangic: parseApiGun(j['hafta_baslangic']) ?? bugunKulup(),
        oncekiHafta: _bool(j['onceki_hafta']),
        sonrakiHafta: _bool(j['sonraki_hafta']),
        sureDk: _int(j['sure_dk'], 60),
        gunler: _liste(j['gunler'])
            .map((g) => HaritaGun(
                  tarih: parseApiGun(g['tarih']) ?? bugunKulup(),
                  gunAdi: _str(g['gun_adi']),
                  saatler: _liste(g['saatler'])
                      .map((s) => HaritaSaat(_str(s['saat']), _str(s['durum'])))
                      .toList(),
                ))
            .toList(),
      );
}

/// "Paketinden 1,5 ders düşer" / "Ücret: 3.900 ₺" satırı.
class TalepTahmin {
  final String metin;
  final bool paketYetmiyor;
  final String uyari;

  const TalepTahmin(
      {this.metin = '', this.paketYetmiyor = false, this.uyari = ''});

  factory TalepTahmin.fromJson(dynamic json) {
    final j = (json as Map?)?.cast<String, dynamic>() ?? const {};
    return TalepTahmin(
      metin: _str(j['metin']),
      paketYetmiyor: _bool(j['paket_yetmiyor']),
      uyari: _str(j['uyari']),
    );
  }
}

class SecenekHoca {
  final int id;
  final String ad;
  final TalepTahmin tahmin;

  const SecenekHoca({required this.id, required this.ad, required this.tahmin});
}

class TalepSecenekleri {
  final DateTime baslangic;
  final DateTime bitis;
  final int sureDk;
  final String dersTanimi;
  final List<SecenekHoca> hocalar;
  final List<TalepKisi> kortlar;
  final TalepTahmin farkEtmezTahmin;
  final bool uyeBos;

  const TalepSecenekleri({
    required this.baslangic,
    required this.bitis,
    required this.sureDk,
    required this.dersTanimi,
    required this.hocalar,
    required this.kortlar,
    required this.farkEtmezTahmin,
    this.uyeBos = true,
  });

  factory TalepSecenekleri.fromJson(Map<String, dynamic> j) => TalepSecenekleri(
        baslangic: parseApiTarihOrNow(j['baslangic_tarih_saat']),
        bitis: parseApiTarihOrNow(j['bitis_tarih_saat']),
        sureDk: _int(j['sure_dk'], 60),
        dersTanimi: _str(j['ders_tanimi']),
        hocalar: _liste(j['hocalar'])
            .map((h) => SecenekHoca(
                  id: _int(h['id']),
                  ad: _str(h['ad']),
                  tahmin: TalepTahmin.fromJson(h['tahmin']),
                ))
            .toList(),
        kortlar: _liste(j['kortlar'])
            .map((k) => TalepKisi(id: _int(k['id']), ad: _str(k['adi'])))
            .toList(),
        farkEtmezTahmin: TalepTahmin.fromJson(j['fark_etmez_tahmin']),
        uyeBos: j['uye_bos'] == null || _bool(j['uye_bos']),
      );

  /// Seçilen hocaya göre (null = Fark etmez) tahmin.
  TalepTahmin tahminFor(int? hocaId) {
    if (hocaId == null) return farkEtmezTahmin;
    for (final h in hocalar) {
      if (h.id == hocaId) return h.tahmin;
    }
    return farkEtmezTahmin;
  }
}

class TalepOnerisi {
  final DateTime baslangic;
  final DateTime bitis;
  final int sureDk;
  final String dersTanimi;
  final String antrenorAdi;
  final String kortAdi;
  final int? kisiSayisi;
  final String urunAdi;
  final String notu;
  final DateTime? sonCevap;
  final String sonCevapMetni;
  final String ekstraUcretMetni;
  final String ozet;

  /// Talepte istenene göre değişenler ("Saat: 17:00-18:30 → 18:00-19:30").
  final List<String> degisenler;

  const TalepOnerisi({
    required this.baslangic,
    required this.bitis,
    required this.sureDk,
    required this.dersTanimi,
    this.antrenorAdi = '',
    this.kortAdi = '',
    this.kisiSayisi,
    this.urunAdi = '',
    this.notu = '',
    this.sonCevap,
    this.sonCevapMetni = '',
    this.ekstraUcretMetni = '',
    this.ozet = '',
    this.degisenler = const [],
  });

  static TalepOnerisi? fromJsonN(dynamic json) {
    if (json is! Map) return null;
    final j = json.cast<String, dynamic>();
    return TalepOnerisi(
      baslangic: parseApiTarihOrNow(j['baslangic_tarih_saat']),
      bitis: parseApiTarihOrNow(j['bitis_tarih_saat']),
      sureDk: _int(j['sure_dk'], 60),
      dersTanimi: _str(j['ders_tanimi']),
      antrenorAdi: _str(j['antrenor_adi']),
      kortAdi: _str(j['kort_adi']),
      kisiSayisi: _intN(j['kisi_sayisi']),
      urunAdi: _str(j['urun_adi']),
      notu: _str(j['notu']),
      sonCevap: parseApiTarih(j['son_cevap']),
      sonCevapMetni: _str(j['son_cevap_metni']),
      ekstraUcretMetni: _str(j['ekstra_ucret_metni']),
      ozet: _str(j['ozet']),
      degisenler: _metinler(j['degisenler']),
    );
  }
}

/// Üyenin "Taleplerim" satırı. `uyeDurum`: OFISTE · CEVAP_BEKLIYOR ·
/// ONAYLANDI · KAPANDI; `durumMetni` ekranda gösterilecek kısa metin.
class UyeTalep {
  final int id;
  final String tur;
  final String turAdi;
  final String durum;
  final String uyeDurum;
  final String durumMetni;
  final int uyeId;
  final String uyeAdi;
  final int? antrenorId;
  final String antrenorAdi;
  final int? kortId;
  final String kortAdi;
  final DateTime baslangic;
  final DateTime bitis;
  final int sureDk;
  final String dersTanimi;
  final bool esneme;
  final int? kisiSayisi;
  final String aciklama;
  final String ozet;
  final bool paketYetmiyor;
  final String redNedeni;
  final TalepOnerisi? oneri;
  final String dersAciklamasi;
  final bool dersIptal;

  /// Kaydedilen derste istenene göre değişenler (saat kaydı, atanan hoca…).
  final List<String> dersDegisenler;
  final DateTime? olusturulma;
  final bool geriCekilebilir;
  final bool duzenlenebilir;

  const UyeTalep({
    required this.id,
    required this.tur,
    required this.turAdi,
    required this.durum,
    required this.uyeDurum,
    required this.durumMetni,
    required this.uyeId,
    this.uyeAdi = '',
    this.antrenorId,
    this.antrenorAdi = '',
    this.kortId,
    this.kortAdi = '',
    required this.baslangic,
    required this.bitis,
    required this.sureDk,
    this.dersTanimi = '',
    this.esneme = false,
    this.kisiSayisi,
    this.aciklama = '',
    this.ozet = '',
    this.paketYetmiyor = false,
    this.redNedeni = '',
    this.oneri,
    this.dersAciklamasi = '',
    this.dersIptal = false,
    this.dersDegisenler = const [],
    this.olusturulma,
    this.geriCekilebilir = false,
    this.duzenlenebilir = false,
  });

  factory UyeTalep.fromJson(Map<String, dynamic> j) {
    final ders = (j['ders'] as Map?)?.cast<String, dynamic>();
    return UyeTalep(
      id: _int(j['id']),
      tur: _str(j['tur']),
      turAdi: _str(j['tur_adi']),
      durum: _str(j['durum']),
      uyeDurum: _str(j['uye_durum']),
      durumMetni: _str(j['durum_metni']),
      uyeId: _int(j['uye_id']),
      uyeAdi: _str(j['uye_adi']),
      antrenorId: _intN(j['antrenor_id']),
      antrenorAdi: _str(j['antrenor_adi']),
      kortId: _intN(j['kort_id']),
      kortAdi: _str(j['kort_adi']),
      baslangic: parseApiTarihOrNow(j['baslangic_tarih_saat']),
      bitis: parseApiTarihOrNow(j['bitis_tarih_saat']),
      sureDk: _int(j['sure_dk'], 60),
      dersTanimi: _str(j['ders_tanimi']),
      esneme: _bool(j['esneme']),
      kisiSayisi: _intN(j['kisi_sayisi']),
      aciklama: _str(j['aciklama']),
      ozet: _str(j['ozet']),
      paketYetmiyor: _bool(j['paket_yetmiyor']),
      redNedeni: _str(j['red_nedeni']),
      oneri: TalepOnerisi.fromJsonN(j['oneri']),
      dersAciklamasi: _str(ders?['ders_tanimi']) +
          (_str(ders?['antrenor_adi']).isEmpty
              ? ''
              : ' · ${_str(ders?['antrenor_adi'])}'),
      dersIptal: _bool(ders?['iptal_mi']),
      dersDegisenler: _metinler(ders?['degisenler']),
      olusturulma: parseApiTarih(j['olusturulma_zamani']),
      geriCekilebilir: _bool(j['geri_cekilebilir']),
      duzenlenebilir: _bool(j['duzenlenebilir']),
    );
  }

  bool get cevapBekliyor => uyeDurum == 'CEVAP_BEKLIYOR';
  bool get acik => uyeDurum == 'OFISTE' || uyeDurum == 'CEVAP_BEKLIYOR';
}

/// Sihirbazın taşıdığı seçimler (Düzenle / Benzerini aç ile dolu açılır).
class TalepTaslagi {
  String? tur;
  int? uyeId;
  int sureDk;
  int? antrenorId;
  int? kortId;
  DateTime? baslangic;
  bool esneme;
  int kisiSayisi;
  String aciklama;

  /// Düzenle: eski talep yenisi açılırken geri çekilir.
  int? degistirilenTalepId;

  TalepTaslagi({
    this.tur,
    this.uyeId,
    this.sureDk = 60,
    this.antrenorId,
    this.kortId,
    this.baslangic,
    this.esneme = false,
    this.kisiSayisi = 1,
    this.aciklama = '',
    this.degistirilenTalepId,
  });

  factory TalepTaslagi.talepten(UyeTalep t, {required bool duzenle}) =>
      TalepTaslagi(
        tur: t.tur,
        uyeId: t.uyeId,
        sureDk: t.sureDk,
        antrenorId: t.antrenorId,
        kortId: t.kortId,
        baslangic: duzenle ? t.baslangic : null,
        esneme: t.esneme,
        kisiSayisi: t.kisiSayisi ?? 1,
        aciklama: t.aciklama,
        degistirilenTalepId: duzenle ? t.id : null,
      );

  Map<String, dynamic> govde() => {
        'uye_id': uyeId,
        'tur': tur,
        'baslangic_tarih_saat':
            baslangic == null ? null : formatApiTarih(baslangic!),
        'sure_dk': sureDk,
        'antrenor_id': antrenorId,
        'kort_id': kortId,
        'esneme': esneme,
        if (tur == TalepTuru.kort) 'kisi_sayisi': kisiSayisi,
        'aciklama': aciklama,
        if (degistirilenTalepId != null)
          'degistirilen_talep_id': degistirilenTalepId,
      };
}
