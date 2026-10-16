// lib/screens/7_yonetici/uyeler/widgets/uye_istatistik_kartlar.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Üye listesinin filtresi: sayılı kartlar (Toplam · Aktif · Pasif · Borçlu ·
/// Yeni). Kart hem sayıyı gösterir hem dokununca listeyi süzer; seçili kart
/// vurgulu. Önceden başlıkta ayrıca Tümü/Aktif/Pasif/Borçlular butonları
/// vardı — aynı işi yapan iki yapı (kullanıcı kararı 2026-10-16).
class UyeIstatistikKartlar extends StatelessWidget {
  /// İlk sayfa gelene kadar null: kartlar "–" ile durur ama dokunulabilir.
  final UyeIstatistik? data;

  /// 'tumu' | 'aktif' | 'pasif' | 'borclu' | 'yeni'
  final String secili;
  final ValueChanged<String> onSec;

  const UyeIstatistikKartlar({
    super.key,
    required this.data,
    required this.secili,
    required this.onSec,
  });

  static const double _dikey = 8;
  static const double _degerBoyu = 18;
  static const double _etiketBoyu = 11;

  /// Kart yüksekliği; başlık şeridinin (SliverAppBar bottom) hesabı için.
  /// Yazı ölçeği 1.3'e çıkabildiği için sabit değer verilmez.
  static double yukseklik(BuildContext context) {
    final olcek = MediaQuery.textScalerOf(context);
    return _dikey * 2 +
        olcek.scale(_degerBoyu) * 1.25 +
        2 +
        olcek.scale(_etiketBoyu) * 1.3 +
        2; // kenarlık
  }

  @override
  Widget build(BuildContext context) {
    String sayi(int? n) => n?.toString() ?? '–';
    final d = data;
    final kartlar = [
      ('tumu', 'Toplam', sayi(d?.toplamUye), ListeTonu.bilgi),
      ('aktif', 'Aktif', sayi(d?.aktifUye), ListeTonu.basari),
      ('pasif', 'Pasif', sayi(d?.pasifUye), ListeTonu.notr),
      // Alanı göndermeyen eski sunucuda "–"; filtre yine çalışır.
      ('borclu', 'Borçlu', sayi(d?.borcluUye), ListeTonu.hata),
      ('yeni', 'Yeni', sayi(d?.buAyYeniKayit), ListeTonu.vurgu),
    ];
    return SizedBox(
      height: yukseklik(context),
      child: Row(
        children: [
          for (final (i, (kod, etiket, deger, ton)) in kartlar.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _FiltreKarti(
                etiket: etiket,
                deger: deger,
                ton: ton,
                secili: kod == secili,
                onTap: () => onSec(kod),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FiltreKarti extends StatelessWidget {
  final String etiket;
  final String deger;
  final ListeTonu ton;
  final bool secili;
  final VoidCallback onTap;

  const _FiltreKarti({
    required this.etiket,
    required this.deger,
    required this.ton,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final on = ton.on(context);
    final yaricap = BorderRadius.circular(Yaricap.m);
    void dokun() {
      if (secili) return;
      HapticFeedback.selectionClick();
      onTap();
    }

    // InkWell ExcludeSemantics'in altında kaldığı için dokunma eylemi burada
    // verilir; yoksa ekran okuyucu kartı okur ama seçemez.
    return Semantics(
      button: true,
      selected: secili,
      label: deger == '–' ? etiket : '$etiket $deger üye',
      onTap: secili ? null : dokun,
      child: ExcludeSemantics(
        child: Material(
          color: secili ? ton.zemin(context) : cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: yaricap,
            side: BorderSide(
              color: secili ? on : cs.outlineVariant,
              width: secili ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: yaricap,
            onTap: dokun,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: UyeIstatistikKartlar._dikey,
              ),
              // Dar ekranda / büyük yazıda sayı ve etiket küçülür, taşmaz.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      deger,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: UyeIstatistikKartlar._degerBoyu,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                        color: on,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      etiket,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: UyeIstatistikKartlar._etiketBoyu,
                        height: 1.3,
                        fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                        color: secili ? on : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
