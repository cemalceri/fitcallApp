// lib/screens/7_yonetici/raporlar/raporlar_page.dart

import 'package:fitcall/screens/7_yonetici/dashboard/widgets/donem_kutusu.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/doluluk_haritasi_model.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/doluluk_haritasi_section.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/rapor_ozet_kartlar.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/ciro_raporu_section.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/tahsilat_raporu_section.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/doluluk_raporu_section.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/antrenor_performans_section.dart';

/// Raporlar: dönem seçimi panodaki gibi içerikte (kullanıcı isteği
/// 2026-10-16). İki grup, ikisi de seçili döneme bağlı:
///   1. dönem kutusu — seçici + özet kartlar + ciro + tahsilat
///   2. kort ve antrenör — ısı haritası + kort doluluğu + antrenörler
/// Uzun listeler (ciro/tahsilat günleri, kortlar, antrenörler) kendi
/// kartlarında kayar. Aktif üye kartı (o anki sayı, dönemden bağımsız)
/// burada gösterilmez; panoda "Şu an" altında.
class RaporlarPage extends StatefulWidget {
  const RaporlarPage({super.key});

  @override
  State<RaporlarPage> createState() => _RaporlarPageState();
}

class _RaporlarPageState extends State<RaporlarPage> {
  DonemFiltresi _seciliDonem = DonemFiltresi.buHafta;
  RaporlarData? _data;
  DolulukHaritasi? _harita;
  bool _loading = true;
  String? _errorMessage;

  /// Dönem değişti, sayfa yerinde; iki grubun içi iskelette.
  bool _donemYukleniyor = false;

  /// Hızlı art arda dönem seçiminde geç gelen eski yanıt yenisini ezmesin.
  int _istekNo = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<(RaporlarData?, DolulukHaritasi?)> _getir(DonemFiltresi donem) async {
    // İki isteği eşzamanlı başlat
    final raporFuture = YoneticiApiService.getRaporlar(donem: donem);
    final haritaFuture = YoneticiApiService.getDolulukHaritasi(donem: donem);
    final rapor = await raporFuture;
    final harita = await haritaFuture;
    return (rapor.data, harita.data);
  }

  Future<void> _loadData() async {
    final no = ++_istekNo;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final (rapor, harita) = await _getir(_seciliDonem);
      if (mounted && no == _istekNo) {
        setState(() {
          _data = rapor;
          _harita = harita;
          _loading = false;
          _donemYukleniyor = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted && no == _istekNo) {
        setState(() {
          _errorMessage = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && no == _istekNo) {
        setState(() {
          _errorMessage = 'Veriler yüklenirken bir hata oluştu.';
          _loading = false;
        });
      }
    }
  }

  /// Panodaki gibi: dönem değişince sayfa iskelete dönmez, yalnız iki grubun
  /// içi yenilenir. Hata olursa önceki seçime dönülür.
  Future<void> _onDonemChanged(DonemFiltresi donem) async {
    if (_data == null) {
      setState(() => _seciliDonem = donem);
      _loadData();
      return;
    }
    final onceki = _seciliDonem;
    final no = ++_istekNo;
    setState(() {
      _seciliDonem = donem;
      _donemYukleniyor = true;
    });
    try {
      final (rapor, harita) = await _getir(donem);
      if (!mounted || no != _istekNo) return;
      setState(() {
        _data = rapor ?? _data;
        _harita = harita;
        _donemYukleniyor = false;
      });
    } catch (e) {
      if (!mounted || no != _istekNo) return;
      setState(() {
        _seciliDonem = onceki;
        _donemYukleniyor = false;
      });
      ShowMessage.error(
        context,
        e is ApiException ? e.message : 'Veriler yüklenirken bir hata oluştu.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dönem seçimi ve seçili günler içerikteki dönem kutusunda.
            const SekmeBasligi(baslik: 'Raporlar'),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Aşağı çekip yenilemede rapor yerinde durur; iskelet yalnız ilk açılışta.
    if (_loading && _data == null) {
      return const IskeletKart(anaKartYuksekligi: 110);
    }

    if (_errorMessage != null && _data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_data == null) {
      return const Center(child: Text('Veri bulunamadı'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Seçici + özet kartlar + ciro + tahsilat
            DonemKutusu(
              seciliDonem: _seciliDonem,
              onDonemChanged: _onDonemChanged,
              yukleniyor: _donemYukleniyor,
              iskeletYukseklikleri: const [100, 220, 220],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RaporOzetKartlar(
                    data: _data!.ozetKartlar.where((k) => !k.anlikMi).toList(),
                  ),
                  const SizedBox(height: 16),
                  CiroRaporuSection(data: _data!.ciroRaporu),
                  const SizedBox(height: 16),
                  TahsilatRaporuSection(data: _data!.tahsilatRaporu),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Aynı dönemin kort ve antrenör raporları
            DonemGrubu(
              ikon: Icons.sports_tennis_rounded,
              baslik: 'Kort ve antrenör',
              donem: _seciliDonem,
              yukleniyor: _donemYukleniyor,
              iskeletYukseklikleri: const [220, 220, 220],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Doluluk ısı haritası (saat x haftanın günü)
                  if (_harita != null) ...[
                    DolulukHaritasiSection(data: _harita!),
                    const SizedBox(height: 16),
                  ],
                  DolulukRaporuSection(data: _data!.dolulukRaporu),
                  const SizedBox(height: 16),
                  AntrenorPerformansSection(data: _data!.antrenorPerformans),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
