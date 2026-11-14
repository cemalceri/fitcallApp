// lib/screens/2_uye/bildirim_tercihleri/bildirim_tercihleri_page.dart
//
// Ayarlar > "Bildirim tercihleri" (yalnız üye ana hesabı; üye bildirimleri
// ana hesaba gider). Anahtar iyimser güncellenir; kayıt başarısızsa (öğrenme
// modu engeli dahil) eski haline döner. Uyarılı grup (ör. ders teyidi)
// kapatılmadan önce onay alt sayfası açılır.

import 'package:fitcall/models/2_uye/bildirim_tercihi_models.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/2_uye/bildirim_tercihleri/widgets/bildirim_tercihleri_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/uye/bildirim_tercihi_service.dart';
import 'package:material_ui/material_ui.dart';

class BildirimTercihleriPage extends StatefulWidget {
  const BildirimTercihleriPage({super.key});

  @override
  State<BildirimTercihleriPage> createState() => _BildirimTercihleriPageState();
}

class _BildirimTercihleriPageState extends State<BildirimTercihleriPage> {
  BildirimTercihleri? _veri;
  String? _hata;
  final Set<String> _kaydedilenler = {};

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _hata = null);
    try {
      final veri = await BildirimTercihiService.getir();
      if (mounted) setState(() => _veri = veri);
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Bildirim tercihleri yüklenemedi.');
    }
  }

  Future<void> _degistir(BildirimTercihGrubu grup, bool acik) async {
    if (!acik && grup.kapatmaUyarisi != null) {
      final onay = await BildirimKapatmaOnayi.goster(context, grup);
      if (!onay || !mounted) return;
    }

    setState(() {
      _veri = _veri?.ileGuncelle(grup.kod, acik);
      _kaydedilenler.add(grup.kod);
    });
    try {
      final (veri, _) = await BildirimTercihiService.kaydet(grup.kod, acik);
      if (!mounted) return;
      setState(() {
        // Başka grubun kaydı sürüyorsa onun iyimser değerini ezme.
        _veri = _kaydedilenler.length > 1
            ? _veri?.ileGuncelle(grup.kod, acik)
            : veri;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _veri = _veri?.ileGuncelle(grup.kod, !acik));
      ShowMessage.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _veri = _veri?.ileGuncelle(grup.kod, !acik));
      ShowMessage.error(context, 'Tercih kaydedilemedi.');
    } finally {
      if (mounted) setState(() => _kaydedilenler.remove(grup.kod));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim tercihleri')),
      body: SafeArea(
        top: false,
        child: BildirimTercihleriGorunumu(
          veri: _veri,
          hata: _hata,
          kaydedilenler: _kaydedilenler,
          onYenile: _yukle,
          onYenidenDene: _yukle,
          onDegistir: _degistir,
        ),
      ),
    );
  }
}
