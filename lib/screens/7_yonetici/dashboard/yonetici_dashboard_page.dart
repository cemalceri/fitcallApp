// lib/screens/7_yonetici/dashboard/yonetici_dashboard_page.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/dashboard_header.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/donem_kutusu.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
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

  /// "Toplam Alacak" kartı: Üyeler sekmesi "borçlu + en borçlu önce" ön
  /// ayarıyla açılır (ayrı Borçlu Üyeler sayfası kaldırıldı).
  final VoidCallback? onBorcluUyeler;

  const YoneticiDashboardPage({
    super.key,
    this.onTabChange,
    this.onMenuTap,
    this.onBorcluUyeler,
  });

  @override
  State<YoneticiDashboardPage> createState() => _YoneticiDashboardPageState();
}

class _YoneticiDashboardPageState extends State<YoneticiDashboardPage> {
  DonemFiltresi _seciliDonem = DonemFiltresi.bugun;
  DashboardData? _data;
  bool _loading = true;
  String? _errorMessage;

  /// Dönem değişti, sayfa yerinde; yalnız dönem kutusu iskelette.
  bool _donemYukleniyor = false;

  /// Hızlı art arda dönem seçiminde geç gelen eski yanıt yenisini ezmesin.
  int _istekNo = 0;

  @override
  void initState() {
    super.initState();
    // Üye/antrenör ana sayfalarındaki gibi: zil ve simge rozeti beslensin.
    NotificationService.refreshUnreadCount();
    _loadData();
  }

  Future<void> _loadData() async {
    final no = ++_istekNo;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await YoneticiApiService.getDashboard(donem: _seciliDonem);
      if (mounted && no == _istekNo) {
        setState(() {
          _data = result.data;
          _loading = false;
          _donemYukleniyor = false;
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

  /// Dönem değişince sayfa iskelete dönmez (seçici artık içerikte): veri
  /// yerinde kalır, yalnız dönem kutusu yenilenir. Hata olursa önceki seçime
  /// dönülür ki kutudaki sayılar seçili dönemle çelişmesin.
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
      final result = await YoneticiApiService.getDashboard(donem: donem);
      if (!mounted || no != _istekNo) return;
      setState(() {
        _data = result.data ?? _data;
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
    // Başlık bandında yalnız karşılama; dönem seçimi etkilediği kartlarla
    // birlikte içerikteki dönem kutusunda (DonemKutusu).
    return Scaffold(
      body: Column(
        children: [
          BaslikBandi(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: DashboardHeader(onMenuTap: widget.onMenuTap),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Aşağı çekip yenilemede mevcut pano durur; iskelet yalnız ilk açılışta.
    if (_loading && _data == null) {
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
            // Bugünün özeti en üstte (kullanıcı isteği 2026-10-16).
            DailySummaryCard(
              data: _data!.gununOzeti,
              bugunkuDers: _data!.hizliErisimDersler.toplamDers,
            ),
            const SizedBox(height: 20),

            // Seçilen döneme bağlı kartlar, seçiciyle aynı kutuda.
            DonemKutusu(
              seciliDonem: _seciliDonem,
              onDonemChanged: _onDonemChanged,
              yukleniyor: _donemYukleniyor,
              child: StatCardsGrid(data: _data!, grup: PanoKartGrubu.donem),
            ),
            const SizedBox(height: 20),

            // Dönemden bağımsız: o anki durum.
            const PanoBolumEtiketi(
                ikon: Icons.schedule_rounded, etiket: 'Şu an'),
            StatCardsGrid(
              data: _data!,
              grup: PanoKartGrubu.anlik,
              onToplamAlacakTap: () {
                HapticFeedback.lightImpact();
                widget.onBorcluUyeler?.call();
              },
            ),
            const SizedBox(height: 20),

            // Grafik her zaman bu haftanın günleri (Pzt → Paz), dönemden bağımsız.
            const PanoBolumEtiketi(
              ikon: Icons.bar_chart_rounded,
              etiket: 'Bu haftanın günleri',
            ),
            WeeklyChartCard(
              ciroData: _data!.haftalikCiro,
              tahsilatData: _data!.haftalikTahsilat,
              onDetayTap: () => widget.onTabChange?.call(1), // Raporlar
            ),
            const SizedBox(height: 20),

            const PanoBolumEtiketi(ikon: Icons.today_rounded, etiket: 'Bugün'),
            QuickAccessSection(
              data: _data!,
              onRaporlarTap: () => widget.onTabChange?.call(1), // Raporlar
              onAntrenorTap: () => widget.onTabChange?.call(3), // Antrenörler
              onDerslerTap: () => widget.onTabChange?.call(4), // Dersler
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
