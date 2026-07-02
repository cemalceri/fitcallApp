// lib/screens/7_yonetici/raporlar/raporlar_page.dart

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.06),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raporlar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detaylı performans, ciro ve tahsilat raporları',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PeriodFilterTabs(
                      seciliDonem: _seciliDonem,
                      onDonemChanged: _onDonemChanged,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet kartlar
            RaporOzetKartlar(data: _data!.ozetKartlar),
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
          ],
        ),
      ),
    );
  }
}
