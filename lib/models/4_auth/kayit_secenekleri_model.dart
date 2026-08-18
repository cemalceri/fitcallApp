// lib/models/4_auth/kayit_secenekleri_model.dart
//
// Üyelik başvuru formunun açılır liste verileri (getKayitFormVerileri).
//
// Seçenekler backend'de web formundan okunuyor; mobil sabit liste tutmuyor ki
// web'e eklenen bir kulüp/okul/program tercihi burada da görünsün.

class Secenek {
  /// API'ye gönderilecek değer (işletme/okul için id, diğerleri için etiketin
  /// kendisi — backend'in choice değerleri Türkçe metin).
  final String deger;

  /// Kullanıcıya gösterilen metin.
  final String etiket;

  const Secenek({required this.deger, required this.etiket});

  factory Secenek.fromJson(Map<String, dynamic> j) => Secenek(
        deger: (j['deger'] ?? j['id'] ?? '').toString(),
        etiket: (j['etiket'] ?? j['adi'] ?? '').toString(),
      );
}

class KayitSecenekleri {
  final List<Secenek> isletmeler;
  final List<Secenek> okullar;
  final List<Secenek> cinsiyetler;
  final List<Secenek> tenisGecmisi;
  final List<Secenek> programTercihleri;

  const KayitSecenekleri({
    required this.isletmeler,
    required this.okullar,
    required this.cinsiyetler,
    required this.tenisGecmisi,
    required this.programTercihleri,
  });

  static List<Secenek> _liste(dynamic ham) => (ham as List? ?? const [])
      .map((e) => Secenek.fromJson((e as Map).cast<String, dynamic>()))
      .toList();

  factory KayitSecenekleri.fromJson(Map<String, dynamic> j) => KayitSecenekleri(
        isletmeler: _liste(j['isletmeler']),
        okullar: _liste(j['okullar']),
        cinsiyetler: _liste(j['cinsiyetler']),
        tenisGecmisi: _liste(j['tenis_gecmisi']),
        programTercihleri: _liste(j['program_tercihleri']),
      );
}
