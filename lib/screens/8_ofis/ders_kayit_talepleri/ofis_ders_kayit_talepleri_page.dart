// lib/screens/8_ofis/ders_kayit_talepleri/ofis_ders_kayit_talepleri_page.dart
//
// Ofisin "Talepler" sayfası: Bende · Beklemede · Kapanan.
//   - Üyenin ders / kort kiralama talebi: satıra dokununca detay açılır
//     (hocaya sor, telefonla onay, kayıt oluştur, değişiklik öner, reddet).
//   - Antrenörün ders kayıt talebi (Bende'de): haftalık programın formuyla
//     kayıt ya da gerekçeyle ret (eski akış).
// Web karşılığı /etkinlik/ders-kayit-talepleri. Ana Sayfa'daki bekleyen işler
// satırından ve ofise gelen bildirimden açılır.

import 'package:fitcall/models/10_ofis/ofis_uye_talep_models.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/8_ofis/ders_kayit_talepleri/uye_talep_detay_page.dart';
import 'package:fitcall/screens/8_ofis/program/ofis_program_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/ofis/ofis_uye_talep_service.dart';
import 'package:flutter/material.dart';

import 'talep_islemleri.dart';
import 'widgets/ofis_talepler_gorunumu.dart';

class OfisDersKayitTalepleriPage extends StatefulWidget {
  const OfisDersKayitTalepleriPage({super.key});

  @override
  State<OfisDersKayitTalepleriPage> createState() =>
      _OfisDersKayitTalepleriPageState();
}

class _OfisDersKayitTalepleriPageState
    extends State<OfisDersKayitTalepleriPage> {
  String _sekme = 'bende';
  OfisTalepListesi? _liste;
  String? _hata;
  int? _islenen;
  final _arama = TextEditingController();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _arama.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    final sekme = _sekme;
    setState(() => _hata = null);
    try {
      final liste =
          await OfisUyeTalepService.liste(sekme, arama: _arama.text.trim());
      if (mounted && sekme == _sekme) setState(() => _liste = liste);
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Talepler yüklenemedi.');
    }
  }

  void _sekmeSec(String sekme) {
    if (sekme == _sekme) return;
    setState(() {
      _sekme = sekme;
      _liste = null;
    });
    _yukle();
  }

  Future<void> _uyeTalepAc(OfisUyeTalep talep) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OfisUyeTalepDetayPage(talepId: talep.id),
    ));
    if (mounted) _yukle();
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
        child: OfisTaleplerGorunumu(
          sekme: _sekme,
          liste: _liste,
          hata: _hata,
          islenenTalepId: _islenen,
          aramaKontrol: _arama,
          onGeri: Navigator.of(context).canPop()
              ? () => Navigator.of(context).maybePop()
              : null,
          onSekme: _sekmeSec,
          onYenile: _yukle,
          onYenidenDene: _yukle,
          onAra: (_) => _yukle(),
          onUyeTalepAc: _uyeTalepAc,
          onKayitOlustur: (t) =>
              _islem(t, DersKayitTalebiIslemleri.kayitOlustur),
          onReddet: (t) => _islem(t, DersKayitTalebiIslemleri.reddet),
          onProgramdaGoster: _programdaGoster,
        ),
      ),
    );
  }
}
