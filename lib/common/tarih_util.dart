// lib/common/tarih_util.dart
//
// API ile tarih/saat alışverişinin TEK standardı.
// Backend karşılığı: api/core/tarih.py + calendarapp/utils/tarih_util.py
//
// OKUMA (backend -> mobil)
//   Backend datetime alanlarını yerel saatte (Europe/Istanbul) offset'li ISO-8601
//   döner: "2026-07-23T10:00:00+03:00".
//   Dart'ta DateTime.parse offset gördüğünde değeri UTC'ye çevirip isUtc=true
//   yapar; .hour ve DateFormat o durumda UTC saatini verir (10:00 -> "07:00").
//   Bu yüzden gelen her değer parseApiTarih() ile okunmalı; fonksiyon .toLocal()
//   uygulayarak duvar saatini geri getirir.
//
// YAZMA (mobil -> backend)
//   Offset'siz "naive" yerel ISO gönderilir: "2026-07-23T10:00:00".
//   Backend bunu Europe/Istanbul olarak yorumlar — web'in datetime-local
//   input'uyla birebir aynı yol. formatApiTarih() bunu üretir.
//   .toUtc() KULLANMAYIN; sunucuya "Z" ile göndermek saat kaymasına yol açar.
//
// Kural: model/servis katmanında doğrudan DateTime.parse / toIso8601String
// çağırmayın, buradaki yardımcıları kullanın.

/// Backend'den gelen tarih-saat metnini cihazın yerel saatine çevirir.
///
/// Boş/geçersiz değerde null döner (fırlatmaz).
DateTime? parseApiTarih(dynamic deger) {
  if (deger == null) return null;
  if (deger is DateTime) return deger.isUtc ? deger.toLocal() : deger;

  final metin = deger.toString().trim();
  if (metin.isEmpty) return null;

  final parsed = DateTime.tryParse(metin);
  if (parsed == null) return null;

  // Offset'li ya da "Z"li geldiyse isUtc=true olur; toLocal() duvar saatini verir.
  // Offset'siz geldiyse zaten yereldir ve toLocal() etkisizdir.
  return parsed.toLocal();
}

/// [parseApiTarih] ile aynı; değer okunamazsa [varsayilan] (yoksa "şimdi") döner.
DateTime parseApiTarihOrNow(dynamic deger, {DateTime? varsayilan}) {
  return parseApiTarih(deger) ?? varsayilan ?? DateTime.now();
}

/// Yalnızca tarih içeren alanlar ("2026-07-23") için. Saat bileşeni sıfırlanır.
DateTime? parseApiGun(dynamic deger) {
  final d = parseApiTarih(deger);
  if (d == null) return null;
  return DateTime(d.year, d.month, d.day);
}

/// Backend'e gönderilecek offset'siz yerel ISO metin: "2026-07-23T10:00:00".
///
/// Saniye dahil edilir, mikrosaniye atılır. UTC bir DateTime verilirse önce
/// yerele çevrilir — sunucuya her zaman duvar saati gider.
String formatApiTarih(DateTime tarih) {
  final t = tarih.isUtc ? tarih.toLocal() : tarih;
  String iki(int n) => n.toString().padLeft(2, '0');
  return '${t.year.toString().padLeft(4, '0')}-${iki(t.month)}-${iki(t.day)}'
      'T${iki(t.hour)}:${iki(t.minute)}:${iki(t.second)}';
}

/// Backend'e gönderilecek yalnızca-gün metni: "2026-07-23".
String formatApiGun(DateTime tarih) {
  final t = tarih.isUtc ? tarih.toLocal() : tarih;
  String iki(int n) => n.toString().padLeft(2, '0');
  return '${t.year.toString().padLeft(4, '0')}-${iki(t.month)}-${iki(t.day)}';
}
