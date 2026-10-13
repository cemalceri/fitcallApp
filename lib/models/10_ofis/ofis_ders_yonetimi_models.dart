// lib/models/10_ofis/ofis_ders_yonetimi_models.dart
//
// Ofis Ana Sayfa (bekleyen işler), Dersler (web Ders Yönetimi'nin mobil
// karşılığı) ve plan dışı kararlar. Uçlar: api/ofis/ders_yonetimi.py.

import 'package:fitcall/common/tarih_util.dart';

int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
bool? _bool(dynamic v) => v is bool ? v : null;
String? _metin(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/* ============================== Ana Sayfa ============================== */

class OnayBekleyenGun {
  final DateTime tarih;
  final int bekleyen;

  /// Antrenörün "yapıldı" dediği, yönetici kararı bekleyen ders sayısı.
  final int antrenorOnayli;

  const OnayBekleyenGun({
    required this.tarih,
    required this.bekleyen,
    required this.antrenorOnayli,
  });

  factory OnayBekleyenGun.fromJson(Map<String, dynamic> j) => OnayBekleyenGun(
        tarih: parseApiGun(j['tarih']) ?? simdiKulup(),
        bekleyen: _int(j['bekleyen']),
        antrenorOnayli: _int(j['antrenor_onayli']),
      );
}

class OfisBekleyenIsler {
  final int bugunDers;
  final int bugunIptal;
  final int bugunOnayBekleyen;
  final int onayBekleyen;
  final int onayBekleyenAntrenorOnayli;
  final int pencereGun;
  final List<OnayBekleyenGun> onayGunleri;
  final int planDisiKisi;
  final int planDisiDers;
  final int teyitKisi;
  final int teyitDers;

  /// Cevap bekleyen katılımcıların günlere dağılımı (bugün, yarın).
  final List<(DateTime, int)> teyitGunleri;

  const OfisBekleyenIsler({
    required this.bugunDers,
    required this.bugunIptal,
    required this.bugunOnayBekleyen,
    required this.onayBekleyen,
    required this.onayBekleyenAntrenorOnayli,
    required this.pencereGun,
    required this.onayGunleri,
    required this.planDisiKisi,
    required this.planDisiDers,
    required this.teyitKisi,
    required this.teyitDers,
    this.teyitGunleri = const [],
  });

  /// Katılım cevabı beklenen ilk gün (yoksa bugün).
  DateTime get ilkTeyitGunu => teyitGunleri.isEmpty
      ? bugunKulup()
      : teyitGunleri.first.$1;

  bool get isYok => onayBekleyen == 0 && planDisiKisi == 0 && teyitKisi == 0;

  factory OfisBekleyenIsler.fromJson(Map<String, dynamic> j) {
    final bugun = Map<String, dynamic>.from(j['bugun'] as Map? ?? {});
    final onay = Map<String, dynamic>.from(j['onay_bekleyen'] as Map? ?? {});
    final plan = Map<String, dynamic>.from(j['plan_disi_bekleyen'] as Map? ?? {});
    final teyit = Map<String, dynamic>.from(j['teyit_bekleyen'] as Map? ?? {});
    return OfisBekleyenIsler(
      bugunDers: _int(bugun['ders']),
      bugunIptal: _int(bugun['iptal']),
      bugunOnayBekleyen: _int(bugun['onay_bekleyen']),
      onayBekleyen: _int(onay['toplam']),
      onayBekleyenAntrenorOnayli: _int(onay['antrenor_onayli']),
      pencereGun: _int(onay['pencere_gun']),
      onayGunleri: (onay['gunler'] as List? ?? [])
          .map((e) => OnayBekleyenGun.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      planDisiKisi: _int(plan['kisi']),
      planDisiDers: _int(plan['ders']),
      teyitKisi: _int(teyit['kisi']),
      teyitDers: _int(teyit['ders']),
      teyitGunleri: (teyit['gunler'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((m) => (parseApiGun(m['tarih']) ?? bugunKulup(), _int(m['kisi'])))
          .toList(),
    );
  }
}

/* ============================== Gün verisi ============================== */

/// Katılımcının katılım bildirimi (teyit) durumu.
enum TeyitDurumu { katilacak, katilmayacak, bekliyor, bildirimYok, yok }

TeyitDurumu _teyit(dynamic v) => switch (v) {
      'katilacak' => TeyitDurumu.katilacak,
      'katilmayacak' => TeyitDurumu.katilmayacak,
      'bekliyor' => TeyitDurumu.bekliyor,
      'bildirim_yok' => TeyitDurumu.bildirimYok,
      _ => TeyitDurumu.yok,
    };

/// Geçmiş paket dersinde katılımcının paket düşümü: düşülebilir, geri
/// alınabilir ya da düşüm kaydı yok.
enum PaketDusumu { dus, geriAl, yok }

class YonetimKatilimci {
  final int uyeId;
  final String adSoyad;
  final TeyitDurumu teyit;
  final String? teyitAciklama;
  final String? teyitEden;

  /// Antrenör yoklaması: true katıldı, false katılmadı, null girilmedi.
  final bool? katildi;
  final bool planDisiMi;
  final PaketDusumu paketDusumu;

  const YonetimKatilimci({
    required this.uyeId,
    required this.adSoyad,
    required this.teyit,
    this.teyitAciklama,
    this.teyitEden,
    this.katildi,
    this.planDisiMi = false,
    this.paketDusumu = PaketDusumu.yok,
  });

  factory YonetimKatilimci.fromJson(Map<String, dynamic> j) => YonetimKatilimci(
        uyeId: _int(j['uye_id']),
        adSoyad: _metin(j['ad_soyad']) ?? '-',
        teyit: _teyit(j['teyit_durum']),
        teyitAciklama: _metin(j['teyit_aciklama']),
        teyitEden: _metin(j['teyit_eden']),
        katildi: switch (j['katilim_durum']) {
          'katildi' => true,
          'katilmadi' => false,
          _ => null,
        },
        planDisiMi: j['plan_disi_mi'] == true,
        paketDusumu: switch (j['paket_dusum_btn']) {
          'dus' => PaketDusumu.dus,
          'geri_al' => PaketDusumu.geriAl,
          _ => PaketDusumu.yok,
        },
      );
}

/// Dersin bağlamı: web'deki gibi gelecek / geçmiş / iptal.
enum DersBaglami { gelecek, gecmis, iptal }

class YonetimDersi {
  final int id;
  final DersBaglami baglam;
  final String kortAdi;
  final DateTime baslangic;
  final DateTime bitis;
  final String? urunAdi;
  final String? antrenor;
  final String? yardimciAntrenor;

  final String? iptalSebebi;
  final String? iptalAciklamasi;
  final String? iptalEden;

  /// Yönetici kararı: true yapıldı, false yapılmadı, null bekliyor.
  final bool? yoneticiKarari;
  final String? yoneticiNeden;
  final String? yoneticiOnaylayan;

  /// Antrenörün bildirimi: true yapıldı, false yapılmadı, null bildirmedi.
  final bool? antrenorKarari;
  final String? antrenorNeden;

  final bool? hakedis;
  final bool? yardimciHakedis;
  final List<YonetimKatilimci> katilimcilar;

  /// Karar bekleyen plan dışı / misafir kişi sayısı.
  final int planDisiBekleyen;

  const YonetimDersi({
    required this.id,
    required this.baglam,
    required this.kortAdi,
    required this.baslangic,
    required this.bitis,
    this.urunAdi,
    this.antrenor,
    this.yardimciAntrenor,
    this.iptalSebebi,
    this.iptalAciklamasi,
    this.iptalEden,
    this.yoneticiKarari,
    this.yoneticiNeden,
    this.yoneticiOnaylayan,
    this.antrenorKarari,
    this.antrenorNeden,
    this.hakedis,
    this.yardimciHakedis,
    this.katilimcilar = const [],
    this.planDisiBekleyen = 0,
  });

  bool get iptalMi => baglam == DersBaglami.iptal;
  bool get gecmisMi => baglam == DersBaglami.gecmis;
  bool get gelecekMi => baglam == DersBaglami.gelecek;

  /// Ders bitti mi — istemci saatiyle. `baglam` sunucunun İSTEK ANINDAKİ
  /// değerlendirmesi, sayfa açık kaldıkça bayatlıyor. Satır etiketi/sayaçları
  /// istemci saatini, onay arayüzü `baglam`ı kullandığı için ders sayfa
  /// açıkken bitince satır "Onay bekliyor" derken sheet'te Yapıldı/Yapılmadı
  /// düğmeleri hiç çizilmiyordu. Onay ve hakediş artık buradan geçiyor.
  bool get bittiMi => !bitis.isAfter(simdiKulup());

  /// Ders henüz başlamadı. Katılım teyidi ("Katılacak") ve hatırlatma yalnız
  /// bu durumda anlamlı — sunucu da `baslangic > now` istiyor
  /// (api/ofis/ders_yonetimi.py). `gelecekMi` yerine bu kullanılıyor: ders
  /// sayfa açıkken başlayınca bayat `baglam` hâlâ "Hatırlat" gösteriyor,
  /// dokununca sunucu 400 veriyordu.
  bool get baslamadiMi => baslangic.isAfter(simdiKulup());

  /// Yönetici onayı / hakediş kararı verilebilir: iptal değil ve bitmiş.
  /// (Sunucu da aynı kapıyı uyguluyor: api/ofis/ders_yonetimi.py)
  bool get kararVerilebilir => !iptalMi && bittiMi;

  /// Ders bitmiş ama yönetici kararı yok.
  bool get onayBekliyor => kararVerilebilir && yoneticiKarari == null;

  /// Toplu onaya uygun: antrenör "yapıldı" demiş, yönetici karar vermemiş.
  bool get topluOnaylanabilir => onayBekliyor && antrenorKarari == true;

  /// Katılım bildirimine cevap vermemiş katılımcılar (henüz başlamamış ders).
  int get cevapsiz => baslamadiMi
      ? katilimcilar
          .where((k) =>
              !k.planDisiMi &&
              (k.teyit == TeyitDurumu.bekliyor ||
                  k.teyit == TeyitDurumu.bildirimYok))
          .length
      : 0;

  factory YonetimDersi.fromJson(Map<String, dynamic> j) {
    final baslangic = parseApiTarihOrNow(j['baslangic']);
    return YonetimDersi(
      id: _int(j['id']),
      baglam: switch (j['baglam']) {
        'iptal' => DersBaglami.iptal,
        'gelecek' => DersBaglami.gelecek,
        _ => DersBaglami.gecmis,
      },
      kortAdi: _metin(j['kort_adi']) ?? '-',
      baslangic: baslangic,
      bitis: parseApiTarih(j['bitis']) ?? baslangic,
      urunAdi: _metin(j['urun_adi']),
      antrenor: _metin(j['antrenor']),
      yardimciAntrenor: _metin(j['yardimci_antrenor']),
      iptalSebebi: _metin(j['iptal_sebebi']),
      iptalAciklamasi: _metin(j['iptal_aciklamasi']),
      iptalEden: _metin(j['iptal_eden']),
      yoneticiKarari: _bool(j['yonetici_tamamlandi']),
      yoneticiNeden: _metin(j['yonetici_neden']),
      yoneticiOnaylayan: _metin(j['yonetici_onaylayan']),
      antrenorKarari: _bool(j['antrenor_tamamlandi']),
      antrenorNeden: _metin(j['antrenor_neden']),
      hakedis: _bool(j['hakedis']),
      yardimciHakedis: _bool(j['yardimci_hakedis']),
      katilimcilar: (j['katilimcilar'] as List? ?? [])
          .map((e) => YonetimKatilimci.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      planDisiBekleyen: _int(j['plan_disi_bekleyen']),
    );
  }
}

class YapilmadiNedeni {
  final String kod;
  final String etiket;
  const YapilmadiNedeni(this.kod, this.etiket);
}

class DersYonetimiGun {
  final DateTime tarih;
  final List<YonetimDersi> dersler;
  final List<YapilmadiNedeni> yapilmadiNedenleri;

  const DersYonetimiGun({
    required this.tarih,
    required this.dersler,
    this.yapilmadiNedenleri = const [],
  });

  int get onayBekleyen => dersler.where((d) => d.onayBekliyor).length;
  int get topluOnaylanabilir =>
      dersler.where((d) => d.topluOnaylanabilir).length;
  int get cevapsiz => dersler.fold(0, (t, d) => t + d.cevapsiz);
  int get iptal => dersler.where((d) => d.iptalMi).length;

  factory DersYonetimiGun.fromJson(Map<String, dynamic> j) => DersYonetimiGun(
        tarih: parseApiGun(j['tarih']) ?? simdiKulup(),
        dersler: (j['dersler'] as List? ?? [])
            .map((e) => YonetimDersi.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        yapilmadiNedenleri: (j['yapilmadi_nedenleri'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .map((m) => YapilmadiNedeni(
                m['kod']?.toString() ?? '', m['etiket']?.toString() ?? ''))
            .toList(),
      );
}

/* ============================ Plan dışı kararlar ============================ */

class PlanDisiKisi {
  /// 'uye' (plan dışı katılan üye) ya da 'misafir'.
  final String tur;
  final int id;
  final String adSoyad;
  final String? notMetni;

  const PlanDisiKisi({
    required this.tur,
    required this.id,
    required this.adSoyad,
    this.notMetni,
  });

  bool get misafirMi => tur == 'misafir';

  /// Karar ucunun beklediği anahtar: "misafir:12".
  String get anahtar => '$tur:$id';

  factory PlanDisiKisi.fromJson(Map<String, dynamic> j) => PlanDisiKisi(
        tur: j['tur']?.toString() ?? 'uye',
        id: _int(j['id']),
        adSoyad: _metin(j['ad_soyad']) ?? '-',
        notMetni: _metin(j['not_metni']),
      );
}

class PlanDisiDers {
  final int etkinlikId;
  final DateTime baslangic;
  final String kort;
  final String antrenor;
  final String urun;
  final List<PlanDisiKisi> kisiler;

  const PlanDisiDers({
    required this.etkinlikId,
    required this.baslangic,
    required this.kort,
    required this.antrenor,
    required this.urun,
    required this.kisiler,
  });

  factory PlanDisiDers.fromJson(Map<String, dynamic> j) => PlanDisiDers(
        etkinlikId: _int(j['etkinlik_id']),
        baslangic: parseApiTarihOrNow(j['baslangic']),
        kort: _metin(j['kort']) ?? '-',
        antrenor: _metin(j['antrenor']) ?? '-',
        urun: _metin(j['urun']) ?? '-',
        kisiler: (j['kisiler'] as List? ?? [])
            .map((e) => PlanDisiKisi.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class PlanDisiPaket {
  final int id;
  final String etiket;
  const PlanDisiPaket({required this.id, required this.etiket});
}

class PlanDisiAday {
  final int uyeId;
  final String adSoyad;
  final bool varsayilan;
  final List<PlanDisiPaket> paketler;

  const PlanDisiAday({
    required this.uyeId,
    required this.adSoyad,
    required this.varsayilan,
    this.paketler = const [],
  });

  factory PlanDisiAday.fromJson(Map<String, dynamic> j) => PlanDisiAday(
        uyeId: _int(j['uye_id']),
        adSoyad: _metin(j['ad_soyad']) ?? '-',
        varsayilan: j['varsayilan'] == true,
        paketler: (j['paketler'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .map((m) => PlanDisiPaket(
                  id: _int(m['id']),
                  etiket: _metin(m['etiket']) ?? _metin(m['ad']) ?? '-',
                ))
            .toList(),
      );
}

class PlanDisiSecenekler {
  final String kisi;
  final List<PlanDisiAday> adaylar;

  const PlanDisiSecenekler({required this.kisi, required this.adaylar});

  factory PlanDisiSecenekler.fromJson(Map<String, dynamic> j) =>
      PlanDisiSecenekler(
        kisi: _metin(j['kisi']) ?? '-',
        adaylar: (j['adaylar'] as List? ?? [])
            .map((e) => PlanDisiAday.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
