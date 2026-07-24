// lib/screens/7_yonetici/program/widgets/program_izgara.dart
//
// Günün kort × saat ızgarası.
//
// Yerleşim: sol tarafta sabit saat kolonu, sağda yatay kaydırmalı kort kolonları.
// Kort başlıkları gövdeyle aynı yatay ofseti paylaşır (iki ScrollController
// birbirine bağlı), böylece dikey kaydırmada başlıklar yerinde kalır.
// Dış Column'un yüksekliği sınırlı olduğundan gövde Expanded içinde; taşma yok.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:flutter/material.dart';

import 'program_constants.dart';
import 'program_ders_blok.dart';

/// Aynı kortta çakışan dersleri yan yana yerleştirmek için hesaplanan konum.
class _Yerlesim {
  final ProgramDersi ders;
  final double ust;
  final double yukseklik;
  final int kolon;
  final int kolonSayisi;

  _Yerlesim({
    required this.ders,
    required this.ust,
    required this.yukseklik,
    required this.kolon,
    required this.kolonSayisi,
  });
}

class ProgramIzgara extends StatefulWidget {
  final List<SecenekKort> kortlar;
  final List<ProgramDersi> dersler;
  final DateTime secilenGun;
  final ValueChanged<ProgramDersi> onDersTap;

  /// Boş bir zaman aralığına dokunulduğunda (kort, başlangıç) verir.
  final void Function(SecenekKort kort, DateTime baslangic)? onBosSlotTap;

  const ProgramIzgara({
    super.key,
    required this.kortlar,
    required this.dersler,
    required this.secilenGun,
    required this.onDersTap,
    this.onBosSlotTap,
  });

  @override
  State<ProgramIzgara> createState() => _ProgramIzgaraState();
}

class _ProgramIzgaraState extends State<ProgramIzgara> {
  final ScrollController _govdeYatay = ScrollController();
  final ScrollController _baslikYatay = ScrollController();

  @override
  void initState() {
    super.initState();
    _govdeYatay.addListener(_yataySenkronize);
  }

  void _yataySenkronize() {
    if (!_baslikYatay.hasClients || !_govdeYatay.hasClients) return;
    final hedef = _govdeYatay.offset.clamp(
      _baslikYatay.position.minScrollExtent,
      _baslikYatay.position.maxScrollExtent,
    );
    if ((_baslikYatay.offset - hedef).abs() > 0.5) {
      _baslikYatay.jumpTo(hedef);
    }
  }

  @override
  void dispose() {
    _govdeYatay.removeListener(_yataySenkronize);
    _govdeYatay.dispose();
    _baslikYatay.dispose();
    super.dispose();
  }

  /// Izgaranın saat aralığı: varsayılan 07-23, veri dışarı taşarsa genişletilir.
  (int, int) get _saatAraligi {
    var bas = ProgramOlculeri.varsayilanBaslangicSaati;
    var bit = ProgramOlculeri.varsayilanBitisSaati;
    for (final d in widget.dersler) {
      if (d.baslangic.hour < bas) bas = d.baslangic.hour;
      final bitisSaati = d.bitis.minute > 0 ? d.bitis.hour + 1 : d.bitis.hour;
      if (bitisSaati > bit) bit = bitisSaati;
    }
    if (bit <= bas) bit = bas + 1;
    return (bas, bit.clamp(bas + 1, 24));
  }

  /// Bir kortun derslerini çakışma gruplarına ayırıp kolon indeksi atar.
  List<_Yerlesim> _kortYerlesimi(List<ProgramDersi> kortDersleri, int baslangicSaati) {
    if (kortDersleri.isEmpty) return const [];

    final sirali = [...kortDersleri]
      ..sort((a, b) => a.baslangic.compareTo(b.baslangic));

    final sonuc = <_Yerlesim>[];
    var grup = <ProgramDersi>[];
    DateTime? grupBitis;

    void grubuYerlestir() {
      if (grup.isEmpty) return;
      // Grup içinde ilk uygun kolona yerleştir
      final kolonSonlari = <DateTime>[];
      final atamalar = <int>[];
      for (final d in grup) {
        var atandi = -1;
        for (var i = 0; i < kolonSonlari.length; i++) {
          if (!d.baslangic.isBefore(kolonSonlari[i])) {
            kolonSonlari[i] = d.bitis;
            atandi = i;
            break;
          }
        }
        if (atandi == -1) {
          kolonSonlari.add(d.bitis);
          atandi = kolonSonlari.length - 1;
        }
        atamalar.add(atandi);
      }
      for (var i = 0; i < grup.length; i++) {
        final d = grup[i];
        sonuc.add(_Yerlesim(
          ders: d,
          ust: ProgramZaman.zamandanPiksel(d.baslangic, baslangicSaati),
          yukseklik: ProgramZaman.sureyeGoreYukseklik(d.sureDakika),
          kolon: atamalar[i],
          kolonSayisi: kolonSonlari.length,
        ));
      }
      grup = <ProgramDersi>[];
      grupBitis = null;
    }

    for (final d in sirali) {
      if (grup.isEmpty || (grupBitis != null && d.baslangic.isBefore(grupBitis!))) {
        grup.add(d);
        grupBitis = (grupBitis == null || d.bitis.isAfter(grupBitis!))
            ? d.bitis
            : grupBitis;
      } else {
        grubuYerlestir();
        grup.add(d);
        grupBitis = d.bitis;
      }
    }
    grubuYerlestir();
    return sonuc;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kortlar.isEmpty) {
      return const Center(child: Text('Tanımlı kort bulunamadı.'));
    }

    final (basSaat, bitSaat) = _saatAraligi;
    final toplamYukseklik =
        (bitSaat - basSaat) * ProgramOlculeri.saatYuksekligi;
    final izgaraGenisligi =
        widget.kortlar.length * ProgramOlculeri.kortKolonGenisligi;

    return Column(
      children: [
        _kortBasliklari(),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: toplamYukseklik + 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _saatKolonu(basSaat, bitSaat, toplamYukseklik + 24),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _govdeYatay,
                      child: SizedBox(
                        width: izgaraGenisligi,
                        height: toplamYukseklik + 24,
                        child: Stack(
                          children: [
                            // En altta tek bir dokunma katmanı: boş alana
                            // dokunulunca konumdan kort ve saat hesaplanır.
                            // (Eskiden yarım saatlik hücre başına ayrı bir
                            // GestureDetector vardı — yüzlerce widget, ağır.)
                            if (widget.onBosSlotTap != null)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (d) => _bosAlanaDokunuldu(
                                      d.localPosition, basSaat),
                                ),
                              ),
                            ..._saatCizgileri(basSaat, bitSaat, izgaraGenisligi),
                            ..._kortAyraclari(toplamYukseklik),
                            ..._dersBloklari(basSaat),
                            if (_bugunMu) _simdiCizgisi(basSaat, izgaraGenisligi),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _bugunMu {
    final bugun = DateTime.now();
    return widget.secilenGun.year == bugun.year &&
        widget.secilenGun.month == bugun.month &&
        widget.secilenGun.day == bugun.day;
  }

  Widget _kortBasliklari() {
    return SizedBox(
      height: ProgramOlculeri.kortBaslikYuksekligi,
      child: Row(
        children: [
          const SizedBox(width: ProgramOlculeri.saatKolonGenisligi),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _baslikYatay,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: widget.kortlar
                    .map(
                      (k) => Container(
                        width: ProgramOlculeri.kortKolonGenisligi,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(
                                color: ProgramRenkleri.kortAyraci, width: 1),
                            bottom: BorderSide(
                                color: ProgramRenkleri.kortAyraci, width: 1),
                          ),
                        ),
                        child: Text(
                          k.adi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saatKolonu(int basSaat, int bitSaat, double yukseklik) {
    // Yükseklik AÇIKÇA verilmeli: içi yalnızca Positioned çocuklardan oluşan bir
    // Stack, gevşek kısıt altında kendini sıfır yükseklikte ölçer ve saat
    // etiketleri hiç görünmezdi.
    return SizedBox(
      width: ProgramOlculeri.saatKolonGenisligi,
      height: yukseklik,
      child: Stack(
        children: [
          for (int s = basSaat; s <= bitSaat; s++)
            Positioned(
              top: (s - basSaat) * ProgramOlculeri.saatYuksekligi - 7,
              left: 0,
              right: 6,
              child: Text(
                '${s.toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _saatCizgileri(int basSaat, int bitSaat, double genislik) {
    final cizgiler = <Widget>[];
    for (int s = basSaat; s <= bitSaat; s++) {
      final ust = (s - basSaat) * ProgramOlculeri.saatYuksekligi;
      cizgiler.add(Positioned(
        top: ust,
        left: 0,
        width: genislik,
        child: Container(height: 1, color: ProgramRenkleri.saatCizgisi),
      ));
      if (s < bitSaat) {
        cizgiler.add(Positioned(
          top: ust + ProgramOlculeri.saatYuksekligi / 2,
          left: 0,
          width: genislik,
          child: Container(height: 0.5, color: ProgramRenkleri.yarimSaatCizgisi),
        ));
      }
    }
    return cizgiler;
  }

  List<Widget> _kortAyraclari(double yukseklik) {
    return [
      for (int i = 0; i < widget.kortlar.length; i++)
        Positioned(
          left: i * ProgramOlculeri.kortKolonGenisligi,
          top: 0,
          height: yukseklik,
          child: Container(width: 1, color: ProgramRenkleri.kortAyraci),
        ),
    ];
  }

  /// Boş alana dokunulduğunda konumdan kort ve (yarım saate yuvarlanmış) saati
  /// hesaplar. Ders blokları bu katmanın ÜSTÜNDE olduğundan dolu alanda blok
  /// dokunuşu önceliklidir.
  void _bosAlanaDokunuldu(Offset konum, int basSaat) {
    final kortIndex = (konum.dx / ProgramOlculeri.kortKolonGenisligi).floor();
    if (kortIndex < 0 || kortIndex >= widget.kortlar.length) return;

    final dakikaOfseti = konum.dy / ProgramOlculeri.dakikaBasinaPiksel;
    final toplamDakika = basSaat * 60 + dakikaOfseti;
    if (toplamDakika < 0) return;

    // 30 dakikanın katına yuvarla (backend kuralı)
    final yuvarlanmis = (toplamDakika ~/ 30) * 30;
    final saat = yuvarlanmis ~/ 60;
    if (saat > 23) return;

    widget.onBosSlotTap!(
      widget.kortlar[kortIndex],
      DateTime(
        widget.secilenGun.year,
        widget.secilenGun.month,
        widget.secilenGun.day,
        saat,
        yuvarlanmis % 60,
      ),
    );
  }

  List<Widget> _dersBloklari(int basSaat) {
    final bloklar = <Widget>[];

    for (var ki = 0; ki < widget.kortlar.length; ki++) {
      final kort = widget.kortlar[ki];
      final kortDersleri =
          widget.dersler.where((d) => d.kortId == kort.id).toList();
      final yerlesimler = _kortYerlesimi(kortDersleri, basSaat);

      for (final y in yerlesimler) {
        final kolonGenislik =
            ProgramOlculeri.kortKolonGenisligi / y.kolonSayisi;
        bloklar.add(Positioned(
          left: ki * ProgramOlculeri.kortKolonGenisligi +
              y.kolon * kolonGenislik +
              ProgramOlculeri.blokYatayBosluk,
          top: y.ust,
          width: kolonGenislik - ProgramOlculeri.blokYatayBosluk * 2,
          height: y.yukseklik,
          child: ProgramDersBlok(
            ders: y.ders,
            yukseklik: y.yukseklik,
            onTap: () => widget.onDersTap(y.ders),
          ),
        ));
      }
    }

    // Kortu olmayan dersler (veri tutarsızlığı) kaybolmasın diye kort adı
    // bilinmeyen bir sütunda değil, hiç gösterilmiyor; sayfa altındaki uyarı
    // yerine liste görünümünde erişilebilir kalıyorlar.
    return bloklar;
  }

  Widget _simdiCizgisi(int basSaat, double genislik) {
    final simdi = DateTime.now();
    final ust = ProgramZaman.zamandanPiksel(simdi, basSaat);
    if (ust < 0) return const SizedBox.shrink();

    return Positioned(
      top: ust,
      left: 0,
      width: genislik,
      child: Container(height: 2, color: ProgramRenkleri.simdiCizgisi),
    );
  }
}
