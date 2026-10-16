// lib/screens/8_ofis/ders_kayit_talepleri/ofis_ders_kayit_talepleri_page.dart
//
// Ofisin "Ders kayıt talepleri" sayfası: antrenörün açtığı talepler, en eski
// üstte. Notu okuyup aynı sayfadan haftalık programa ders kaydı oluşturur ya
// da gerekçeyle reddeder. Web karşılığı /etkinlik/ders-kayit-talepleri.
// Ana Sayfa'daki bekleyen işler satırından ve ofise gelen bildirimden açılır.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/8_ofis/program/ofis_program_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_kayit_talebi_service.dart';
import 'package:flutter/material.dart';

import 'talep_islemleri.dart';
import 'widgets/ders_kayit_talepleri_gorunumu.dart';

class OfisDersKayitTalepleriPage extends StatefulWidget {
  const OfisDersKayitTalepleriPage({super.key});

  @override
  State<OfisDersKayitTalepleriPage> createState() =>
      _OfisDersKayitTalepleriPageState();
}

class _OfisDersKayitTalepleriPageState
    extends State<OfisDersKayitTalepleriPage> {
  List<DersKayitTalebi>? _talepler;
  String? _hata;
  int? _islenen;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _hata = null);
    try {
      final liste = await DersKayitTalebiService.bekleyenler();
      if (mounted) setState(() => _talepler = liste);
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Talepler yüklenemedi.');
    }
  }

  Future<void> _islem(DersKayitTalebi talep,
      Future<bool> Function(BuildContext, DersKayitTalebi) is_) async {
    if (_islenen != null) return;
    setState(() => _islenen = talep.id);
    try {
      final tamam = await is_(context, talep);
      if (tamam) await _yukle();
    } finally {
      if (mounted) setState(() => _islenen = null);
    }
  }

  void _programdaGoster(DersKayitTalebi talep) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OfisProgramPage(baslangicTarihi: talep.baslangic),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: DersKayitTalepleriGorunumu(
          talepler: _talepler,
          yukleniyor: _talepler == null && _hata == null,
          hata: _hata,
          islenenTalepId: _islenen,
          onGeri: Navigator.of(context).canPop()
              ? () => Navigator.of(context).maybePop()
              : null,
          onYenile: _yukle,
          onYenidenDene: _yukle,
          onKayitOlustur: (t) =>
              _islem(t, DersKayitTalebiIslemleri.kayitOlustur),
          onReddet: (t) => _islem(t, DersKayitTalebiIslemleri.reddet),
          onProgramdaGoster: _programdaGoster,
        ),
      ),
    );
  }
}
