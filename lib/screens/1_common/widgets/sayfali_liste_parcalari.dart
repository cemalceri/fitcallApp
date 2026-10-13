// lib/screens/1_common/widgets/sayfali_liste_parcalari.dart
//
// Sayfalı listelerin (bkz. lib/common/sayfali_liste.dart) ortak sunum
// parçaları: sona yaklaşınca sonraki sayfayı isteyen dinleyici, liste sonu
// iskeleti/hatası ve baş harf grupları.

import 'package:fitcall/common/harf_gruplari.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';

/// Dikey kaydırma listenin sonuna [esik] pikselden fazla yaklaşınca
/// [onSonaYaklasti]'yı çağırır.
///
/// İçerik değişince de (yeni sayfa eklendi ama ekranı doldurmadı) kontrol
/// eder; yalnız kaydırmayı dinlemek kısa listede sonraki sayfayı hiç
/// istemezdi. Yatay çip şeridi gibi iç kaydırmalar yok sayılır.
class SayfaSonuDinleyici extends StatefulWidget {
  final VoidCallback? onSonaYaklasti;
  final double esik;
  final Widget child;

  const SayfaSonuDinleyici({
    super.key,
    required this.onSonaYaklasti,
    this.esik = 600,
    required this.child,
  });

  @override
  State<SayfaSonuDinleyici> createState() => _SayfaSonuDinleyiciState();
}

class _SayfaSonuDinleyiciState extends State<SayfaSonuDinleyici> {
  bool _kontrol(ScrollMetrics m, int derinlik) {
    if (widget.onSonaYaklasti != null &&
        derinlik == 0 &&
        m.axis == Axis.vertical &&
        m.extentAfter < widget.esik) {
      widget.onSonaYaklasti!();
    }
    return false;
  }

  /// İçerik görünür alandan kısa kaldıkça kaydırma ölçüleri değişmez ve
  /// bildirim gelmez; her yeniden çizimden sonra dıştaki kaydırmanın ölçüsü
  /// elle sınanır (sunucu 20'den az kayıt döndürse de sonraki sayfa istenir).
  void _kareSonuKontrol() {
    if (!mounted) return;
    ScrollableState? kaydirma;
    void ara(Element e) {
      if (kaydirma != null) return;
      if (e is StatefulElement && e.state is ScrollableState) {
        kaydirma = e.state as ScrollableState;
        return;
      }
      e.visitChildren(ara);
    }

    context.visitChildElements(ara);
    final konum = kaydirma?.position;
    if (konum != null && konum.hasContentDimensions) {
      _kontrol(konum, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _kareSonuKontrol());
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _kontrol(n.metrics, n.depth),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _kontrol(n.metrics, n.depth),
        child: widget.child,
      ),
    );
  }
}

/// Liste sonu: sonraki sayfa yüklenirken üç iskelet satırı, alınamadıysa
/// mesaj + "Tekrar dene". Liste tamamsa hiçbir şey.
List<Widget> sayfaSonuSliverlari(
  BuildContext context, {
  required bool dahaYukleniyor,
  required String? dahaHatasi,
  required VoidCallback? onTekrarDene,
}) {
  if (dahaYukleniyor) {
    return const [
      SliverToBoxAdapter(
        child: IskeletListe(satirSayisi: 3, kaydirilabilir: false),
      ),
    ];
  }
  if (dahaHatasi != null) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Bosluk.l, Bosluk.m, Bosluk.s, Bosluk.m),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 18, color: context.renkler.hata),
              const SizedBox(width: Bosluk.s),
              Expanded(
                child: Text(
                  dahaHatasi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.bodySmall,
                ),
              ),
              TextButton(
                onPressed: onTekrarDene,
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
    ];
  }
  return const [];
}

/// Ada göre sıralı satırları baş harf gruplarına böler: her harfin yapışkan
/// başlığı ve altında ince ayraçlı satırlar.
///
/// Başlıkta sayı yok — liste sayfalı geldiği için harfin kaç kişisi olduğu
/// son sayfa gelene kadar bilinmiyor.
///
/// Her harf kendi `SliverMainAxisGroup`'unda: yapışkan başlık yalnız kendi
/// grubunun içinde asılı kalır, grup bitince yukarı itilir. Grupsuz
/// başlıklar ekranın tepesinde üst üste yığılıyordu (A, B, C…).
List<Widget> harfGrubuSliverlari<T>(
  BuildContext context, {
  required List<T> ogeler,
  required String Function(T) ad,
  required Widget Function(BuildContext, T) satir,
}) {
  final yukseklik = listeGrupBasligiYuksekligi(context);
  return [
    for (final (harf, grup) in harfGruplari(ogeler, ad))
      SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: ListeGrupBasligiDelegate(
              baslik: harf,
              yukseklik: yukseklik,
            ),
          ),
          SliverList.builder(
            itemCount: grup.length,
            itemBuilder: (context, index) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index > 0) const ListeAyraci(),
                satir(context, grup[index]),
              ],
            ),
          ),
        ],
      ),
  ];
}
