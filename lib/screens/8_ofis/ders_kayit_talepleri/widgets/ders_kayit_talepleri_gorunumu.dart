// lib/screens/8_ofis/ders_kayit_talepleri/widgets/ders_kayit_talepleri_gorunumu.dart
//
// Ofisin "Ders kayıt talepleri" sayfasının görsel gövdesi — API çağırmaz,
// testte doğrudan render edilir. Her satırda talep eden, istenen gün/saat/kort,
// antrenörün notu ve üç eylem: Programda göster · Reddet · Kayıt oluştur.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DersKayitTalepleriGorunumu extends StatelessWidget {
  final List<DersKayitTalebi>? talepler;
  final bool yukleniyor;
  final String? hata;
  final VoidCallback? onGeri;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;
  final ValueChanged<DersKayitTalebi> onKayitOlustur;
  final ValueChanged<DersKayitTalebi> onReddet;
  final ValueChanged<DersKayitTalebi> onProgramdaGoster;

  /// İşlenen talep (butonları kilitli).
  final int? islenenTalepId;

  const DersKayitTalepleriGorunumu({
    super.key,
    required this.talepler,
    required this.yukleniyor,
    required this.onYenile,
    required this.onYenidenDene,
    required this.onKayitOlustur,
    required this.onReddet,
    required this.onProgramdaGoster,
    this.hata,
    this.onGeri,
    this.islenenTalepId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BaslikBandi(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 6),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                if (onGeri != null)
                  BaslikIkonButonu(
                    ikon: Icons.arrow_back_rounded,
                    ipucu: 'Geri',
                    onTap: onGeri!,
                  )
                else
                  const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ders kayıt talepleri',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: baslikYazi(
                      context,
                      const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _govde(context)),
      ],
    );
  }

  Widget _govde(BuildContext context) {
    final liste = talepler;
    if (liste == null) {
      if (hata != null) {
        return BosDurum(
          ikon: Icons.error_outline_rounded,
          baslik: 'Talepler yüklenemedi',
          aciklama: hata!,
          eylemEtiketi: 'Tekrar dene',
          eylemIkonu: Icons.refresh_rounded,
          onEylem: onYenidenDene,
          ikonRengi: context.cs.error,
        );
      }
      return const IskeletListe();
    }

    return RefreshIndicator(
      onRefresh: onYenile,
      child: liste.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 48),
                BosDurum(
                  ikon: Icons.inbox_rounded,
                  baslik: 'Bekleyen talep yok',
                  aciklama:
                      'Antrenörün açtığı ders kayıt talepleri burada görünür.',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: liste.length,
              separatorBuilder: (_, __) => const ListeAyraci(),
              itemBuilder: (context, i) => DersKayitTalebiSatiri(
                talep: liste[i],
                kilitli: islenenTalepId != null,
                onKayitOlustur: () => onKayitOlustur(liste[i]),
                onReddet: () => onReddet(liste[i]),
                onProgramdaGoster: () => onProgramdaGoster(liste[i]),
              ),
            ),
    );
  }
}

/// Tek talep satırı. Liste satırı kalıbı (daire avatar, iki satır, ince
/// ayraç) korunur; altına not ve eylemler eklenir. Karta sarılmaz.
class DersKayitTalebiSatiri extends StatelessWidget {
  final DersKayitTalebi talep;
  final bool kilitli;
  final VoidCallback onKayitOlustur;
  final VoidCallback onReddet;
  final VoidCallback onProgramdaGoster;

  const DersKayitTalebiSatiri({
    super.key,
    required this.talep,
    required this.onKayitOlustur,
    required this.onReddet,
    required this.onProgramdaGoster,
    this.kilitli = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final gun = DateFormat('d MMM EEE', 'tr_TR').format(talep.baslangic);
    final gonderim = talep.olusturulma == null
        ? null
        : DateFormat('d MMM HH:mm', 'tr_TR').format(talep.olusturulma!);

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListeAvatari(
                basHarfler: ListeAvatari.harfler(talep.talepEdenAdi),
                ton: ListeTonu.uyari,
              ),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      talep.talepEdenAdi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.metin.titleSmall,
                    ),
                    Text(
                      '$gun · ${talep.saat}-${talep.bitisSaat} · ${talep.kortAdi}',
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    if (gonderim != null)
                      Text(
                        'Gönderildi: $gonderim',
                        style:
                            TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    const SizedBox(height: Bosluk.s),
                    Text(
                      talep.aciklama,
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Bosluk.s),
          // Dar ekran + büyük yazıda üç düğme alt satıra kayar (taşma yok).
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Wrap(
              spacing: Bosluk.s,
              runSpacing: Bosluk.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: kilitli ? null : onProgramdaGoster,
                  icon: const Icon(Icons.calendar_view_week_rounded, size: 18),
                  label: const Text('Programda göster'),
                ),
                YikiciButon(
                  etiket: 'Reddet',
                  onPressed: kilitli ? null : onReddet,
                ),
                FilledButton(
                  onPressed: kilitli ? null : onKayitOlustur,
                  child: const Text('Kayıt oluştur'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
