// lib/screens/7_yonetici/antrenorler/widgets/antrenor_liste_item.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/degerlendirmeler/widgets/puan_parcalari.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Antrenör listesi satırı: iki ayrı dokunma alanı.
///
/// Solda ortak [ListeSatiri] (ad, özet, ok) hakediş saatlerine; sağda ince
/// bir ayraçla ayrılmış puan hücresi ("★ 4.8 (23)" / "Yorumlar ›")
/// değerlendirmelere gider. İki hedef de kendi okunu taşır; önceki alt
/// sayfa (iki seçenek) araya fazladan bir dokunuş koyuyordu (kullanıcı
/// kararı 2026-10-16).
class AntrenorListeItemWidget extends StatelessWidget {
  final AntrenorListeItem antrenor;
  final VoidCallback? onHakedis;

  /// Değerlendirmesi olmayan antrenörde çağrılmaz: hücre "Puan yok" yazar
  /// ve dokunulmaz.
  final VoidCallback? onDegerlendirmeler;

  const AntrenorListeItemWidget({
    super.key,
    required this.antrenor,
    this.onHakedis,
    this.onDegerlendirmeler,
  });

  @override
  Widget build(BuildContext context) {
    final satir = ListeSatiri(
      onGorsel: ListeAvatari(
        basHarfler: ListeAvatari.harfler(antrenor.adSoyad),
        ton: antrenor.aktifMi ? ListeTonu.bilgi : ListeTonu.notr,
      ),
      baslik: antrenor.adSoyad,
      rozet: antrenor.aktifMi ? null : const _PasifRozeti(),
      altBaslik: 'Bugün ${antrenor.bugunDersSayisi} ders · '
          'hafta ${antrenor.haftalikDersSayisi} · '
          '${antrenor.ogrenciSayisi} öğrenci',
      okGoster: onHakedis != null,
      onTap: onHakedis,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: onHakedis == null
                ? satir
                : Semantics(hint: 'Hakediş saatleri', child: satir),
          ),
          PuanHucresi(
            puan: antrenor.ortalamaPuan,
            sayi: antrenor.degerlendirmeSayisi,
            onTap: onDegerlendirmeler,
          ),
        ],
      ),
    );
  }
}

/// Satırın sağındaki değerlendirme hücresi.
///
/// Puan varsa uyarı zemininde "★ 4.8 (23)" ve altında "Yorumlar ›": hücre
/// kendi hedefini adıyla söyler. Puan yoksa zeminsiz, soluk "Puan yok" ve
/// dokunulmaz — açılacak yorum yok.
class PuanHucresi extends StatelessWidget {
  final double? puan;

  /// Değerlendirme sayısı. Bu alanı göndermeyen eski sunucuda null gelir;
  /// ortalama yine gösterilir, yalnız parantez düşer.
  final int? sayi;
  final VoidCallback? onTap;

  const PuanHucresi({super.key, required this.puan, this.sayi, this.onTap});

  bool get _puanVar => puan != null && sayi != 0;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final renkler = context.renkler;
    final metin = context.metin;
    final puanVar = _puanVar;
    final on = puanVar ? renkler.uyari : cs.onSurfaceVariant;
    final dokunulur = puanVar && onTap != null;

    final Widget icerik;
    if (puanVar) {
      icerik = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 18, color: on),
              const SizedBox(width: 2),
              Text.rich(
                TextSpan(
                  text: puan!.toStringAsFixed(1),
                  style: metin.titleSmall?.copyWith(
                    color: on,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    if (sayi != null)
                      TextSpan(
                        text: ' (${PuanRozeti.sayiMetni(sayi!)})',
                        style: metin.labelMedium?.copyWith(
                          color: on,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Yorumlar',
                maxLines: 1,
                style: metin.labelMedium?.copyWith(
                  color: on,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: on),
            ],
          ),
        ],
      );
    } else {
      icerik = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded, size: 18, color: on),
          const SizedBox(height: 2),
          Text(
            'Puan yok',
            maxLines: 1,
            style: metin.labelMedium?.copyWith(color: on),
          ),
        ],
      );
    }

    final hucre = Material(
      type: puanVar ? MaterialType.canvas : MaterialType.transparency,
      color: puanVar ? renkler.uyariZemin : null,
      child: InkWell(
        onTap: dokunulur
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        child: Container(
          // Sabit genişlik: yazı büyüdükçe hücre genişlerse soldaki ad ve
          // "Pasif" rozeti dar ekranda taşıyordu; içerik ölçeklenir.
          width: 100,
          padding: const EdgeInsets.symmetric(
            horizontal: Bosluk.m,
            vertical: Bosluk.s,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: puanVar
                    ? renkler.uyari.withValues(alpha: 0.35)
                    : cs.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(fit: BoxFit.scaleDown, child: icerik),
        ),
      ),
    );

    if (!puanVar) {
      return Semantics(label: 'Henüz değerlendirme yok', child: hucre);
    }
    return Semantics(
      button: dokunulur,
      label: 'Değerlendirmeler, ortalama ${puan!.toStringAsFixed(1)}'
          '${sayi == null ? '' : ', $sayi değerlendirme'}',
      child: ExcludeSemantics(child: hucre),
    );
  }
}

class _PasifRozeti extends StatelessWidget {
  const _PasifRozeti();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Yaricap.s),
      ),
      child: Text(
        'Pasif',
        style: context.metin.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
