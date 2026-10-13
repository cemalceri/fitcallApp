// lib/screens/8_ofis/dersler/onay_bekleyen_gunler_page.dart
//
// Ana Sayfa'daki "Ders onayı"ndan açılır: yönetici kararı bekleyen dersleri
// olan günler, en yeni üstte. Güne dokununca o günün Dersler ekranı "Onay
// bekleyen" süzgeciyle açılır; dönüşte liste tazelenir.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/8_ofis/dersler/ofis_dersler_page.dart';
import 'package:fitcall/screens/8_ofis/dersler/widgets/ofis_dersler_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/ofis/ofis_ders_yonetimi_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OnayBekleyenGunlerPage extends StatefulWidget {
  const OnayBekleyenGunlerPage({super.key});

  @override
  State<OnayBekleyenGunlerPage> createState() => _OnayBekleyenGunlerPageState();
}

class _OnayBekleyenGunlerPageState extends State<OnayBekleyenGunlerPage> {
  OfisBekleyenIsler? _veri;
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle({bool iskelet = true}) async {
    setState(() {
      if (iskelet) _yukleniyor = true;
      _hata = null;
    });
    try {
      final veri = await OfisDersYonetimiService.bekleyenIsler();
      if (!mounted) return;
      setState(() {
        _veri = veri;
        _yukleniyor = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.message;
        _yukleniyor = false;
      });
    }
  }

  Future<void> _gunAc(OnayBekleyenGun gun) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OfisDerslerPage(
        baslangicTarihi: gun.tarih,
        baslangicSuzgeci: DersSuzgeci.onayBekleyen,
      ),
    ));
    if (mounted) _yukle(iskelet: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onay Bekleyen Dersler')),
      body: OnayBekleyenGunlerGorunumu(
        veri: _veri,
        yukleniyor: _yukleniyor,
        hata: _hata,
        onGunSec: _gunAc,
        onYenile: () => _yukle(iskelet: false),
        onYenidenDene: _yukle,
      ),
    );
  }
}

/// Sunum gövdesi (taşma testinde doğrudan çizilir).
class OnayBekleyenGunlerGorunumu extends StatelessWidget {
  final OfisBekleyenIsler? veri;
  final bool yukleniyor;
  final String? hata;
  final ValueChanged<OnayBekleyenGun> onGunSec;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;

  const OnayBekleyenGunlerGorunumu({
    super.key,
    required this.veri,
    required this.yukleniyor,
    required this.hata,
    required this.onGunSec,
    required this.onYenile,
    required this.onYenidenDene,
  });

  static final _gun = DateFormat('d MMMM EEEE', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) return const IskeletListe();
    if (hata != null) {
      return BosDurum(
        ikon: Icons.error_outline_rounded,
        baslik: 'Liste alınamadı',
        aciklama: hata!,
        ikonRengi: context.renkler.hata,
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: onYenidenDene,
      );
    }
    final gunler = veri?.onayGunleri ?? const <OnayBekleyenGun>[];
    if (gunler.isEmpty) {
      return BosDurum(
        ikon: Icons.task_alt_rounded,
        baslik: 'Onay bekleyen ders yok',
        aciklama: 'Son ${veri?.pencereGun ?? 60} günün bütün dersleri '
            'karara bağlanmış.',
        ikonRengi: context.renkler.basari,
      );
    }
    return RefreshIndicator(
      onRefresh: onYenile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Son ${veri!.pencereGun} günde ${veri!.onayBekleyen} ders onay '
              'bekliyor; ${veri!.onayBekleyenAntrenorOnayli} tanesini antrenör '
              '"yapıldı" diye bildirdi. Daha eski dersler web panelinde.',
              style: context.metin.bodySmall,
            ),
          ),
          for (final (i, g) in gunler.indexed) ...[
            if (i > 0) const ListeAyraci(),
            ListeSatiri(
              onGorsel: ListeAvatari(
                basHarfler: '${g.tarih.day}',
                ton: ListeTonu.uyari,
              ),
              baslik: _gun.format(g.tarih),
              altBaslik: g.antrenorOnayli > 0
                  ? '${g.antrenorOnayli} tanesini antrenör onayladı'
                  : 'Antrenör bildirimi yok',
              deger: '${g.bekleyen}',
              altDeger: 'ders',
              okGoster: true,
              onTap: () => onGunSec(g),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
