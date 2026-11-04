// lib/screens/1_common/ogrenme/hedefler.dart
//
// `OgrenmeHedefi` kimlikleri. Ekran da rehber de aynı sabiti kullanır; yazım
// hatası derlemede yakalanır.

abstract final class Hedef {
  /// Hafta şeridinde dersi olan, bugün ya da sonraki bir gün.
  static const takvimDersliGun = 'takvim.dersliGun';

  /// Takvimdeki gelecek, iptal edilmemiş ders bloğu.
  static const takvimDers = 'takvim.ders';

  /// Ders detayındaki "katılamayacağım" açıklama kutusu.
  static const takvimAciklama = 'takvim.aciklama';

  /// Ortak yükleme göstergesi: ekranda varken "Oku" yerine "Yükleniyor".
  static const yukleniyor = 'yukleniyor';
}
