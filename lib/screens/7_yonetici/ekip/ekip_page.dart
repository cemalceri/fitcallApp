// lib/screens/7_yonetici/ekip/ekip_page.dart
//
// Yönetici → Ekip: ofis çalışanları bu dönemde ne yaptı, bugün kaçta geldi.
// Yalnız raporlama; görsel gövde [EkipGorunumu]'nda.

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/ekip_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_butonu.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/period_filter_tabs.dart';
import 'package:fitcall/screens/7_yonetici/ekip/ekip_detay_page.dart';
import 'package:fitcall/screens/7_yonetici/ekip/widgets/ekip_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:flutter/material.dart';

class EkipPage extends StatefulWidget {
  const EkipPage({super.key});

  @override
  State<EkipPage> createState() => _EkipPageState();
}

class _EkipPageState extends State<EkipPage> {
  DonemFiltresi _donem = DonemFiltresi.bugun;
  EkipData? _data;
  bool _yukleniyor = true;
  String? _hata;

  /// Hızlı art arda dönem seçiminde geç gelen eski yanıt yenisini ezmesin.
  int _istekNo = 0;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  /// [onceki]: dönem değişimiyle çağrıldıysa önceki seçim. İstek başarısız
  /// olursa seçim ona döner ki ekrandaki sayılar seçili dönemle çelişmesin.
  Future<void> _yukle({DonemFiltresi? onceki}) async {
    final no = ++_istekNo;
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final sonuc = await YoneticiApiService.getEkip(donem: _donem);
      if (!mounted || no != _istekNo) return;
      setState(() {
        _data = sonuc.data;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted || no != _istekNo) return;
      final mesaj = e is ApiException ? e.message : 'Ekip bilgisi alınamadı.';
      setState(() {
        if (onceki != null) _donem = onceki;
        _hata = mesaj;
        _yukleniyor = false;
      });
      // Eski veri ekranda duruyorsa tam sayfa hata çizilmez; mesajla bildir.
      if (_data != null) ShowMessage.error(context, mesaj);
    }
  }

  void _donemSec(DonemFiltresi donem) {
    if (donem == _donem) return;
    final onceki = _donem;
    _donem = donem;
    _yukle(onceki: _data == null ? null : onceki);
  }

  void _kisiAc(EkipKisi kisi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EkipDetayPage(kullaniciId: kisi.id, adSoyad: kisi.adSoyad),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekip'),
        actions: [
          OgrenmeButonu(
            sayfa: OgrenmeSayfasi.yoneticiEkip,
            sssRotasi: routeEnums[SayfaAdi.yoneticiYardim]!,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.m, Bosluk.l, 0),
            child: OgrenmeHedefi(
              id: Hedef.ekipDonemSecici,
              child: PeriodFilterTabs(
                seciliDonem: _donem,
                onDonemChanged: _donemSec,
                yuzeyde: true,
              ),
            ),
          ),
          Expanded(child: _icerik()),
        ],
      ),
    );
  }

  Widget _icerik() {
    final data = _data;
    if (_yukleniyor && data == null) {
      return const IskeletKart(anaKartYuksekligi: 90);
    }
    if (_hata != null && data == null) {
      return BosDurum(
        ikon: Icons.error_outline_rounded,
        baslik: 'Ekip bilgisi alınamadı',
        aciklama: _hata!,
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: _yukle,
        ikonRengi: context.cs.error,
      );
    }
    if (data == null) return const SizedBox.shrink();
    return RefreshIndicator(
      onRefresh: _yukle,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.xl),
        child: AnimatedOpacity(
          // Dönem değişirken eski veri soluk durur, sayfa iskelete dönmez.
          opacity: _yukleniyor ? 0.5 : 1,
          duration: const Duration(milliseconds: 150),
          child: EkipGorunumu(data: data, onKisi: _kisiAc),
        ),
      ),
    );
  }
}
