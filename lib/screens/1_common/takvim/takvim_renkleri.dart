// lib/screens/1_common/takvim/takvim_renkleri.dart
//
// Takvim ekranlarının renk erişimi.
//
// Eskiden üye ve antrenör takvimlerinde iki ayrı `TakvimColors` sabit sınıfı
// vardı; kopyalar zamanla ayrıştı (8 satır fark) ve sabit oldukları için koyu
// temada okunmaz hâle geliyorlardı. Artık tek kaynak var ve değerler tema
// token'larından türetiliyor: `context.takvim.pending` gibi.

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

class TakvimRenkleri {
  final ColorScheme _cs;
  final FitcallRenkleri _r;

  const TakvimRenkleri(this._cs, this._r);

  /// Takvimin ana vurgu rengi (seçili gün, bugün işareti).
  Color get primary => _cs.primary;

  /// Ana rengin açık zemini (çip ve buton arka planı).
  Color get primaryLight => _r.vurguZemin;

  // Ders durumları
  Color get future => _r.dersGelecek;
  Color get completed => _r.dersTamamlandi;
  Color get pending => _r.dersBekliyor;
  Color get notAttending => _r.dersIptal;
  Color get notDone => _r.dersYapilmadi;
  Color get cancelled => _r.dersIptal;

  // Izgara ve yüzey
  Color get hourLine => _r.saatCizgisi;
  Color get halfHourLine => _r.yarimSaatCizgisi;
  Color get currentTimeLine => _r.simdiCizgisi;
  Color get surface => _r.takvimZemin;
  Color get kart => _cs.surface;

  // Metin
  Color get textPrimary => _cs.onSurface;
  Color get textSecondary => _cs.onSurfaceVariant;
  Color get textMuted => _cs.outline;
}

extension TakvimRenkKisayolu on BuildContext {
  TakvimRenkleri get takvim => TakvimRenkleri(cs, renkler);
}
