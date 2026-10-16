// lib/screens/1_common/degerlendirmeler/degerlendirmeler_page.dart
//
// Bir antrenörün ders değerlendirmeleri — veri katmanı. Yalnız yönetici,
// Antrenörler listesindeki puandan açar; antrenör ve ofis bu ekranı görmez
// (kullanıcı kararı 2026-10-15), sınır sunucuda
// (api/etkinlik/degerlendirmeler.py yalnız yöneticiye açık).
//
// Görsel gövde [DegerlendirmelerGorunumu]'nda.

import 'package:fitcall/common/sayfali_liste.dart';
import 'package:fitcall/models/1_common/degerlendirme_models.dart';
import 'package:fitcall/screens/1_common/degerlendirmeler/widgets/degerlendirme_detayi.dart';
import 'package:fitcall/screens/1_common/degerlendirmeler/widgets/degerlendirmeler_gorunumu.dart';
import 'package:fitcall/services/etkinlik/degerlendirme_service.dart';
import 'package:flutter/material.dart';

class DegerlendirmelerPage extends StatefulWidget {
  final int antrenorId;

  /// Başlığın altında yazan antrenör adı.
  final String antrenorAdi;

  const DegerlendirmelerPage({
    super.key,
    required this.antrenorId,
    required this.antrenorAdi,
  });

  @override
  State<DegerlendirmelerPage> createState() => _DegerlendirmelerPageState();
}

class _DegerlendirmelerPageState extends State<DegerlendirmelerPage> {
  late final SayfaliListe<DersDegerlendirmesi> _liste =
      SayfaliListe<DersDegerlendirmesi>(_getirici(), anahtar: (d) => d.id);

  String _filtre = 'tumu';

  /// Özet yalnız ilk sayfayla gelir; [SayfaliListe.ek] nesil korumalı.
  DegerlendirmeOzeti? get _ozet => _liste.ek as DegerlendirmeOzeti?;

  @override
  void initState() {
    super.initState();
    _liste.addListener(_degisti);
    _liste.yenile();
  }

  @override
  void dispose() {
    _liste.dispose();
    super.dispose();
  }

  void _degisti() {
    if (mounted) setState(() {});
  }

  SayfaGetirici<DersDegerlendirmesi> _getirici() {
    final filtre = _filtre;
    return (sayfa) async {
      final sonuc = await DegerlendirmeService.liste(
        sayfa: sayfa,
        filtre: filtre,
        antrenorId: widget.antrenorId,
      );
      final veri = sonuc.data;
      return SayfaSonucu(
        ogeler: veri?.degerlendirmeler ?? const [],
        toplamSayfa: veri?.toplamSayfa ?? 1,
        toplam: veri?.toplam ?? 0,
        ek: sayfa == 1 ? veri?.ozet : null,
      );
    };
  }

  void _filtreSec(String filtre) {
    if (filtre == _filtre) return;
    setState(() => _filtre = filtre);
    _liste.yenile(getir: _getirici());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DegerlendirmelerGorunumu(
        baslik: 'Değerlendirmeler',
        altBaslik: widget.antrenorAdi,
        degerlendirmeler: _liste.ogeler,
        ozet: _ozet,
        toplam: _liste.toplam,
        yukleniyor: _liste.ilkYukleniyor,
        hata: _liste.hata,
        dahaYukleniyor: _liste.dahaYukleniyor,
        dahaHatasi: _liste.dahaHatasi,
        onDahaFazla: _liste.dahaFazla,
        onDahaTekrarDene: _liste.dahaTekrarDene,
        filtre: _filtre,
        onFiltre: _filtreSec,
        onYenile: () => _liste.yenile(iskelet: false),
        onYenidenDene: _liste.yenile,
        onSec: (d) => degerlendirmeDetayiAc(context, d),
      ),
    );
  }
}
