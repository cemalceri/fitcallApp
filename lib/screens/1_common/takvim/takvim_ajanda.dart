// lib/screens/1_common/takvim/takvim_ajanda.dart
//
// Ajanda görünümü — "sıradaki derslerim ne zaman" sorusunun cevabı.
//
// Izgara (timeline) bir günü saat saat gösterir; boş saatler ekranın çoğunu
// kaplar. Üye çoğunlukla haftasına liste olarak bakmak ister: gün başlıkları
// yapışkan, yalnız dolu saatler var. Antrenör günü ızgarada görmek istediği
// için varsayılan görünüm rol bazında farklı seçilir.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_renkleri.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_zaman.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:flutter/material.dart';

class TakvimAjanda extends StatelessWidget {
  /// Görüntülenecek dersler (genelde içinde bulunulan hafta).
  final List<EtkinlikModel> dersler;
  final ValueChanged<EtkinlikModel> onLessonTap;
  final void Function(EtkinlikModel ders)? onLessonLongPress;

  /// Ders satırının sağında gösterilecek durum etiketi (role göre değişir).
  final String Function(EtkinlikModel ders)? durumEtiketi;
  final Color Function(BuildContext context, EtkinlikModel ders)? durumRengi;

  const TakvimAjanda({
    super.key,
    required this.dersler,
    required this.onLessonTap,
    this.onLessonLongPress,
    this.durumEtiketi,
    this.durumRengi,
  });

  @override
  Widget build(BuildContext context) {
    if (dersler.isEmpty) {
      return const BosDurum(
        ikon: Icons.event_available_rounded,
        baslik: 'Bu haftada ders yok',
        aciklama: 'Seçili hafta için planlanmış ders bulunmuyor. '
            'Başka bir haftaya bakmak için şeridi yana kaydır.',
      );
    }

    final sirali = [...dersler]
      ..sort((a, b) => a.baslangicTarihSaat.compareTo(b.baslangicTarihSaat));

    // Gün -> dersler
    final gunler = <DateTime, List<EtkinlikModel>>{};
    for (final ders in sirali) {
      final gun = TimeUtils.normalizeDate(ders.baslangicTarihSaat);
      gunler.putIfAbsent(gun, () => []).add(ders);
    }

    return CustomScrollView(
      slivers: [
        for (final giris in gunler.entries) ...[
          SliverStickyBaslik(gun: giris.key, adet: giris.value.length),
          SliverList.separated(
            itemCount: giris.value.length,
            separatorBuilder: (_, __) => const SizedBox(height: Bosluk.s),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
              child: _AjandaSatiri(
                ders: giris.value[i],
                onTap: () => onLessonTap(giris.value[i]),
                onLongPress: onLessonLongPress == null
                    ? null
                    : () => onLessonLongPress!(giris.value[i]),
                etiket: durumEtiketi?.call(giris.value[i]),
                renk: durumRengi?.call(context, giris.value[i]),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Bosluk.l)),
        ],
      ],
    );
  }
}

/// Gün başlığı — listeyle birlikte kayar, günün üstünde asılı kalır.
class SliverStickyBaslik extends StatelessWidget {
  final DateTime gun;
  final int adet;

  const SliverStickyBaslik({super.key, required this.gun, required this.adet});

  @override
  Widget build(BuildContext context) {
    final bugun = TimeUtils.isSameDay(gun, simdiKulup());
    final cs = context.cs;

    return SliverAppBar(
      primary: false,
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 40,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: Bosluk.l,
      title: Row(
        children: [
          Flexible(
            child: Text(
              TimeUtils.formatDateFull(gun),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.metin.titleSmall?.copyWith(
                color: bugun ? cs.primary : cs.onSurface,
              ),
            ),
          ),
          if (bugun) ...[
            const SizedBox(width: Bosluk.s),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: Bosluk.s, vertical: 1),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(Yaricap.s),
              ),
              child: Text(
                'Bugün',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(width: Bosluk.s),
          Text('$adet ders', maxLines: 1, style: context.metin.bodySmall),
        ],
      ),
    );
  }
}

class _AjandaSatiri extends StatelessWidget {
  final EtkinlikModel ders;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? etiket;
  final Color? renk;

  const _AjandaSatiri({
    required this.ders,
    required this.onTap,
    this.onLongPress,
    this.etiket,
    this.renk,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final vurgu = renk ?? context.takvim.future;

    return Semantics(
      button: true,
      label: '${TimeUtils.formatTime(ders.baslangicTarihSaat)} '
          '${ders.kortAdi}${etiket == null ? '' : ', $etiket'}',
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Yaricap.l),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(Yaricap.l),
          child: Padding(
            padding: const EdgeInsets.all(Bosluk.m),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 42,
                  decoration: BoxDecoration(
                    color: vurgu,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: Bosluk.m),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TimeUtils.formatTime(ders.baslangicTarihSaat),
                      maxLines: 1,
                      style: context.metin.titleSmall,
                    ),
                    Text(
                      TimeUtils.formatTime(ders.bitisTarihSaat),
                      maxLines: 1,
                      style: context.metin.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(width: Bosluk.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ders.kortAdi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.metin.titleSmall,
                      ),
                      if ((ders.antrenorAdi ?? '').isNotEmpty)
                        Text(
                          ders.antrenorAdi!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.metin.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (etiket != null)
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.only(left: Bosluk.s),
                      padding: const EdgeInsets.symmetric(
                          horizontal: Bosluk.s, vertical: 3),
                      decoration: BoxDecoration(
                        color: vurgu.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(Yaricap.s),
                      ),
                      child: Text(
                        etiket!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: vurgu,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
