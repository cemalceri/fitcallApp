// lib/screens/2_uye/bildirim_tercihleri/widgets/bildirim_tercihleri_gorunumu.dart
//
// "Bildirim tercihleri" görünümü — API çağırmaz, testte render edilir.
// Grup başına bir anahtar; kapatılan grubun bildirimleri telefona gelmez,
// Bildirimlerim'de yine görünür. Açıklamalar uzun olduğu için satır
// ListeSatiri değil SwitchListTile (alt başlık birden çok satıra iner).

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/bildirim_tercihi_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:material_ui/material_ui.dart';

class BildirimTercihleriGorunumu extends StatelessWidget {
  final BildirimTercihleri? veri;
  final String? hata;

  /// Kaydı süren grupların kodları; anahtarları beklerken pasif.
  final Set<String> kaydedilenler;

  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;
  final void Function(BildirimTercihGrubu grup, bool acik) onDegistir;

  const BildirimTercihleriGorunumu({
    super.key,
    required this.veri,
    required this.onYenile,
    required this.onYenidenDene,
    required this.onDegistir,
    this.hata,
    this.kaydedilenler = const {},
  });

  @override
  Widget build(BuildContext context) {
    final v = veri;
    if (v == null) {
      if (hata != null) {
        return BosDurum(
          ikon: Icons.error_outline_rounded,
          baslik: 'Tercihler açılamadı',
          aciklama: hata!,
          eylemEtiketi: 'Tekrar dene',
          eylemIkonu: Icons.refresh_rounded,
          onEylem: onYenidenDene,
        );
      }
      return const IskeletListe(satirSayisi: 4);
    }

    final cs = context.cs;
    final bilgi =
        StringBuffer('Kapattığın bildirimler telefonuna gelmez; uygulamadaki '
            'Bildirimlerim listesinde yine görünür.');
    if (v.uyeProfilSayisi > 1) {
      bilgi.write(' Ayar hesabındaki ${v.uyeProfilSayisi} üye profilinin '
          'hepsine uygulanır.');
    }

    return RefreshIndicator(
      onRefresh: onYenile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Bosluk.xl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.s),
            child: Text(
              bilgi.toString(),
              style: context.metin.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const ListeGrupBasligi(baslik: 'Telefona gelen bildirimler'),
          for (var i = 0; i < v.gruplar.length; i++) ...[
            if (i > 0) const ListeAyraci(),
            _GrupSatiri(
              grup: v.gruplar[i],
              kaydediliyor: kaydedilenler.contains(v.gruplar[i].kod),
              onDegistir: onDegistir,
            ),
          ],
        ],
      ),
    );
  }
}

class _GrupSatiri extends StatelessWidget {
  final BildirimTercihGrubu grup;
  final bool kaydediliyor;
  final void Function(BildirimTercihGrubu grup, bool acik) onDegistir;

  const _GrupSatiri({
    required this.grup,
    required this.kaydediliyor,
    required this.onDegistir,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
      value: grup.acik,
      onChanged: kaydediliyor ? null : (d) => onDegistir(grup, d),
      title: Text(grup.baslik),
      subtitle: grup.aciklama.isEmpty ? null : Text(grup.aciklama),
    );
  }
}

/// Uyarılı grubu kapatmadan önceki onay alt sayfası. `true` = kapat.
class BildirimKapatmaOnayi extends StatelessWidget {
  final BildirimTercihGrubu grup;

  const BildirimKapatmaOnayi({super.key, required this.grup});

  /// Alt sayfa olarak açar; `true` = kapat. Uyarı metni uzun olabildiği için
  /// yükseklik içeriğe göre (varsayılan sınır ekranın ~%56'sı, küçük
  /// telefonda taşıyordu), sığmazsa kaydırılır.
  static Future<bool> goster(
          BuildContext context, BildirimTercihGrubu grup) async =>
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => BildirimKapatmaOnayi(grup: grup),
      ) ==
      true;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Bosluk.xl, Bosluk.s, Bosluk.xl, Bosluk.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.renkler.uyariZemin,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_off_rounded,
                    color: context.renkler.uyari, size: 26),
              ),
              const SizedBox(height: Bosluk.l),
              Text(
                '${grup.baslik} kapatılsın mı?',
                textAlign: TextAlign.center,
                style: context.metin.titleLarge,
              ),
              const SizedBox(height: Bosluk.s),
              Text(
                grup.kapatmaUyarisi ?? '',
                textAlign: TextAlign.center,
                style: context.metin.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: Bosluk.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: Bosluk.m),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Kapat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
