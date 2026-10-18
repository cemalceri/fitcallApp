// lib/common/dekont_dosya_util.dart
//
// Dekont yüklemesinin istemci tarafı denetimi. Sunucu aynı kuralları
// (calendarapp/services/dekont_service.py) yeniden uygular; burada amaç
// kullanıcıya hatayı yüklemeden önce, satır içinde göstermek.

/// Sunucuyla aynı sınır: dekont başına en fazla 5 MB.
const int dekontEnBuyukMb = 5;
const int dekontEnBuyukBayt = dekontEnBuyukMb * 1024 * 1024;

/// Türü içerikten (sihirli baytlar) bulur: yalnız PDF, JPEG, PNG.
/// Bilinmeyen tür → null.
String? dekontTuru(List<int> b) {
  if (b.length >= 5 &&
      b[0] == 0x25 && // %
      b[1] == 0x50 && // P
      b[2] == 0x44 && // D
      b[3] == 0x46 && // F
      b[4] == 0x2D) {
    return 'application/pdf';
  }
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47) {
    return 'image/png';
  }
  return null;
}

/// "7,2" — Türkçe ondalıkla MB.
String mbMetni(int bayt) =>
    (bayt / 1024 / 1024).toStringAsFixed(1).replaceAll('.', ',');

/// Dosya yüklenebilir mi? Değilse kullanıcıya gösterilecek cümle.
String? dekontDosyasiHatasi(List<int> baytlar) {
  if (baytlar.isEmpty) return 'Dosya boş.';
  if (baytlar.length > dekontEnBuyukBayt) {
    return 'Dosya ${mbMetni(baytlar.length)} MB; en fazla $dekontEnBuyukMb MB '
        'olabilir. Dekontun ekran görüntüsünü yükleyebilirsin.';
  }
  if (dekontTuru(baytlar) == null) {
    return 'Yalnız fotoğraf (JPEG, PNG) ya da PDF yüklenebilir.';
  }
  return null;
}

/// '12.500,50', '12500,5', '12500.50', '12.500' → sayı. Boş → null.
/// Geçersizse [double.nan] döner (boş ile geçersizi ayırmak için).
double? tutarCoz(String metin) {
  var m = metin.replaceAll(RegExp(r'[₺\s]'), '').replaceAll('TL', '');
  if (m.isEmpty) return null;
  if (m.contains(',') && m.contains('.')) {
    m = m.replaceAll('.', '').replaceAll(',', '.');
  } else if (m.contains(',')) {
    m = m.replaceAll(',', '.');
  } else if ('.'.allMatches(m).length > 1) {
    m = m.replaceAll('.', '');
  } else if (RegExp(r'^\d+\.\d{3}$').hasMatch(m)) {
    m = m.replaceAll('.', '');
  }
  return double.tryParse(m) ?? double.nan;
}
