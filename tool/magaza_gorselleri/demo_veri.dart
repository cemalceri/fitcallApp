// Mağaza görsellerinin demo dünyası: uydurma kişiler, kortlar, dersler.
//
// Gerçek üye adı / fotoğrafı kullanılmaz (KVKK). Tarihler çalıştırma gününe
// göre kurulur; görseller hangi gün üretilirse üretilsin "bu hafta" görünür.

DateTime get bugun {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Haftanın pazartesisi.
DateTime get haftaBasi => bugun.subtract(Duration(days: bugun.weekday - 1));

DateTime gunSaat(int gunFarki, int saat, [int dakika = 0]) =>
    bugun.add(Duration(days: gunFarki, hours: saat, minutes: dakika));

/// Backend biçimi: ofsetli yerel saat ("2026-07-23T10:00:00+03:00").
String apiTarih(DateTime d) =>
    '${d.toIso8601String().split('.').first}+03:00';

String apiGun(DateTime d) => d.toIso8601String().split('T').first;

class DemoKisi {
  final int id;
  final String adi;
  final String soyadi;
  const DemoKisi(this.id, this.adi, this.soyadi);
  String get adSoyad => '$adi $soyadi';
  Map<String, Object?> get lite => {'id': id, 'adi': adi, 'soyadi': soyadi};
}

const uye = DemoKisi(101, 'Deniz', 'Yılmaz');
const uyeler = [
  DemoKisi(102, 'Ece', 'Şahin'),
  DemoKisi(103, 'Can', 'Öztürk'),
  DemoKisi(104, 'Zeynep', 'Arslan'),
  DemoKisi(105, 'Mert', 'Çelik'),
  DemoKisi(106, 'Elif', 'Koç'),
  DemoKisi(107, 'Ali', 'Doğan'),
  DemoKisi(108, 'Defne', 'Kurt'),
  DemoKisi(109, 'Kerem', 'Aksoy'),
  DemoKisi(110, 'Ada', 'Polat'),
  DemoKisi(111, 'Emir', 'Yıldız'),
];

const antrenor = DemoKisi(201, 'Emre', 'Kaya');
const antrenorler = [
  antrenor,
  DemoKisi(202, 'Selin', 'Aydın'),
  DemoKisi(203, 'Burak', 'Demir'),
];

const kortlar = {1: 'Merkez Kort', 2: 'Kort 2', 3: 'Kapalı Kort'};

int _etkinlikId = 3000;

/// Bir ders kaydı (EtkinlikModel.fromMap biçiminde).
Map<String, Object?> ders({
  required DateTime baslangic,
  int dakika = 60,
  int kort = 1,
  DemoKisi hoca = antrenor,
  List<DemoKisi> katilimcilar = const [uye],
  String seviye = 'Orta',
  String urun = 'Yetişkin Grup',
  bool iptal = false,
  int? id,
}) {
  return {
    'id': id ?? _etkinlikId++,
    'kort': kort,
    'kort_adi': kortlar[kort],
    'baslangic_tarih_saat': apiTarih(baslangic),
    'bitis_tarih_saat': apiTarih(baslangic.add(Duration(minutes: dakika))),
    'seviye': seviye,
    'iptal_mi': iptal,
    'is_active': true,
    'is_deleted': false,
    'olusturulma_zamani': apiTarih(bugun.subtract(const Duration(days: 20))),
    'guncellenme_zamani': apiTarih(bugun.subtract(const Duration(days: 2))),
    'urun': 1,
    'urun_adi': urun,
    'antrenor': hoca.id,
    'antrenor_adi': hoca.adSoyad,
    'isletme': 1,
    'uyeler': [for (final k in katilimcilar) k.lite],
  };
}
