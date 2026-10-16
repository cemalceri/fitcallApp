// lib/screens/3_antrenor/program/antrenor_program_page.dart
//
// Antrenörün salt-okunur "Tüm Program"ı: ofisin haftalık ızgarasının aynısı
// (ortak ProgramGorunumu), tüm antrenörlerin dersleri. Izgarada değişiklik
// yapılamaz — boş hücre dokunuşu bağlanmaz, derse dokununca yalnız bilgi
// açılır. Tek eylem "Ders kayıt talebi": ofis onaylayınca ders programa eklenir.
//
// Veri antrenorHaftalikProgram ucundan gelir; ders alanları sunucuda beyaz
// listeden geçer (iptal nedeni, onay durumu, misafir adları yok).
// Takvim sayfasının başlığındaki ikondan, seçili günle açılır.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/program/program_gorunumu.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_kayit_talebi_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/ders_kayit_talebi_sheet.dart';
import 'widgets/program_bilgi_sheet.dart';

class AntrenorProgramPage extends StatefulWidget {
  const AntrenorProgramPage({super.key});

  @override
  State<AntrenorProgramPage> createState() => _AntrenorProgramPageState();
}

class _AntrenorProgramPageState extends State<AntrenorProgramPage> {
  HaftalikProgram? _program;
  bool _yukleniyor = true;
  String? _hata;
  DateTime _secilenGun = simdiKulup();
  bool _argumanOkundu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumanOkundu) return;
    _argumanOkundu = true;
    // Takvimden {tarih: 'YYYY-MM-DD'} ile açılır.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final tarih = parseApiGun(args['tarih']?.toString());
      if (tarih != null) _secilenGun = tarih;
    }
    _yukle();
  }

  DateTime get _gunBasi =>
      DateTime(_secilenGun.year, _secilenGun.month, _secilenGun.day);

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final sonuc = await DersKayitTalebiService.antrenorHaftalikProgram(
          tarih: _secilenGun);
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

  Future<void> _talepAc() async {
    final program = _program;
    if (program == null) return;
    final mesaj = await DersKayitTalebiSheet.ac(
      context,
      kortlar: program.kortlar,
      varsayilan: TalepVarsayilani.hesapla(
        program: program,
        gun: _gunBasi,
        simdi: simdiKulup(),
      ),
    );
    if (mesaj == null || !mounted) return;
    ShowMessage.success(context, mesaj);
    await _yukle();
  }

  Future<void> _talebeDokunuldu(DersKayitTalebi talep) async {
    final geriCekildi = await ProgramTalepBilgiSheet.ac(context, talep);
    if (!geriCekildi || !mounted) return;
    ShowMessage.success(context, 'Talep geri çekildi.');
    await _yukle();
  }

  @override
  Widget build(BuildContext context) {
    final program = _program;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: _yukleniyor || _hata != null || program == null
            ? Column(
                children: [
                  _yuklenirkenBaslik(),
                  Expanded(child: _durumGovdesi()),
                ],
              )
            : ProgramGorunumu(
                program: program,
                secilenGun: _gunBasi,
                baslik: 'Tüm Program',
                onGeri: () => Navigator.maybePop(context),
                onOncekiHafta: () => _haftaDegistir(-1),
                onSonrakiHafta: () => _haftaDegistir(1),
                onBugun: _bugune,
                onGunSec: _gunSec,
                vurgulaAntrenorId: program.benimAntrenorId,
                onDersTap: (d) => ProgramDersBilgiSheet.ac(
                  context,
                  d,
                  benim: program.benimAntrenorId != null &&
                      d.antrenorId == program.benimAntrenorId,
                ),
                onTalepTap: _talebeDokunuldu,
              ),
      ),
      floatingActionButton: program == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _talepAc,
              icon: const Icon(Icons.add),
              label: const Text('Ders kayıt talebi'),
            ),
    );
  }

  Widget _yuklenirkenBaslik() {
    return BaslikBandi(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 6),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Geri',
            ),
            const Expanded(
              child: Text(
                'Tüm Program',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durumGovdesi() {
    if (_yukleniyor) return const IskeletTakvim();
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
