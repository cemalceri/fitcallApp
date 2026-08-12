// lib/screens/7_yonetici/dashboard/yonetici_dashboard_page.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/borclu_uyeler_page.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/dashboard_header.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/period_filter_tabs.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/stat_cards_grid.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/weekly_chart_card.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/quick_access_section.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/daily_summary_card.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';

class YoneticiDashboardPage extends StatefulWidget {
  /// Sekmeler arası geçiş
  /// (0:Dashboard 1:Raporlar 2:Üyeler 3:Antrenör 4:Dersler 5:Program)
  final void Function(int index)? onTabChange;

  /// Header'daki hamburger; ana kabuğun drawer'ını açar. null ise gizlenir.
  final VoidCallback? onMenuTap;

  const YoneticiDashboardPage({super.key, this.onTabChange, this.onMenuTap});

  @override
  State<YoneticiDashboardPage> createState() => _YoneticiDashboardPageState();
}

class _YoneticiDashboardPageState extends State<YoneticiDashboardPage> {
  DonemFiltresi _seciliDonem = DonemFiltresi.bugun;
  DashboardData? _data;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Üye/antrenör ana sayfalarındaki gibi: zil ve simge rozeti beslensin.
    NotificationService.refreshUnreadCount();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await YoneticiApiService.getDashboard(donem: _seciliDonem);
      if (mounted) {
        setState(() {
          _data = result.data;
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
              colorScheme.surface,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const IskeletDashboard();
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
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            DashboardHeader(onMenuTap: widget.onMenuTap),
            const SizedBox(height: 20),

            // Dönem filtresi
            PeriodFilterTabs(
              seciliDonem: _seciliDonem,
              onDonemChanged: _onDonemChanged,
            ),
            const SizedBox(height: 20),

            // İstatistik kartları
            StatCardsGrid(
              data: _data!,
              onToplamAlacakTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BorcluUyelerPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Haftalık ciro/tahsilat grafiği
            WeeklyChartCard(
              ciroData: _data!.haftalikCiro,
              tahsilatData: _data!.haftalikTahsilat,
              onDetayTap: () => widget.onTabChange?.call(1), // Raporlar
            ),
            const SizedBox(height: 20),

            // Hızlı erişim
            QuickAccessSection(
              data: _data!,
              onRaporlarTap: () => widget.onTabChange?.call(1), // Raporlar
              onAntrenorTap: () => widget.onTabChange?.call(3), // Antrenörler
              onDerslerTap: () => widget.onTabChange?.call(4), // Dersler
            ),
            const SizedBox(height: 16),

            // Günün özeti
            DailySummaryCard(data: _data!.gununOzeti),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
