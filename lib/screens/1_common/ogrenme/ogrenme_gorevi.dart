// lib/screens/1_common/ogrenme/ogrenme_gorevi.dart
//
// "?" rehberinin veri modeli. Rehberler sabit veridir (gorevler.dart);
// ekranlar rehberden habersizdir. Bir adımın hedefi ya ekrandaki buton
// yazısıyla ([Secici.metin]) ya da yazısı olmayan öğeye sarılan
// [OgrenmeHedefi] kimliğiyle ([Secici.hedef]) bulunur.

import 'package:fitcall/common/constants.dart';

/// Rehberi olan sayfalar. "?" butonu hangi listeyi açacağını buradan bilir.
enum OgrenmeSayfasi {
  uyeAnaSayfa('Ana sayfaya dön'),
  uyeTakvim('Takvime dön'),
  uyeHareketler('Hareketlere dön'),
  uyeHavale('Ödeme sayfasına dön'),
  uyeUrunler('Paketlere dön'),
  uyeTelafi('Telafi derslerine dön'),
  uyeGecmisDersler('Geçmiş derslere dön'),
  uyeProfil('Hesabıma dön'),
  uyeTeyit('Katılım sayfasına dön'),
  uyeEvent('Davet sayfasına dön'),
  uyeTaleplerim('Taleplerime dön'),

  /// Bütün rollerde aynı sayfalar; rol bağımlı rehberde `roller` verilir.
  qrOlustur('QR ekranına dön'),
  bildirimler('Bildirimlere dön'),
  ayarlar('Ayarlara dön'),

  /// Ofis ve yönetici ortak.
  duyurular('Duyurulara dön'),
  antrenorAnaSayfa('Ana sayfaya dön'),
  antrenorTakvim('Takvime dön'),
  antrenorEksikYoklama('Eksik yoklamalara dön'),
  antrenorProgram('Programa dön'),
  antrenorHakedis('Hakediş saatlerine dön'),
  antrenorCalismaSaatleri('Çalışma saatlerine dön'),
  antrenorOgrenciler('Öğrencilerime dön'),
  ofisAnaSayfa('Ana sayfaya dön'),
  ofisProgram('Programa dön'),
  ofisDersler('Derslere dön'),
  ofisDersKayitTalepleri('Taleplere dön'),
  ofisPlanDisi('Kararlara dön'),
  ofisUyeler('Üyelere dön'),
  qrDogrula('QR doğrulamaya dön'),
  yoneticiAnaSayfa('Ana sayfaya dön'),
  yoneticiRaporlar('Raporlara dön'),
  yoneticiUyeler('Üyelere dön'),
  yoneticiUyeDetay('Üye detayına dön'),
  yoneticiAntrenorler('Antrenörlere dön'),
  yoneticiDersler('Derslere dön'),
  yoneticiDegerlendirmeler('Değerlendirmelere dön'),
  yoneticiHakedis('Hakediş saatlerine dön'),
  yoneticiEkip('Ekibe dön'),
  yoneticiDekontlar('Ödemelere dön');

  /// Bitişte rehberin başladığı sayfaya dönen butonun adı. Yönelme eki
  /// sayfa adından güvenle üretilemediği için elle yazılır.
  final String donusEtiketi;

  const OgrenmeSayfasi(this.donusEtiketi);
}

/// Adımın ekrandaki hedefi.
sealed class Secici {
  const Secici();

  /// Yazısı olmayan ya da yazısı veriden gelen öğe (ders bloğu, satır):
  /// ekranda `OgrenmeHedefi(id: …)` ile sarılır.
  const factory Secici.hedef(String id) = HedefSecici;

  /// Ekrandaki buton yazısı. Yazının en yakın dokunulabilir atası hedeftir.
  const factory Secici.metin(String metin) = MetinSecici;
}

class HedefSecici extends Secici {
  final String id;
  const HedefSecici(this.id);
}

class MetinSecici extends Secici {
  final String metin;
  const MetinSecici(this.metin);
}

class OgrenmeAdimi {
  final Secici hedef;

  /// Tek cümle, en çok 8 kelime. Ekrandaki buton adı «…» içinde yazılır;
  /// ekranda tırnakla ve kalın gösterilir.
  final String metin;

  /// Kalıcı son adım: buton gösterilir ama basılamaz.
  final bool kalici;

  /// Kalıcı adımda butona basılınca ne olacağı, küçük harfle
  /// ("ofise ve hocana haber gider").
  final String? sonuc;

  /// Sonraki adımın hedefi zaten ekrandaysa bu adım atlanır (ör. seçili
  /// günde ders varken "Dersi olan bir güne dokun").
  final bool atlanabilir;

  /// Okuma adımı: hedef parlar, adım «Anladım» ile geçilir.
  final bool bilgi;

  /// Okuma adımında parlayan yere dokunulabilir mi (yazı alanı, seçim).
  /// Varsayılan kapalı: parlayan kart sekme değiştiriyor ya da sayfa
  /// açıyorsa dokunuş rehberi yolundan çıkarmasın.
  final bool dokunulur;

  /// Okuma adımında «Anladım»a basıldı ama sonraki adımın hedefi ekranda
  /// yok: adım geçmez, balonda bu yazı çıkar (ör. seçili günde uygun ders
  /// yok). Verilmezse dokunulur adımda [varsayilanYoksa], yalnız okunan
  /// adımda [varsayilanYoksaOkuma] (orada seçilecek bir şey yok).
  final String? yoksa;

  static const varsayilanYoksa = 'Önce parlayan yerde seçimini yap.';
  static const varsayilanYoksaOkuma =
      'Burada gösterecek bir şey yok; «Kapat»a dokun.';

  /// Sonraki hedef yokken balonda çıkan yazı.
  String get yoksaMetni =>
      yoksa ?? (dokunulur ? varsayilanYoksa : varsayilanYoksaOkuma);

  const OgrenmeAdimi({
    required this.hedef,
    required this.metin,
    this.kalici = false,
    this.sonuc,
    this.atlanabilir = false,
    this.bilgi = false,
    this.dokunulur = false,
    this.yoksa,
  });
}

class OgrenmeGorevi {
  final String id;
  final OgrenmeSayfasi sayfa;

  /// Kullanıcının soracağı soru ("Derse gelemeyeceğimi nasıl bildiririm?").
  final String baslik;

  /// Veri yokken satırda ve okuma ekranında kullanılan koşul
  /// ("Takviminde ders olunca" → "… deneyebilirsin.").
  final String kosulMetni;

  final List<OgrenmeAdimi> adimlar;

  /// Bitişte gösterilen kural, en çok 3 kısa cümle; Sık sorulanlar'daki
  /// cevapla ve ekrandaki bilgi notuyla çelişmemeli.
  final String? kural;

  /// Rollerle ortak sayfada (Bildirimler, Ayarlar) yalnız bu rollere
  /// gösterilir; boşsa herkese.
  final Set<Roller> roller;

  const OgrenmeGorevi({
    required this.id,
    required this.sayfa,
    required this.baslik,
    required this.kosulMetni,
    required this.adimlar,
    this.kural,
    this.roller = const {},
  });

  /// [rol] (profilin rol adı) bu rehberi görür mü?
  bool rolde(String? rol) => roller.isEmpty || roller.any((r) => r.name == rol);
}
