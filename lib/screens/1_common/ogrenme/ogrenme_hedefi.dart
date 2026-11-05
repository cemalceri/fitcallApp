// lib/screens/1_common/ogrenme/ogrenme_hedefi.dart
//
// Yazısı olmayan ya da yazısı veriden gelen öğeyi (ders bloğu, gün hücresi)
// rehbere tanıtır. Çizime ve dokunmaya etkisi yoktur; yalnız kendini kimliğiyle
// kaydeder, rehber konumu buradan bulur.
//
// Saydam isabet kutusu: tıklanamaz bir kartın ortası boşluğa düşse de
// rehber "üstü örtülü mü?" sorusunu bu kutuyla yanıtlar. `translucent`
// dokunuşu ne yutar ne yönlendirir; altındaki öğeler aynen dokunulur.

import 'package:flutter/widgets.dart';

class OgrenmeHedefi extends StatefulWidget {
  /// `Hedef` sabitlerinden biri (hedefler.dart); null ise kayıt yok.
  /// Kimlik veriye göre gelip gidince sarmalayıcı yerinde kalır, çocuğun
  /// durumu (animasyon, odak) sıfırlanmaz.
  final String? id;
  final Widget child;

  const OgrenmeHedefi({super.key, required this.id, required this.child});

  static final Map<String, Set<BuildContext>> _kayit = {};

  /// Kimliği taşıyan, ağaçta duran öğeler (ekleme sırasıyla).
  static Iterable<BuildContext> kayitlilar(String id) =>
      _kayit[id] ?? const <BuildContext>{};

  @override
  State<OgrenmeHedefi> createState() => _OgrenmeHedefiState();
}

class _OgrenmeHedefiState extends State<OgrenmeHedefi> {
  @override
  void initState() {
    super.initState();
    _kaydet(widget.id);
  }

  @override
  void didUpdateWidget(OgrenmeHedefi eski) {
    super.didUpdateWidget(eski);
    if (eski.id != widget.id) {
      _sil(eski.id);
      _kaydet(widget.id);
    }
  }

  @override
  void dispose() {
    _sil(widget.id);
    super.dispose();
  }

  void _kaydet(String? id) {
    if (id == null) return;
    OgrenmeHedefi._kayit.putIfAbsent(id, () => <BuildContext>{}).add(context);
  }

  void _sil(String? id) {
    if (id == null) return;
    final kume = OgrenmeHedefi._kayit[id];
    kume?.remove(context);
    if (kume != null && kume.isEmpty) OgrenmeHedefi._kayit.remove(id);
  }

  @override
  Widget build(BuildContext context) =>
      MetaData(behavior: HitTestBehavior.translucent, child: widget.child);
}

/// Ortak widget'larda rol ya da veri bazında hedef vermeyi kısaltır; [id]
/// null olsa da sarar (bkz. [OgrenmeHedefi.id]).
Widget ogrenmeHedefiSar(String? id, Widget child) =>
    OgrenmeHedefi(id: id, child: child);
