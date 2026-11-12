// lib/screens/1_common/widgets/sekme_gecmisi.dart
//
// Kabukların (üye, antrenör, ofis, yönetici) alt sekmeleri için geri tuşu
// geçmişi. Kural: geri tuşu her zaman bir önceki sayfaya döner; önceki yoksa
// uygulama kapanır.
//
// Sekme geçişi Navigator'a sayfa eklemez (IndexedStack), bu yüzden geri tuşu
// eskiden ya uygulamayı kapatıyordu (yönetici: ana sayfadaki karttan Dersler'e
// geçip geri basınca) ya da hep Ana Sayfa'ya atlıyordu. Navigator'a itilen
// sayfalar (detaylar) zaten kendi geri davranışıyla kapanır; bu sınıf yalnız
// sekmeler arasındaki adımları tutar.

/// Sekme geçmişi yığını. Aynı sekme yığında bir kez durur (en son ziyaret
/// edildiği yerde), böylece yığın sekme sayısını aşmaz.
class SekmeGecmisi {
  final List<int> _yigin = [];

  /// [eski] sekmeden [yeni] sekmeye geçerken çağrılır.
  void kaydet(int eski, int yeni) {
    if (eski == yeni) return;
    _yigin
      ..remove(eski)
      ..remove(yeni)
      ..add(eski);
  }

  bool get bos => _yigin.isEmpty;

  /// Geri tuşunda dönülecek sekme; geçmiş boşsa null.
  int? geriAl() => _yigin.isEmpty ? null : _yigin.removeLast();

  /// Geri tuşu uygulamayı kapatabilir mi: geçmiş boş ve Ana Sayfa'dayız.
  /// Geçmiş boşken başka sekmedeysek geri tuşu önce Ana Sayfa'ya döner.
  bool kapatabilir(int aktif, {int anaSayfa = 0}) => bos && aktif == anaSayfa;

  /// Geri tuşunda gidilecek sekme: geçmişin sonu, yoksa Ana Sayfa.
  int geriHedefi({int anaSayfa = 0}) => geriAl() ?? anaSayfa;
}
