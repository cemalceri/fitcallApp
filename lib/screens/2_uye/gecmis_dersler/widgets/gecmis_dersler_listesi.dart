import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/gecmis_ders_model.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Geçmiş dersleri aya göre gruplayıp düz satırlar hâlinde listeler.
///
/// Kart yığını yerine ortak liste kalıbı: ay başlığı + saç teli ayraçla ayrılan
/// satırlar. Satırın solunda gün rozeti durur — geçmiş ders listesinde satırı
/// ayırt eden şey tarih.
///
/// API çağrısı içermez; veri ve footer dışarıdan verilir. Böylece taşma
/// testinde doğrudan pump edilebilir (bkz. CLAUDE.md).
class GecmisDerslerListesi extends StatelessWidget {
  final List<GecmisDersModel> dersler;
  final void Function(GecmisDersModel) onDegerlendir;

  /// Liste sonuna eklenecek "daha eski" butonu / bilgi satırı (opsiyonel).
  final Widget? footer;

  const GecmisDerslerListesi({
    super.key,
    required this.dersler,
    required this.onDegerlendir,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    // Aylara göre grupla (liste zaten yeniden eskiye sıralı gelir).
    final ayFmt = DateFormat('MMMM yyyy', 'tr');
    final gruplar = <String, List<GecmisDersModel>>{};
    for (final d in dersler) {
      final k = ayFmt.format(d.baslangicTarihSaat);
      gruplar.putIfAbsent(k, () => []).add(d);
    }

    final widgets = <Widget>[];
    gruplar.forEach((ay, list) {
      widgets.add(
        ListeGrupBasligi(
          baslik: ay[0].toUpperCase() + ay.substring(1),
          sayi: list.length,
        ),
      );
      for (var i = 0; i < list.length; i++) {
        if (i > 0) widgets.add(const ListeAyraci(solBosluk: 76));
        widgets.add(
          _DersSatiri(
            ders: list[i],
            onDegerlendir: () => onDegerlendir(list[i]),
          ),
        );
      }
    });
    if (footer != null) {
      widgets.add(Padding(
        padding: const EdgeInsets.all(Bosluk.l),
        child: footer!,
      ));
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Bosluk.xl),
      children: widgets,
    );
  }
}

/// Dersin sonuç durumu — etiket + anlam tonu.
class _DersDurum {
  final String metin;
  final ListeTonu ton;
  const _DersDurum(this.metin, this.ton);
}

class _DersSatiri extends StatelessWidget {
  final GecmisDersModel ders;
  final VoidCallback onDegerlendir;

  const _DersSatiri({required this.ders, required this.onDegerlendir});

  /// Durum rengi doğrudan temadan gelir: eski sabit hex'ler koyu temada
  /// zeminle yeterince ayrışmıyordu. İptal ile "katılmadı" aynı tonda ama
  /// etiketleri farklı — ayrımı renk değil metin taşır (renk körlüğü).
  _DersDurum get _durum {
    if (ders.iptalMi) return const _DersDurum('İptal', ListeTonu.hata);
    if (ders.katilim != null) {
      if (ders.katilim!.katildi) {
        return _DersDurum(
          ders.katilim!.planDisiMi ? 'Katıldı (plan dışı)' : 'Katıldı',
          ListeTonu.basari,
        );
      }
      return const _DersDurum('Katılmadı', ListeTonu.hata);
    }
    if (ders.dersYapildi == true) {
      return const _DersDurum('Ders yapıldı', ListeTonu.basari);
    }
    if (ders.dersYapildi == false) {
      return const _DersDurum('Ders yapılmadı', ListeTonu.notr);
    }
    return const _DersDurum('Kulüp onayında', ListeTonu.uyari);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final saatFmt = DateFormat('HH:mm');
    final gunFmt = DateFormat('EEE', 'tr');
    final durum = _durum;
    final notMetni = ders.katilim?.notMetni;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Bosluk.l,
        vertical: Bosluk.m,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GunRozeti(
            gun: '${ders.baslangicTarihSaat.day}',
            kisaGun: gunFmt.format(ders.baslangicTarihSaat),
            ton: durum.ton,
          ),
          const SizedBox(width: Bosluk.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${saatFmt.format(ders.baslangicTarihSaat)}'
                        ' - ${saatFmt.format(ders.bitisTarihSaat)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.metin.titleSmall,
                      ),
                    ),
                    const SizedBox(width: Bosluk.s),
                    _DurumRozeti(durum: durum),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (ders.kortAdi.isNotEmpty) ders.kortAdi,
                    if (ders.antrenorAdi.isNotEmpty) ders.antrenorAdi,
                    if (ders.urunAdi.isNotEmpty) ders.urunAdi,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.bodySmall,
                ),
                if (notMetni != null && notMetni.isNotEmpty) ...[
                  const SizedBox(height: Bosluk.s),
                  Container(
                    padding: const EdgeInsets.all(Bosluk.s),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(Yaricap.s),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 15, color: cs.onSurfaceVariant),
                        const SizedBox(width: Bosluk.xs),
                        Expanded(
                          child: Text(notMetni, style: context.metin.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!ders.iptalMi) ...[
                  const SizedBox(height: Bosluk.xs),
                  _degerlendirmeSatiri(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _degerlendirmeSatiri(BuildContext context) {
    final puanim = ders.puanim;

    if (puanim != null) {
      final yorum = puanim.yorum;
      return Row(
        children: [
          for (var i = 0; i < 5; i++)
            Icon(
              i < puanim.puan
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 18,
              color: context.renkler.uyari,
            ),
          if (yorum != null && yorum.isNotEmpty) ...[
            const SizedBox(width: Bosluk.s),
            Expanded(
              child: Text(
                yorum,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.metin.bodySmall,
              ),
            ),
          ],
        ],
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onDegerlendir,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: Bosluk.s),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.star_outline_rounded, size: 18),
        label: const Text('Değerlendir'),
      ),
    );
  }
}

/// Satırın solundaki gün rozeti — gün numarası + kısa gün adı.
class _GunRozeti extends StatelessWidget {
  final String gun;
  final String kisaGun;
  final ListeTonu ton;

  const _GunRozeti({
    required this.gun,
    required this.kisaGun,
    required this.ton,
  });

  @override
  Widget build(BuildContext context) {
    final on = ton.on(context);

    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: Bosluk.s),
      decoration: BoxDecoration(
        color: ton.zemin(context),
        borderRadius: BorderRadius.circular(Yaricap.m),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              gun,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: on,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              kisaGun,
              style: context.metin.labelSmall?.copyWith(color: on),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurumRozeti extends StatelessWidget {
  final _DersDurum durum;

  const _DurumRozeti({required this.durum});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Bosluk.s, vertical: 2),
      decoration: BoxDecoration(
        color: durum.ton.zemin(context),
        borderRadius: BorderRadius.circular(Yaricap.s),
      ),
      child: Text(
        durum.metin,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.metin.labelSmall
            ?.copyWith(color: durum.ton.on(context)),
      ),
    );
  }
}
