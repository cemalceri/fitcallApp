// lib/screens/1_common/acilis_popup/widgets/surum_notu_popup.dart
//
// Tam ekran "Neler yeni?" popup'ı (Tasarım A, kullanıcı kararı 2026-10-15):
// üstte kimlik yüzeyi + sürüm rozeti, ortada açılır madde listesi, altta tek
// "Anladım" butonu. Duyuru popup'ının kardeşi — aynı ağırlıkta hissedilsin
// diye tam ekran ve dışarı dokunarak kapanmıyor.
//
// Neden tam ekran: sorun "sürüm notunu kimse okumuyor". Alttan sayfa ve küçük
// dialog varyantları daha nazikti ama refleksle kapatılıyor; okuma oranı en
// yüksek varyant seçildi. Dengesi: atlanabilirlik tek butonda ve kalıcı erişim
// Ayarlar > "Neler yeni"de.
//
// Accordion `SssKarti` ile çizilir (yardım sayfalarıyla aynı widget): ilk madde
// açık gelir, açılan maddeler [onMaddeAcildi] ile ölçüme gider.
//
// Gövde ([SurumNotuGovdesi]) dialog'tan ayrı: taşma ve kontrast testleri onu
// doğrudan pump ediyor (bkz. test/tasma_ekranlar_test.dart).

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/surum_notu_model.dart';
import 'package:fitcall/screens/1_common/widgets/sss_gorunumu.dart';
import 'package:flutter/material.dart';

/// Popup'ta rahat okunan madde sayısı; fazlası "Tümünü gör" ile sayfaya.
const int surumNotuPopupMaddeSiniri = 4;

class SurumNotuPopup extends StatelessWidget {
  final SurumNotuBlogu blok;
  final VoidCallback onKapat;

  /// Madde sınırı aşıldıysa "Tümünü gör" — null ise buton çizilmez.
  final VoidCallback? onTumunuGor;

  /// Accordion'da bir madde açıldı (ölçüm).
  final ValueChanged<int>? onMaddeAcildi;

  const SurumNotuPopup({
    super.key,
    required this.blok,
    required this.onKapat,
    this.onTumunuGor,
    this.onMaddeAcildi,
  });

  /// Popup'ı açar. "Tümünü gör"e basıldıysa true döner.
  static Future<bool> goster(
    BuildContext context,
    SurumNotuBlogu blok, {
    ValueChanged<int>? onMaddeAcildi,
  }) async {
    final tumunuGorVar = blok.maddeler.length > surumNotuPopupMaddeSiniri;
    final sonuc = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Neler yeni',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => SurumNotuPopup(
        blok: blok,
        onKapat: () => Navigator.of(ctx).pop(false),
        onTumunuGor: tumunuGorVar ? () => Navigator.of(ctx).pop(true) : null,
        onMaddeAcildi: onMaddeAcildi,
      ),
      transitionBuilder: (_, animasyon, __, child) {
        final egri =
            CurvedAnimation(parent: animasyon, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: egri,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(egri),
            child: child,
          ),
        );
      },
    );
    return sonuc ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.gecis.sayfaRengi,
      child: SurumNotuGovdesi(
        blok: blok,
        onKapat: onKapat,
        onTumunuGor: onTumunuGor,
        onMaddeAcildi: onMaddeAcildi,
      ),
    );
  }
}

/// Popup'ın içeriği — dialog kabuğundan bağımsız, testte doğrudan pump edilir.
class SurumNotuGovdesi extends StatelessWidget {
  final SurumNotuBlogu blok;
  final VoidCallback onKapat;
  final VoidCallback? onTumunuGor;
  final ValueChanged<int>? onMaddeAcildi;

  const SurumNotuGovdesi({
    super.key,
    required this.blok,
    required this.onKapat,
    this.onTumunuGor,
    this.onMaddeAcildi,
  });

  @override
  Widget build(BuildContext context) {
    // Popup'ta en çok [surumNotuPopupMaddeSiniri] madde; kalanı sayfada.
    final gosterilen = blok.maddeler.length > surumNotuPopupMaddeSiniri
        ? blok.maddeler.sublist(0, surumNotuPopupMaddeSiniri)
        : blok.maddeler;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Baslik(blok: blok, onKapat: onKapat),
        // Sabit yükseklik oranı YOK: büyük yazı ölçeğinde başlık büyür, liste
        // küçülür; taşma yerine kaydırma olur.
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.s),
            itemCount: gosterilen.length,
            separatorBuilder: (_, __) => const SizedBox(height: Bosluk.m),
            itemBuilder: (_, i) {
              final madde = gosterilen[i];
              return SssKarti(
                sss: SssSoru(
                  ikon: madde.ikonVeri,
                  soru: madde.baslik,
                  cevap: madde.aciklama,
                  yol: madde.yol,
                ),
                // İlk madde açık: popup boş bir liste gibi görünmesin.
                baslangictaAcik: i == 0,
                onAcildi: () => onMaddeAcildi?.call(madde.id),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, Bosluk.s, Bosluk.l, Bosluk.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onTumunuGor != null) ...[
                  TextButton(
                    onPressed: onTumunuGor,
                    child: Text('Tümünü gör (${blok.maddeler.length})'),
                  ),
                  const SizedBox(height: Bosluk.xs),
                ],
                FilledButton(
                  onPressed: onKapat,
                  child: const Text('Anladım'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kimlik yüzeyi: sürüm rozeti + başlık + özet. Sayfa başına bir tane.
class _Baslik extends StatelessWidget {
  final SurumNotuBlogu blok;
  final VoidCallback onKapat;

  const _Baslik({required this.blok, required this.onKapat});

  @override
  Widget build(BuildContext context) {
    final gecis = context.gecis;
    final metin = context.metin;
    final ozet = blok.ozet;

    return Container(
      decoration: BoxDecoration(gradient: gecis.kimlik),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Bosluk.xl, Bosluk.s, Bosluk.s, Bosluk.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Kapat',
                  onPressed: onKapat,
                  style: IconButton.styleFrom(
                    foregroundColor: gecis.onKimlik.withValues(alpha: 0.86),
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: Bosluk.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (blok.surum.isNotEmpty) _SurumRozeti(surum: blok.surum),
                    const SizedBox(height: Bosluk.m),
                    Text(
                      blok.baslik,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: metin.headlineSmall?.copyWith(
                        color: gecis.onKimlik,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (ozet.isNotEmpty) ...[
                      const SizedBox(height: Bosluk.xs),
                      Text(
                        ozet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: metin.bodyMedium?.copyWith(
                          color: gecis.onKimlik.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurumRozeti extends StatelessWidget {
  final String surum;

  const _SurumRozeti({required this.surum});

  @override
  Widget build(BuildContext context) {
    final gecis = context.gecis;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Bosluk.m, vertical: Bosluk.xs),
      decoration: BoxDecoration(
        color: TemaGecisleri.kapsulZemini,
        borderRadius: BorderRadius.circular(Yaricap.xl),
      ),
      child: Text(
        surum,
        style: context.metin.labelLarge?.copyWith(
          color: gecis.onKimlik,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
