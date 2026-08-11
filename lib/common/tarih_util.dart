// lib/common/tarih_util.dart
//
// API ile tarih/saat alışverişinin TEK standardı.
// Backend karşılığı: api/core/tarih.py + calendarapp/utils/tarih_util.py
//
// TEMEL KURAL: Uygulamadaki bütün tarih-saatler KULÜP saat dilimindedir
// (Europe/Istanbul). Cihazın saat dilimi ne olursa olsun 08:30 başlayan ders
// ekranda 08:30 görünür — bildirim metniyle, web panelle ve ofisle birebir aynı.
//
// OKUMA (backend -> mobil)
//   Backend datetime alanlarını yerel saatte offset'li ISO-8601 döner:
//   "2026-08-01T08:30:00+03:00". Bazı alanlar (DRF varsayılanı) UTC "Z" ile
//   gelir: "2026-08-01T05:30:00Z". İkisi de aynı anı gösterir; parseApiTarih()
//   ikisini de kulüp duvar saatine (08:30) indirger ve isUtc=false döndürür.
//   Böylece .hour / DateFormat doğrudan kulüp saatini verir.
//
//   NEDEN .toLocal() DEĞİL: .toLocal() cihazın saat dilimini uygular. Saat
//   dilimi Europe/Istanbul olmayan (yurt dışındaki ya da ayarı bozuk) bir
//   telefonda 08:30'luk ders 11:30 / 05:30 görünüyordu; bildirim metni sunucuda
//   üretildiği için 08:30 diyordu ve ikisi çelişiyordu. Ders saatleri kulübün
//   duvar saatidir, cihazın değil.
//
// YAZMA (mobil -> backend)
//   Offset'siz "naive" metin gönderilir: "2026-08-01T08:30:00".
//   Backend bunu Europe/Istanbul olarak yorumlar — web'in datetime-local
//   input'uyla birebir aynı yol. formatApiTarih() bunu üretir.
//   .toUtc() KULLANMAYIN; sunucuya "Z" ile göndermek saat kaymasına yol açar.
//
// ŞİMDİ
//   DateTime.now() cihazın duvar saatidir; API'den gelen değerlerle
//   KARŞILAŞTIRMAYIN. Onun yerine simdiKulup() / bugunKulup() kullanın.
//
// Kural: model/servis/ekran katmanında doğrudan DateTime.parse /
// toIso8601String / DateTime.now() çağırmayın, buradaki yardımcıları kullanın.

/// Kulübün saat dilimi ofseti: Europe/Istanbul.
///
/// Türkiye 2016'dan beri yaz saati uygulamıyor; ofset sabit UTC+03:00. Bu
/// yüzden tam saat dilimi veritabanına (timezone paketi) gerek yok. Kural
/// değişirse burayı güncellemek yeterli.
const Duration kulupUtcOfseti = Duration(hours: 3);

/// Bir "an"ı kulüp duvar saatine çevirir ve isUtc=false olarak döndürür.
///
/// Dönen değerin .hour/.day alanları doğrudan kulüp saatini verir; cihazın
/// saat dilimi sonucu etkilemez.
DateTime _kulupDuvarSaati(DateTime an) {
  final d = an.toUtc().add(kulupUtcOfseti);
  return DateTime(d.year, d.month, d.day, d.hour, d.minute, d.second,
      d.millisecond, d.microsecond);
}

/// Backend'den gelen tarih-saat metnini kulüp duvar saatine çevirir.
///
/// Boş/geçersiz değerde null döner (fırlatmaz).
DateTime? parseApiTarih(dynamic deger) {
  if (deger == null) return null;
  if (deger is DateTime) {
    return deger.isUtc ? _kulupDuvarSaati(deger) : deger;
  }

  final metin = deger.toString().trim();
  if (metin.isEmpty) return null;

  final parsed = DateTime.tryParse(metin);
  if (parsed == null) return null;

  // Offset'li ("+03:00") ya da "Z"li geldiyse DateTime.parse isUtc=true üretir;
  // anı kulüp ofsetine taşı. Offset'siz geldiyse metin zaten kulüp duvar
  // saatidir, olduğu gibi kalır.
  return parsed.isUtc ? _kulupDuvarSaati(parsed) : parsed;
}

/// [parseApiTarih] ile aynı; değer okunamazsa [varsayilan] (yoksa kulüp
/// saatiyle "şimdi") döner.
DateTime parseApiTarihOrNow(dynamic deger, {DateTime? varsayilan}) {
  return parseApiTarih(deger) ?? varsayilan ?? simdiKulup();
}

/// Yalnızca tarih içeren alanlar ("2026-08-01") için. Saat bileşeni sıfırlanır.
DateTime? parseApiGun(dynamic deger) {
  final d = parseApiTarih(deger);
  if (d == null) return null;
  return DateTime(d.year, d.month, d.day);
}

/// Kulüp saat diliminde "şimdi".
///
/// Cihazın saat dilimi yanlış/farklı olsa da doğru çalışır: cihaz saati önce
/// UTC'ye indirilir (bu an bilgisidir, saat diliminden bağımsızdır), sonra
/// kulüp ofseti eklenir.
DateTime simdiKulup() => _kulupDuvarSaati(DateTime.now());

/// Kulüp saat diliminde bugün (saat bileşeni sıfır).
DateTime bugunKulup() {
  final n = simdiKulup();
  return DateTime(n.year, n.month, n.day);
}

/// Kulüp duvar saatini GERÇEK ANA (UTC) çevirir.
///
/// Uygulamadaki tarihler kulüp duvar saatidir (isUtc=false) ve cihazın saat
/// dilimine göre farklı bir "an"a denk gelir. Cihaz dışına çıkan, gerçek zamanı
/// bilmesi gereken yerlerde bunu kullanın — örn. telefonun takvimine etkinlik
/// eklerken (epoch milisaniye gönderilir) ya da bir alarm kurarken.
///
/// Ekranda göstermek için KULLANMAYIN; gösterim zaten kulüp saatiyle yapılır.
DateTime kulupAnI(DateTime kulupSaati) {
  final k = kulupSaati.isUtc ? _kulupDuvarSaati(kulupSaati) : kulupSaati;
  return DateTime.utc(k.year, k.month, k.day, k.hour, k.minute, k.second,
          k.millisecond, k.microsecond)
      .subtract(kulupUtcOfseti);
}

/// Backend'e gönderilecek offset'siz kulüp saati metni: "2026-08-01T08:30:00".
///
/// Saniye dahil edilir, mikrosaniye atılır. UTC bir DateTime verilirse önce
/// kulüp duvar saatine çevrilir — sunucuya her zaman duvar saati gider.
String formatApiTarih(DateTime tarih) {
  final t = tarih.isUtc ? _kulupDuvarSaati(tarih) : tarih;
  String iki(int n) => n.toString().padLeft(2, '0');
  return '${t.year.toString().padLeft(4, '0')}-${iki(t.month)}-${iki(t.day)}'
      'T${iki(t.hour)}:${iki(t.minute)}:${iki(t.second)}';
}

/// Backend'e gönderilecek yalnızca-gün metni: "2026-08-01".
String formatApiGun(DateTime tarih) {
  final t = tarih.isUtc ? _kulupDuvarSaati(tarih) : tarih;
  String iki(int n) => n.toString().padLeft(2, '0');
  return '${t.year.toString().padLeft(4, '0')}-${iki(t.month)}-${iki(t.day)}';
}
