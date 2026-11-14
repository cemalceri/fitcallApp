// lib/screens/2_uye/isletme_basvuru/widgets/isletme_basvuru_gorunumu.dart
//
// "Başka işletmeye üyelik" görünümü — API çağırmaz, testte render edilir.
// Üstte başvurular (yoksa bölüm hiç görünmez), altta yeni başvuru: işletme
// seçimi, aktarılacak bilgiler, KVKK kutusu; "Başvur" altta sabit. Form her
// durumda ekranda kalır (rehber hedefleri); başvurulacak işletme yoksa liste
// yerine tek satır bilgi çıkar ve düğme pasif kalır.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/isletme_basvuru_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

ListeTonu basvuruTonu(String durum) => switch (durum) {
      BasvuruDurumu.uye => ListeTonu.basari,
      BasvuruDurumu.reddedildi => ListeTonu.hata,
      _ => ListeTonu.uyari,
    };

String basvuruDurumMetni(String durum) => switch (durum) {
      BasvuruDurumu.uye => 'Onaylandı',
      BasvuruDurumu.reddedildi => 'Reddedildi',
      _ => 'Bekliyor',
    };

class BasvuruDurumCipi extends StatelessWidget {
  final String durum;

  const BasvuruDurumCipi({super.key, required this.durum});

  @override
  Widget build(BuildContext context) {
    final ton = basvuruTonu(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: ton.zemin(context), borderRadius: BorderRadius.circular(20)),
      child: Text(basvuruDurumMetni(durum),
          maxLines: 1,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: ton.on(context))),
    );
  }
}

class IsletmeBasvuruGorunumu extends StatelessWidget {
  final IsletmeBasvuruVerisi? veri;
  final String? hata;
  final int? seciliIsletmeId;
  final bool kvkkOnay;
  final bool gonderiliyor;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;
  final ValueChanged<int> onSec;
  final ValueChanged<bool> onKvkk;
  final VoidCallback onKvkkMetni;
  final VoidCallback onBasvur;

  /// Onaylanan başvuruya dokununca (profile geçiş).
  final ValueChanged<IsletmeBasvurusu> onOnaylanan;

  const IsletmeBasvuruGorunumu({
    super.key,
    required this.veri,
    required this.kvkkOnay,
    required this.onYenile,
    required this.onYenidenDene,
    required this.onSec,
    required this.onKvkk,
    required this.onKvkkMetni,
    required this.onBasvur,
    required this.onOnaylanan,
    this.hata,
    this.seciliIsletmeId,
    this.gonderiliyor = false,
  });

  @override
  Widget build(BuildContext context) {
    final v = veri;
    if (v == null) {
      if (hata != null) {
        return BosDurum(
          ikon: Icons.error_outline_rounded,
          baslik: 'Sayfa açılamadı',
          aciklama: hata!,
          eylemEtiketi: 'Tekrar dene',
          eylemIkonu: Icons.refresh_rounded,
          onEylem: onYenidenDene,
        );
      }
      return const IskeletListe();
    }

    final basvurabilir = seciliIsletmeId != null && kvkkOnay && !gonderiliyor;
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onYenile,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: Bosluk.l),
              children: [
                if (v.basvurular.isNotEmpty) ...[
                  ListeGrupBasligi(
                      baslik: 'Başvurularım', sayi: v.basvurular.length),
                  for (var i = 0; i < v.basvurular.length; i++) ...[
                    if (i > 0) const ListeAyraci(),
                    _basvuruSatiri(v.basvurular[i]),
                  ],
                ],
                const ListeGrupBasligi(baslik: 'Yeni başvuru'),
                OgrenmeHedefi(
                  id: Hedef.isletmeBasvuruIsletmeler,
                  child: _IsletmeListesi(
                    isletmeler: v.gosterilecekIsletmeler,
                    seciliId: seciliIsletmeId,
                    onSec: onSec,
                  ),
                ),
                OgrenmeHedefi(
                  id: Hedef.isletmeBasvuruBilgiler,
                  child: _Bilgiler(bilgiler: v.bilgiler),
                ),
                OgrenmeHedefi(
                  id: Hedef.isletmeBasvuruKvkk,
                  child: _KvkkOnayi(
                    onay: kvkkOnay,
                    onDegis: onKvkk,
                    onMetin: onKvkkMetni,
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, Bosluk.s, Bosluk.l, Bosluk.m),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: basvurabilir ? onBasvur : null,
                child: gonderiliyor
                    ? const ButonYukleniyorGostergesi()
                    : const Text('Başvur'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _basvuruSatiri(IsletmeBasvurusu b) {
    final tarih =
        b.tarih == null ? '' : DateFormat('d MMM y', 'tr_TR').format(b.tarih!);
    final alt = switch (b.durum) {
      BasvuruDurumu.uye => 'Profiline geçmek için dokun',
      BasvuruDurumu.reddedildi => tarih.isEmpty
          ? 'Yeniden başvurabilirsin'
          : '$tarih · Yeniden başvurabilirsin',
      _ => tarih.isEmpty ? 'Ofis inceliyor' : '$tarih · Ofis inceliyor',
    };
    return ListeSatiri(
      onGorsel: ListeAvatari(
          ikon: Icons.storefront_rounded, ton: basvuruTonu(b.durum)),
      baslik: b.isletmeAdi,
      altBaslik: alt,
      sonEk: BasvuruDurumCipi(durum: b.durum),
      okGoster: b.onaylandi,
      onTap: b.onaylandi ? () => onOnaylanan(b) : null,
    );
  }
}

class _IsletmeListesi extends StatelessWidget {
  final List<IsletmeSecenegi> isletmeler;
  final int? seciliId;
  final ValueChanged<int> onSec;

  const _IsletmeListesi({
    required this.isletmeler,
    required this.seciliId,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    if (isletmeler.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Bosluk.l, vertical: Bosluk.m),
        child: Text('Başvurabileceğin başka işletme yok.',
            style: context.metin.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant)),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < isletmeler.length; i++) ...[
          if (i > 0) const ListeAyraci(),
          _satir(context, isletmeler[i]),
        ],
      ],
    );
  }

  Widget _satir(BuildContext context, IsletmeSecenegi isl) {
    final secili = isl.id == seciliId;
    final cs = context.cs;
    final satir = ListeSatiri(
      onGorsel: Icon(
        secili
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: secili ? cs.primary : cs.onSurfaceVariant,
      ),
      baslik: isl.adi,
      altBaslik: isl.bekliyor
          ? 'Başvurun bekliyor'
          : isl.durum == BasvuruDurumu.reddedildi
              ? 'Yeniden başvurabilirsin'
              : null,
      onTap: isl.secilebilir ? () => onSec(isl.id) : null,
    );
    return isl.secilebilir ? satir : Opacity(opacity: 0.55, child: satir);
  }
}

class _Bilgiler extends StatelessWidget {
  final AktarilanBilgiler bilgiler;

  const _Bilgiler({required this.bilgiler});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    Widget satir(String etiket, String deger) => Padding(
          padding: const EdgeInsets.only(top: Bosluk.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84,
                child: Text(etiket,
                    style:
                        TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ),
              Expanded(
                child: Text(deger.isEmpty ? '—' : deger,
                    style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aktarılacak bilgilerin', style: context.metin.titleSmall),
          satir('Ad soyad', bilgiler.adSoyad),
          satir('Telefon', bilgiler.telefon),
          satir('E-posta', bilgiler.email),
          const SizedBox(height: Bosluk.s),
          Text(
            'Bu bilgileri yalnız seçtiğin işletme görür. '
            'Ödemeler her işletmede ayrı tutulur.',
            style:
                context.metin.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _KvkkOnayi extends StatelessWidget {
  final bool onay;
  final ValueChanged<bool> onDegis;
  final VoidCallback onMetin;

  const _KvkkOnayi({
    required this.onay,
    required this.onDegis,
    required this.onMetin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Bosluk.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: onay,
            onChanged: (d) => onDegis(d ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('KVKK aydınlatma metnini okudum, onaylıyorum'),
          ),
          TextButton(
            onPressed: onMetin,
            child: const Text('Aydınlatma metnini oku'),
          ),
        ],
      ),
    );
  }
}
