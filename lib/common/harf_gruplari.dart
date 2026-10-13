// lib/common/harf_gruplari.dart
//
// Ada göre sıralı listeyi rehberdeki gibi baş harf gruplarına böler.

/// Sunucunun sırasını korur, ardışık aynı harfleri tek grupta birleştirir.
///
/// Ç, Ğ, İ, Ö, Ş, Ü temel harfine katlanır: veritabanı (en_US harmanlaması)
/// "Can, Çağla, Cem" sırasıyla döndürüyor; katlanmasa C, Ç, C diye üç başlık
/// çıkardı. Harfle başlamayan adlar "#" altında toplanır.
List<(String, List<T>)> harfGruplari<T>(
  List<T> ogeler,
  String Function(T) ad,
) {
  final gruplar = <(String, List<T>)>[];
  for (final oge in ogeler) {
    final harf = basHarf(ad(oge));
    if (gruplar.isNotEmpty && gruplar.last.$1 == harf) {
      gruplar.last.$2.add(oge);
    } else {
      gruplar.add((harf, [oge]));
    }
  }
  return gruplar;
}

const _katlama = {
  'Ç': 'C',
  'Ğ': 'G',
  'İ': 'I',
  'Ö': 'O',
  'Ş': 'S',
  'Ü': 'U',
};

/// Adın grup harfi: Türkçe büyük harf, temel harfe katlanmış.
String basHarf(String ad) {
  final temiz = ad.trim();
  if (temiz.isEmpty) return '#';
  var ilk = String.fromCharCode(temiz.runes.first);
  ilk = switch (ilk) {
    'i' => 'İ',
    'ı' => 'I',
    _ => ilk.toUpperCase(),
  };
  ilk = _katlama[ilk] ?? ilk;
  return RegExp(r'^[A-Z]$').hasMatch(ilk) ? ilk : '#';
}
