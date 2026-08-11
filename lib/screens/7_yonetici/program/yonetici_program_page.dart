// lib/screens/7_yonetici/program/yonetici_program_page.dart
//
// Yöneticinin haftalık ders programı: gün seçici + kort kolonlu ızgara.
// Web'deki /etkinlik-pilot ekranının mobil karşılığı.
//
// Kayıt/güncelleme/iptal işlemleri backend'de web ile ORTAK servis katmanından
// geçer, dolayısıyla iş kuralları (30 dk katları, telafi hakkı, 24 saat kuralı,
// paket/borç işlemleri) iki tarafta da aynı çalışır.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/yonetici/yonetici_etkinlik_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/ders_iptal_dialog.dart';
import 'widgets/ders_islem_sheet.dart';
import 'widgets/ders_sil_dialog.dart';
import 'widgets/etkinlik_form_sheet.dart';
import 'widgets/program_gorunumu.dart';
import 'package:fitcall/common/tarih_util.dart';

class YoneticiProgramPage extends StatefulWidget {
  const YoneticiProgramPage({super.key});

  @override
  State<YoneticiProgramPage> createState() => _YoneticiProgramPageState();
}

class _YoneticiProgramPageState extends State<YoneticiProgramPage> {
  HaftalikProgram? _program;
  bool _yukleniyor = true;
  bool _islemDevamEdiyor = false;
  String? _hata;

  DateTime _secilenGun = simdiKulup();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  DateTime get _gunBasi =>
      DateTime(_secilenGun.year, _secilenGun.month, _secilenGun.day);

  /* -------------------------------- veri --------------------------------- */

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final sonuc = await YoneticiEtkinlikService.haftalikProgram(
        tarih: _secilenGun,
      );
      if (!mounted) return;
      setState(() {
        _program = sonuc.data;
        _yukleniyor = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.message;
        _yukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hata = 'Program yüklenirken bir hata oluştu.';
        _yukleniyor = false;
      });
    }
  }

  void _haftaDegistir(int haftaFarki) {
    setState(
        () => _secilenGun = _secilenGun.add(Duration(days: 7 * haftaFarki)));
    _yukle();
  }

  void _gunSec(DateTime gun) {
    HapticFeedback.selectionClick();
    setState(() => _secilenGun = gun);
  }

  void _bugune() {
    final bugun = simdiKulup();
    final ayniHafta = _program != null &&
        !bugun.isBefore(_program!.haftaBaslangic) &&
        !bugun.isAfter(_program!.haftaBitis.add(const Duration(days: 1)));
    setState(() => _secilenGun = bugun);
    if (!ayniHafta) _yukle();
  }

  /* ------------------------------- işlemler ------------------------------- */

  /// Uzun süren işlemlerde çift dokunuşu engeller.
  Future<void> _kilitli(Future<void> Function() is_) async {
    if (_islemDevamEdiyor) return;
    setState(() => _islemDevamEdiyor = true);
    try {
      await is_();
    } finally {
      if (mounted) setState(() => _islemDevamEdiyor = false);
    }
  }

  Future<EtkinlikFormVerileri?> _formVerileriGetir({int? etkinlikId}) async {
    try {
      final sonuc =
          await YoneticiEtkinlikService.formVerileri(etkinlikId: etkinlikId);
      return sonuc.data;
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'Form verileri alınamadı.');
    }
    return null;
  }

  Future<void> _yeniDers({int? kortId, DateTime? baslangic}) async {
    await _kilitli(() async {
      final veriler = await _formVerileriGetir();
      if (veriler == null || !mounted) return;

      final istek = await EtkinlikFormSheet.ac(
        context,
        veriler: veriler,
        onSecilenKortId: kortId,
        onSecilenBaslangic: baslangic ?? _gunBasi,
      );
      if (istek == null || !mounted) return;

      await _kaydet(istek);
    });
  }

  Future<void> _dersiDuzenle(ProgramDersi ders) async {
    await _kilitli(() async {
      final veriler = await _formVerileriGetir(etkinlikId: ders.id);
      if (veriler == null || !mounted) return;

      final istek = await EtkinlikFormSheet.ac(context, veriler: veriler);
      if (istek == null || !mounted) return;

      await _kaydet(istek);
    });
  }

  Future<void> _kaydet(EtkinlikKaydetIstegi istek) async {
    try {
      final sonuc = await YoneticiEtkinlikService.kaydet(istek);
      if (!mounted) return;
      ShowMessage.success(context, sonuc.mesaj);
      await _yukle();
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'Ders kaydedilemedi.');
    }
  }

  Future<void> _dersiIptalEt(ProgramDersi ders) async {
    await _kilitli(() async {
      final veriler = await _formVerileriGetir(etkinlikId: ders.id);
      if (veriler == null || !mounted) return;

      final sonuc = await DersIptalDialog.ac(
        context,
        sebepler: veriler.iptalSebepleri,
        modlar: veriler.iptalModlari,
        dersOzeti: '${ders.tarih} ${ders.saat} · ${ders.kortAdi}',
      );
      if (sonuc == null || !mounted) return;

      try {
        final cevap = await YoneticiEtkinlikService.iptalEt(
          etkinlikId: ders.id,
          sebep: sonuc.sebep,
          aciklama: sonuc.aciklama,
          mod: sonuc.mod,
        );
        if (!mounted) return;
        ShowMessage.success(context, cevap.mesaj);
        await _yukle();
      } on ApiException catch (e) {
        if (mounted) ShowMessage.error(context, e.message);
      }
    });
  }

  Future<void> _iptalGeriAl(ProgramDersi ders) async {
    await _kilitli(() async {
      try {
        final cevap =
            await YoneticiEtkinlikService.iptalGeriAl(etkinlikId: ders.id);
        if (!mounted) return;
        ShowMessage.success(context, cevap.mesaj);
        await _yukle();
      } on ApiException catch (e) {
        if (mounted) ShowMessage.error(context, e.message);
      }
    });
  }

  Future<void> _dersiSil(ProgramDersi ders) async {
    await _kilitli(() async {
      SilmeEtkisi? etki;
      try {
        final onizleme =
            await YoneticiEtkinlikService.silmeOnizleme(etkinlikId: ders.id);
        etki = onizleme.data;
      } on ApiException catch (e) {
        if (mounted) ShowMessage.error(context, e.message);
        return;
      }
      if (etki == null || !mounted) return;

      final onay = await DersSilDialog.ac(context, etki);
      if (!onay || !mounted) return;

      try {
        final cevap = await YoneticiEtkinlikService.sil(etkinlikId: ders.id);
        if (!mounted) return;
        ShowMessage.success(context, cevap.mesaj);
        await _yukle();
      } on ApiException catch (e) {
        if (mounted) ShowMessage.error(context, e.message);
      }
    });
  }

  Future<void> _derseDokunuldu(ProgramDersi ders) async {
    final islem = await DersIslemSheet.ac(context, ders);
    if (islem == null || !mounted) return;

    switch (islem) {
      case DersIslemi.duzenle:
        await _dersiDuzenle(ders);
      case DersIslemi.iptalEt:
        await _dersiIptalEt(ders);
      case DersIslemi.iptalGeriAl:
        await _iptalGeriAl(ders);
      case DersIslemi.sil:
        await _dersiSil(ders);
    }
  }

  /* -------------------------------- build -------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _yukleniyor || _hata != null || _program == null
            ? _durumGovdesi()
            : ProgramGorunumu(
                program: _program!,
                secilenGun: _gunBasi,
                islemDevamEdiyor: _islemDevamEdiyor,
                onOncekiHafta: _yukleniyor ? null : () => _haftaDegistir(-1),
                onSonrakiHafta: _yukleniyor ? null : () => _haftaDegistir(1),
                onBugun: _yukleniyor ? null : _bugune,
                onGunSec: _gunSec,
                onDersTap: _derseDokunuldu,
                onBosSlotTap: (kort, baslangic) =>
                    _yeniDers(kortId: kort.id, baslangic: baslangic),
              ),
      ),
      floatingActionButton: _program == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _islemDevamEdiyor ? null : () => _yeniDers(),
              icon: const Icon(Icons.add),
              label: const Text('Yeni ders'),
            ),
    );
  }

  /// Yükleniyor / hata durumları (dolu durum ProgramGorunumu'nda)
  Widget _durumGovdesi() {
    if (_yukleniyor) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hata != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 44, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 14),
              Text(_hata!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _yukle,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
