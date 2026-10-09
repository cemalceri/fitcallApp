// lib/screens/1_common/duyurular/widgets/duyuru_bicim.dart
//
// Duyurular ekranlarının ortak metin biçimleri.

import 'package:fitcall/models/1_common/duyuru_okuma_models.dart';
import 'package:intl/intl.dart';

final DateFormat _gunAy = DateFormat('d MMM', 'tr_TR');
final DateFormat _saat = DateFormat('HH:mm', 'tr_TR');

String gunAy(DateTime t) => _gunAy.format(t);
String saatDakika(DateTime t) => _saat.format(t);

/// "3–17 Eki", "28 Eyl – 5 Eki", "3 Eki – süresiz".
String yayinAraligi(DateTime bas, DateTime? bit) {
  if (bit == null) return '${gunAy(bas)} – süresiz';
  if (bas.year == bit.year && bas.month == bit.month) {
    if (bas.day == bit.day) return gunAy(bas);
    return '${bas.day}–${gunAy(bit)}';
  }
  return '${gunAy(bas)} – ${gunAy(bit)}';
}

/// "%38". Sıfırdan büyük ama yuvarlanınca sıfıra inen oran "<%1".
String oranMetni(double oran) {
  final yuzde = (oran * 100).round();
  if (yuzde == 0 && oran > 0) return '<%1';
  return '%$yuzde';
}

/// Liste ve özet kartındaki alt satır: "Pasif · Üyeler · 3–17 Eki · Popup · Önemli".
String duyuruAltSatiri({
  required String hedefKitle,
  required DateTime yayinBaslangic,
  DateTime? yayinBitis,
  bool aktifMi = true,
  bool popupGoster = false,
  bool onemliMi = false,
}) =>
    [
      if (!aktifMi) 'Pasif',
      hedefKitleKisa(hedefKitle),
      yayinAraligi(yayinBaslangic, yayinBitis),
      if (popupGoster) 'Popup',
      if (onemliMi) 'Önemli',
    ].join(' · ');

/// Gören satırının alt metni. Ana sayfa şeridi kaydı yalnız detay açılınca
/// yazıldığı için orada "açtı", popup'ta "gördü" denir.
String gormeSekli(GorenHesap h) {
  if (h.kaynak == 'popup') {
    return h.detayAcildi ? "Popup'ta gördü · Detayı açtı" : "Popup'ta gördü";
  }
  return 'Ana sayfadan açtı';
}

/// "Üye", "Antrenör", "Üye · Antrenör".
String rolEtiketleri(DuyuruHesabi h) {
  final roller = <String>{
    for (final p in h.profiller)
      if (p.rol == 'uye')
        'Üye'
      else if (p.rol == 'antrenor')
        'Antrenör',
  };
  return roller.isEmpty ? 'Profil yok' : roller.join(' · ');
}

/// Türkçe büyük/küçük harf duyarsız arama için ("İ"→"i", "I"→"ı").
String aramaBicimi(String s) =>
    s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase().trim();
