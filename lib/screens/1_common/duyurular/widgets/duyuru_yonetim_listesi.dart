// lib/screens/1_common/duyurular/widgets/duyuru_yonetim_listesi.dart

import 'package:fitcall/models/1_common/duyuru_okuma_models.dart';
import 'package:fitcall/screens/1_common/duyurular/widgets/duyuru_bicim.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';

/// Yönetici/ofis duyuru listesi — veriyle beslenen gövde (sayfa API çağırdığı
/// için taşma testleri bunu render eder).
///
/// Gruplar: Yayında / Planlanan / Geçmiş (biten + pasif); boş grup çizilmez.
/// Satırın sağında gören oranı ("%38") ve altında "54/142" hesap.
class DuyuruYonetimListesi extends StatelessWidget {
  final List<DuyuruYonetimSatiri> duyurular;
  final ValueChanged<DuyuruYonetimSatiri> onSec;
  final Future<void> Function() onYenile;

  const DuyuruYonetimListesi({
    super.key,
    required this.duyurular,
    required this.onSec,
    required this.onYenile,
  });

  @override
  Widget build(BuildContext context) {
    if (duyurular.isEmpty) {
      return RefreshIndicator(
        onRefresh: onYenile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            BosDurum(
              ikon: Icons.campaign_outlined,
              baslik: 'Henüz duyuru yok',
              aciklama: 'Duyurular web panelinden oluşturulur; yayınlananlar '
                  've kimlerin gördüğü burada listelenir.',
            ),
          ],
        ),
      );
    }

    List<DuyuruYonetimSatiri> grup(DuyuruYayinDurumu d) =>
        duyurular.where((x) => x.durum == d).toList();

    return RefreshIndicator(
      onRefresh: onYenile,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ..._grup(context, 'Yayında', grup(DuyuruYayinDurumu.yayinda)),
          ..._grup(context, 'Planlanan', grup(DuyuruYayinDurumu.planli)),
          ..._grup(context, 'Geçmiş', grup(DuyuruYayinDurumu.gecmis)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  List<Widget> _grup(
    BuildContext context,
    String baslik,
    List<DuyuruYonetimSatiri> grup,
  ) {
    if (grup.isEmpty) return const [];
    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: ListeGrupBasligiDelegate(
          baslik: baslik,
          sayi: grup.length,
          yukseklik: listeGrupBasligiYuksekligi(context),
        ),
      ),
      SliverList.builder(
        itemCount: grup.length,
        itemBuilder: (context, i) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (i > 0) const ListeAyraci(),
            _satir(grup[i]),
          ],
        ),
      ),
    ];
  }

  Widget _satir(DuyuruYonetimSatiri d) {
    final String deger;
    final String altDeger;
    final oran = d.oran;
    if (!d.olculuyor) {
      deger = '—';
      altDeger = 'ölçülmüyor';
    } else if (d.durum == DuyuruYayinDurumu.planli) {
      deger = '—';
      altDeger = gunAy(d.yayinBaslangic);
    } else {
      deger = oran == null ? '—' : oranMetni(oran);
      altDeger = '${d.gorenSayisi}/${d.hedefSayisi}';
    }

    return ListeSatiri(
      // Önemli sinyali yalnız renkte kalmasın diye alt satırda da yazılı.
      onGorsel: ListeAvatari(
        ikon: Icons.campaign_rounded,
        ton: d.onemliMi ? ListeTonu.vurgu : ListeTonu.bilgi,
      ),
      baslik: d.baslik,
      altBaslik: duyuruAltSatiri(
        hedefKitle: d.hedefKitle,
        yayinBaslangic: d.yayinBaslangic,
        yayinBitis: d.yayinBitis,
        aktifMi: d.aktifMi,
        popupGoster: d.popupGoster,
        onemliMi: d.onemliMi,
      ),
      deger: deger,
      altDeger: altDeger,
      okGoster: true,
      onTap: () => onSec(d),
    );
  }
}
