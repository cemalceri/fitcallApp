// lib/screens/7_yonetici/dekont/bekleyen_dekontlar_gorunumu.dart
//
// "Ödeme onay bekliyor" listesinin veriyle beslenen görünümü (API yok; sayfa
// ve taşma testi aynı widget'ı çizer). Yönetici yalnız görür: onay ve ret
// web'deki dekont masasında, ofiste.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/bekleyen_dekont_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/7_yonetici/widgets/pano_parcalari.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BekleyenDekontlarGorunumu extends StatelessWidget {
  final List<BekleyenDekont> dekontlar;

  /// Satıra dokununca dekontun dosyası açılır; null ise satır dokunulmaz.
  final ValueChanged<BekleyenDekont>? onDekont;

  const BekleyenDekontlarGorunumu({
    super.key,
    required this.dekontlar,
    this.onDekont,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    if (dekontlar.isEmpty) {
      return const BosDurum(
        ikon: Icons.task_alt_rounded,
        baslik: 'Bekleyen ödeme yok',
        aciklama: 'Üyelerin gönderdiği bütün dekontlar ofiste işlenmiş.',
      );
    }
    final toplam = dekontlar.fold<double>(0, (t, d) => t + (d.beyanTutar ?? 0));
    final enEski =
        dekontlar.fold<int>(0, (m, d) => d.beklemeGun > m ? d.beklemeGun : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.l, Bosluk.l, 0),
          child: OgrenmeHedefi(
            id: Hedef.dekontOzeti,
            child: PanoKarti(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Hucre(
                          deger: '${dekontlar.length}',
                          etiket: 'dekont bekliyor',
                        ),
                      ),
                      Expanded(
                        child: _Hucre(
                          deger: tutarYaz(toplam),
                          birim: 'TL',
                          etiket: 'üyelerin yazdığı tutar',
                        ),
                      ),
                      Expanded(
                        child: _Hucre(
                          deger: enEski <= 0 ? 'Bugün' : '$enEski gün',
                          etiket: 'en eskisi',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Bosluk.m),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Yalnız görüntüleme: onay ve ret ofiste, web\'deki '
                          'dekont masasından yapılır. Satıra dokununca resim '
                          'açılır, PDF telefona iner.',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Bosluk.m),
        for (var i = 0; i < dekontlar.length; i++) ...[
          if (i > 0) const ListeAyraci(solBosluk: 72),
          ogrenmeHedefiSar(
            i == 0 ? Hedef.dekontSatiri : null,
            _DekontSatiri(
              dekont: dekontlar[i],
              onTap: onDekont == null ? null : () => onDekont!(dekontlar[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _Hucre extends StatelessWidget {
  final String deger;
  final String? birim;
  final String etiket;

  const _Hucre({required this.deger, required this.etiket, this.birim});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: TutarYazisi(deger, birim: birim, boyut: 20),
        ),
        Text(
          etiket,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: context.cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DekontSatiri extends StatelessWidget {
  final BekleyenDekont dekont;
  final VoidCallback? onTap;

  const _DekontSatiri({required this.dekont, this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = dekont;
    final yuklenme = d.yuklenme == null
        ? null
        : DateFormat('d MMM HH:mm', 'tr_TR').format(d.yuklenme!);
    final alt = [
      if (d.hesapSahibi.isNotEmpty && d.hesapSahibi != d.uyeAdi)
        'Gönderen: ${d.hesapSahibi}',
      if (yuklenme != null) yuklenme,
      if (d.aciklama.isNotEmpty) '“${d.aciklama}”',
    ].join(' · ');

    // Rozet ve tutar esnek: uzun ad ve büyük tutarda dar ekranda kısalır.
    Widget? rozet;
    if (d.ayniDosya) {
      rozet =
          const Flexible(child: DurumHapi('Aynı dosya', ton: ListeTonu.hata));
    } else if (d.yenidenKontrol) {
      rozet = const Flexible(
          child: DurumHapi('Yeniden kontrol', ton: ListeTonu.uyari));
    }
    final bekleme = d.beklemeMetni.isEmpty
        ? null
        : (d.beklemeGun <= 0 ? 'bugün' : '${d.beklemeMetni}dür');
    final metin = context.metin;

    return ListeSatiri(
      onGorsel: ListeAvatari(
        basHarfler: basHarfleri(d.uyeAdi),
        ikon: d.pdfMi ? Icons.picture_as_pdf_outlined : null,
        ton: ListeTonu.uyari,
      ),
      baslik: d.uyeAdi.isEmpty ? 'Üye' : d.uyeAdi,
      rozet: rozet,
      altBaslik: alt.isEmpty ? null : alt,
      sonEk: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            d.beyanTutar == null
                ? 'Tutar yok'
                : '${tutarYaz(d.beyanTutar!)} TL',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: metin.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (bekleme != null)
            Text(
              bekleme,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: metin.labelSmall,
            ),
        ],
      ),
      okGoster: onTap != null,
      onTap: onTap,
    );
  }
}
