// lib/screens/1_common/duyurular/duyuru_yonetim_page.dart
//
// Yönetici ve ofis: duyurular + kimlerin gördüğü (salt-okunur).
//
// Tasarım 2026-10-09'da geliştirici / ürün yöneticisi / tasarımcı / son
// kullanıcı tartışmasıyla çıktı: iki kabuk aynı ekranı ve aynı ucu kullanır,
// oluşturma/düzenleme web'de kalır (okuma durumu sayfasında "Web panelinde
// aç"). Kabuklar arasındaki tek fark üye satırına dokununca açılan detay
// sayfası; o da rotada geri çağırım olarak verilir, ekran role bakmaz.

import 'package:fitcall/models/1_common/duyuru_okuma_models.dart';
import 'package:fitcall/screens/1_common/duyurular/duyuru_okuma_durumu_page.dart';
import 'package:fitcall/screens/1_common/duyurular/widgets/duyuru_yonetim_listesi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/duyuru_api_service.dart';
import 'package:flutter/material.dart';

/// Kabuğa özgü üye detay sayfasını açar (ofiste ofis, yöneticide yönetici).
typedef UyeDetayAcici = void Function(BuildContext context, HesapProfili profil);

class DuyuruYonetimPage extends StatefulWidget {
  final UyeDetayAcici? uyeDetayAc;

  const DuyuruYonetimPage({super.key, this.uyeDetayAc});

  @override
  State<DuyuruYonetimPage> createState() => _DuyuruYonetimPageState();
}

class _DuyuruYonetimPageState extends State<DuyuruYonetimPage> {
  List<DuyuruYonetimSatiri>? _duyurular;
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  /// [iskelet] false ise (aşağı çekip yenileme) mevcut liste ekranda kalır.
  Future<void> _yukle({bool iskelet = true}) async {
    if (iskelet) {
      setState(() {
        _yukleniyor = true;
        _hata = null;
      });
    }
    try {
      final sonuc = await DuyuruService.yonetimListesi();
      if (!mounted) return;
      setState(() {
        _duyurular = sonuc.data ?? [];
        _yukleniyor = false;
        _hata = null;
      });
    } catch (e) {
      if (!mounted) return;
      final mesaj = e is ApiException
          ? e.message
          : 'Duyurular yüklenirken bir hata oluştu.';
      if (_duyurular != null && !iskelet) {
        ShowMessage.error(context, mesaj);
        return;
      }
      setState(() {
        _hata = mesaj;
        _yukleniyor = false;
      });
    }
  }

  Future<void> _ac(DuyuruYonetimSatiri d) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuyuruOkumaDurumuPage(
          duyuruId: d.id,
          baslangicBaslik: d.baslik,
          uyeDetayAc: widget.uyeDetayAc,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyurular')),
      body: _govde(),
    );
  }

  Widget _govde() {
    if (_yukleniyor) {
      return const IskeletGecikmeli(child: IskeletListe());
    }
    final hata = _hata;
    if (hata != null) {
      return BosDurum(
        ikon: Icons.cloud_off_rounded,
        baslik: 'Duyurular yüklenemedi',
        aciklama: hata,
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: _yukle,
      );
    }
    return DuyuruYonetimListesi(
      duyurular: _duyurular ?? const [],
      onSec: _ac,
      onYenile: () => _yukle(iskelet: false),
    );
  }
}
