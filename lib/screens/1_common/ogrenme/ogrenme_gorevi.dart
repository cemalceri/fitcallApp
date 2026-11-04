// lib/screens/1_common/ogrenme/ogrenme_gorevi.dart
//
// "?" rehberinin veri modeli. Rehberler sabit veridir (gorevler.dart);
// ekranlar rehberden habersizdir. Bir adımın hedefi ya ekrandaki buton
// yazısıyla ([Secici.metin]) ya da yazısı olmayan öğeye sarılan
// [OgrenmeHedefi] kimliğiyle ([Secici.hedef]) bulunur.

/// Rehberi olan sayfalar. "?" butonu hangi listeyi açacağını buradan bilir.
enum OgrenmeSayfasi {
  uyeTakvim('Takvime dön');

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

  /// Okuma adımı: hedef parlar, kullanıcı ona dokunup yazabilir; adım
  /// «Anladım» ile geçilir.
  final bool bilgi;

  const OgrenmeAdimi({
    required this.hedef,
    required this.metin,
    this.kalici = false,
    this.sonuc,
    this.atlanabilir = false,
    this.bilgi = false,
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

  const OgrenmeGorevi({
    required this.id,
    required this.sayfa,
    required this.baslik,
    required this.kosulMetni,
    required this.adimlar,
    this.kural,
  });
}
