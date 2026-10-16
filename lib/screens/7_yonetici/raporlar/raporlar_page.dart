// lib/screens/7_yonetici/raporlar/raporlar_page.dart

import 'package:fitcall/screens/7_yonetici/dashboard/widgets/donem_kutusu.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
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
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/period_filter_tabs.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // İki isteği eşzamanlı başlat
      final raporFuture = YoneticiApiService.getRaporlar(donem: _seciliDonem);
      final haritaFuture =
          YoneticiApiService.getDolulukHaritasi(donem: _seciliDonem);
      final result = await raporFuture;
      final harita = await haritaFuture;
      if (mounted) {
        setState(() {
          _data = result.data;
          _harita = harita.data;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Veriler yüklenirken bir hata oluştu.';
          _loading = false;
        });
      }
    }
  }

  void _onDonemChanged(DonemFiltresi donem) {
    setState(() => _seciliDonem = donem);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sağda seçili dönemin günleri: "Bu Hafta" pazartesiden bugüne.
            SekmeBasligi(
              baslik: 'Raporlar',
              sag: BaslikKapsulu(
                _seciliDonem.aralikMetni(bugunKulup()),
                ikon: Icons.date_range_rounded,
              ),
              alt: PeriodFilterTabs(
                seciliDonem: _seciliDonem,
                onDonemChanged: _onDonemChanged,
              ),
            ),

            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const IskeletKart(anaKartYuksekligi: 110);
    }

    if (_errorMessage != null) {
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
        // Üstte de boşluk: özet kartlar başlık bandının kenarına yapışıyordu.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet kartlar — yalnız seçilen döneme bağlı olanlar; aktif üye
            // (o anki sayı) en altta "Şu an" bölümünde.
            RaporOzetKartlar(
              data: _data!.ozetKartlar.where((k) => !k.anlikMi).toList(),
            ),
            const SizedBox(height: 24),

            // Ciro raporu (ders bazlı)
            CiroRaporuSection(data: _data!.ciroRaporu),
            const SizedBox(height: 24),

            // Tahsilat raporu (ödeme bazlı) - YENİ
            TahsilatRaporuSection(data: _data!.tahsilatRaporu),
            const SizedBox(height: 24),

            // Doluluk ısı haritası (saat x haftanın günü)
            if (_harita != null) ...[
              DolulukHaritasiSection(data: _harita!),
              const SizedBox(height: 24),
            ],

            // Doluluk raporu (kort bazlı)
            DolulukRaporuSection(data: _data!.dolulukRaporu),
            const SizedBox(height: 24),

            // Antrenör performans
            AntrenorPerformansSection(data: _data!.antrenorPerformans),
            const SizedBox(height: 24),

            // Dönemden bağımsız: o anki durum.
            if (_data!.ozetKartlar.any((k) => k.anlikMi)) ...[
              const PanoBolumEtiketi(
                  ikon: Icons.schedule_rounded, etiket: 'Şu an'),
              RaporOzetKartlar(
                data: _data!.ozetKartlar.where((k) => k.anlikMi).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
