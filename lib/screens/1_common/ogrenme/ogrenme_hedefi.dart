// lib/screens/1_common/ogrenme/ogrenme_hedefi.dart
//
// Yazısı olmayan ya da yazısı veriden gelen öğeyi (ders bloğu, gün hücresi)
// rehbere tanıtır. Çizime ve dokunmaya etkisi yoktur; yalnız kendini kimliğiyle
// kaydeder, rehber konumu buradan bulur.

import 'package:flutter/widgets.dart';

class OgrenmeHedefi extends StatefulWidget {
  /// `Hedef` sabitlerinden biri (hedefler.dart).
  final String id;
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

  void _kaydet(String id) =>
      OgrenmeHedefi._kayit.putIfAbsent(id, () => <BuildContext>{}).add(context);

  void _sil(String id) {
    final kume = OgrenmeHedefi._kayit[id];
    kume?.remove(context);
    if (kume != null && kume.isEmpty) OgrenmeHedefi._kayit.remove(id);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// [id] null ise [child]'ı olduğu gibi döner; ortak widget'larda rol bazında
/// hedef vermeyi kısaltır.
Widget ogrenmeHedefiSar(String? id, Widget child) =>
    id == null ? child : OgrenmeHedefi(id: id, child: child);
