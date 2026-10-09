// lib/screens/1_common/duyurular/duyuru_okuma_durumu_page.dart

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/duyuru_okuma_models.dart';
import 'package:fitcall/screens/1_common/duyurular/duyuru_yonetim_page.dart';
import 'package:fitcall/screens/1_common/duyurular/widgets/okuma_durumu_gorunumu.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/duyuru_detay_sheet.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/duyuru_api_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bir duyurunun okuma durumu: özet, görenler, görmeyenler.
class DuyuruOkumaDurumuPage extends StatefulWidget {
  final int duyuruId;

  /// Veri inmeden başlıkta görünür.
  final String? baslangicBaslik;
  final UyeDetayAcici? uyeDetayAc;

  const DuyuruOkumaDurumuPage({
    super.key,
    required this.duyuruId,
    this.baslangicBaslik,
    this.uyeDetayAc,
  });

  @override
  State<DuyuruOkumaDurumuPage> createState() => _DuyuruOkumaDurumuPageState();
}

class _DuyuruOkumaDurumuPageState extends State<DuyuruOkumaDurumuPage> {
  DuyuruOkumaDurumu? _veri;
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle({bool iskelet = true}) async {
    if (iskelet) {
      setState(() {
        _yukleniyor = true;
        _hata = null;
      });
    }
    try {
      final sonuc = await DuyuruService.okumaDurumu(widget.duyuruId);
      if (!mounted) return;
      setState(() {
        _veri = sonuc.data;
        _yukleniyor = false;
        _hata = sonuc.data == null ? 'Duyuru bulunamadı.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      final mesaj = e is ApiException
          ? e.message
          : 'Okuma durumu yüklenirken bir hata oluştu.';
      if (_veri != null && !iskelet) {
        ShowMessage.error(context, mesaj);
        return;
      }
      setState(() {
        _hata = mesaj;
        _yukleniyor = false;
      });
    }
  }

  /// Düzenleme ve yayından kaldırma web panelinde (mobil v1 salt-okunur).
  Future<void> _webdeAc(String yol) async {
    final acildi = await launchUrl(
      Uri.parse('$webKokUrl$yol'),
      mode: LaunchMode.externalApplication,
    );
    if (!acildi && mounted) {
      ShowMessage.error(context, 'Web paneli açılamadı.');
    }
  }

  /// Hesapta birden fazla üye profili varsa hangisinin açılacağı sorulur.
  Future<void> _hesapSec(DuyuruHesabi hesap) async {
    final ac = widget.uyeDetayAc;
    if (ac == null) return;
    final profiller = hesap.uyeProfilleri;
    if (profiller.isEmpty) return;
    if (profiller.length == 1) {
      ac(context, profiller.first);
      return;
    }
    final secilen = await showModalBottomSheet<HesapProfili>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Bosluk.l, 0, Bosluk.l, Bosluk.s),
              child: Text('Hangi üye?', style: ctx.metin.titleMedium),
            ),
            for (final p in profiller)
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(p.ad),
                onTap: () => Navigator.of(ctx).pop(p),
              ),
          ],
        ),
      ),
    );
    if (secilen != null && mounted) ac(context, secilen);
  }

  @override
  Widget build(BuildContext context) {
    final veri = _veri;
    final webYolu = veri?.webDuzenleYolu ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Okuma durumu'),
        actions: [
          if (webYolu.isNotEmpty)
            IconButton(
              tooltip: 'Web panelinde aç',
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () => _webdeAc(webYolu),
            ),
        ],
      ),
      body: _govde(),
    );
  }

  Widget _govde() {
    if (_yukleniyor) {
      return const IskeletGecikmeli(
        child: Column(
          children: [
            IskeletKart(),
            Expanded(child: IskeletListe()),
          ],
        ),
      );
    }
    final veri = _veri;
    if (_hata != null || veri == null) {
      return BosDurum(
        ikon: Icons.cloud_off_rounded,
        baslik: 'Okuma durumu yüklenemedi',
        aciklama: _hata ?? 'Duyuru bulunamadı.',
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: _yukle,
      );
    }
    return OkumaDurumuGorunumu(
      veri: veri,
      // Yönetici/ofis içeriğe bakınca kendi "okundu" kaydı yazılmamalı.
      onIcerikGor: () =>
          DuyuruDetaySheet.ac(context, veri.duyuru, okunduIsaretle: false),
      onHesapSec: widget.uyeDetayAc == null ? null : _hesapSec,
      onYenile: () => _yukle(iskelet: false),
    );
  }
}
