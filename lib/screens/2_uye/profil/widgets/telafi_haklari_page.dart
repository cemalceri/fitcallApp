// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/2_uye/telafi_ders/telafi_ders_model.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/uye/uye_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelafiHaklariPage extends StatefulWidget {
  const TelafiHaklariPage({super.key});

  @override
  State<TelafiHaklariPage> createState() => _TelafiHaklariPageState();
}

class _TelafiHaklariPageState extends State<TelafiHaklariPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  List<TelafiDersModel> _aktifList = [];
  List<TelafiDersModel> _yapilanList = [];
  List<TelafiDersModel> _suresiGecenList = [];

  int _toplamSayisi = 0;
  int _aktifSayisi = 0;
  int _yapilanSayisi = 0;
  int _suresiGecenSayisi = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await UyeApiService.getTelafiDersBilgileri();
      final response = result.data;

      if (response == null) {
        throw ApiException('DATA_ERROR', 'Veri alınamadı');
      }

      // İstatistikleri al
      _toplamSayisi = response.istatistik.toplam;
      _aktifSayisi = response.istatistik.aktif;
      _yapilanSayisi = response.istatistik.yapilan;
      _suresiGecenSayisi = response.istatistik.suresiGecen;

      // Listeyi duruma göre ayır
      _aktifList =
          response.telafiListesi.where((t) => t.durum == 'aktif').toList();
      _yapilanList =
          response.telafiListesi.where((t) => t.durum == 'yapildi').toList();
      _suresiGecenList = response.telafiListesi
          .where((t) => t.durum == 'suresi_doldu')
          .toList();

      setState(() => _isLoading = false);
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Beklenmeyen bir hata oluştu: $e';
      });
    }
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
              Colors.deepPurple.withValues(alpha: 0.1),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Geri',
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Telafi Haklarım',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // İçerik
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Bilinmeyen hata',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yeniden Dene'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // İstatistik Kartı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildStatisticsCard(),
        ),

        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF8C8C8C),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Aktif'),
                    if (_aktifSayisi > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_aktifSayisi',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Yapılan'),
                    if (_yapilanSayisi > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_yapilanSayisi',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Geçmiş'),
                    if (_suresiGecenSayisi > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_suresiGecenSayisi',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Bar View
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTelafiList(_aktifList, 'aktif'),
              _buildTelafiList(_yapilanList, 'yapildi'),
              _buildTelafiList(_suresiGecenList, 'suresi_doldu'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7B2CBF),
            Color(0xFF9D4EDD),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_repeat_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Telafi Hakkı',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_toplamSayisi Ders',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Kullanılabilir',
                  _aktifSayisi,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Kullanılan',
                  _yapilanSayisi,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Geçersiz',
                  _suresiGecenSayisi,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFFFFF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTelafiList(List<TelafiDersModel> list, String durum) {
    if (list.isEmpty) {
      return _buildEmptyState(durum);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final telafi = list[index];
          return _TelafiCard(telafi: telafi, durum: durum);
        },
      ),
    );
  }

  Widget _buildEmptyState(String durum) {
    final colorScheme = Theme.of(context).colorScheme;

    String title = '';
    String subtitle = '';
    IconData icon = Icons.inbox_outlined;

    switch (durum) {
      case 'aktif':
        title = 'Aktif Telafi Hakkı Yok';
        subtitle = 'Şu anda kullanılabilir telafi hakkınız bulunmuyor.';
        icon = Icons.event_available_outlined;
        break;
      case 'yapildi':
        title = 'Yapılan Telafi Yok';
        subtitle = 'Henüz telafi dersi almadınız.';
        icon = Icons.event_busy_outlined;
        break;
      case 'suresi_doldu':
        title = 'Süresi Geçen Telafi Yok';
        subtitle = 'Kullanmadığınız ve süresi geçen telafi hakkınız yok.';
        icon = Icons.event_repeat_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Telafi Card                                   */
/* -------------------------------------------------------------------------- */

class _TelafiCard extends StatelessWidget {
  final TelafiDersModel telafi;
  final String durum;

  const _TelafiCard({
    required this.telafi,
    required this.durum,
  });

  Color _getDurumColor() {
    switch (durum) {
      case 'aktif':
        return Colors.green;
      case 'yapildi':
        return Colors.blue;
      case 'suresi_doldu':
        return Colors.red;
      default:
        return const Color(0xFF8C8C8C);
    }
  }

  String _getDurumLabel() {
    switch (durum) {
      case 'aktif':
        return 'Kullanılabilir';
      case 'yapildi':
        return 'Kullanıldı';
      case 'suresi_doldu':
        return 'Süresi Doldu';
      default:
        return 'Bilinmeyen';
    }
  }

  IconData _getDurumIcon() {
    switch (durum) {
      case 'aktif':
        return Icons.check_circle_outline;
      case 'yapildi':
        return Icons.event_available_outlined;
      case 'suresi_doldu':
        return Icons.event_busy_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // _TelafiCard build metodunda, durum badge'inden sonra ekle:

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final durumColor = _getDurumColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: durumColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: durumColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showDetailSheet(context);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Durum Badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: durumColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: durumColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getDurumIcon(), size: 14, color: durumColor),
                        const SizedBox(width: 6),
                        Text(
                          _getDurumLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: durumColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // *** AKTİF OLANLAR İÇİN KALAN GÜN ***
                  if (durum == 'aktif' && telafi.kalanGun > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: telafi.kalanGun <= 7
                            ? Colors.orange.withValues(alpha: 0.15)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: telafi.kalanGun <= 7
                                ? Colors.orange
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${telafi.kalanGun} gün',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: telafi.kalanGun <= 7
                                  ? Colors.orange
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // *** SÜRESİ GEÇENLER İÇİN SON GEÇERLİLİK TARİHİ ***
                  if (durum == 'suresi_doldu')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_busy_rounded,
                            size: 12,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTarih(telafi.sonGecerlilikTarihi),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // İptal Edilen Ders
              _buildDersInfo(
                context,
                title: 'İptal Edilen Ders',
                icon: Icons.cancel_outlined,
                iconColor: Colors.red,
                ders: telafi.iptalEdilenDers,
              ),

              // Yapılan Ders (eğer varsa)
              if (telafi.yapilanDers != null) ...[
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                _buildDersInfo(
                  context,
                  title: 'Telafi Dersi',
                  icon: Icons.check_circle_outlined,
                  iconColor: Colors.green,
                  ders: telafi.yapilanDers,
                ),
              ],

              // Açıklama (eğer varsa)
              if (telafi.aciklama != null &&
                  telafi.aciklama!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          telafi.aciklama!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

// *** YENİ: Tarih formatlama metodu ekle ***
  String _formatTarih(String isoDate) {
    try {
      final date = parseApiTarihOrNow(isoDate);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  Widget _buildDersInfo(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required dynamic ders,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (ders == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                context,
                Icons.calendar_today_outlined,
                '${ders.tarih} ${ders.saat}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoItem(
                context,
                Icons.sports_tennis_outlined,
                ders.kortAdi,
              ),
            ),
          ],
        ),
        if (ders.antrenorAdi != null) ...[
          const SizedBox(height: 8),
          _buildInfoItem(
            context,
            Icons.person_outline,
            ders.antrenorAdi!,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TelafiDetailSheet(telafi: telafi, durum: durum),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           Telafi Detail Sheet                              */
/* -------------------------------------------------------------------------- */

class _TelafiDetailSheet extends StatelessWidget {
  final TelafiDersModel telafi;
  final String durum;

  const _TelafiDetailSheet({
    required this.telafi,
    required this.durum,
  });

  Color _getDurumColor() {
    switch (durum) {
      case 'aktif':
        return Colors.green;
      case 'yapildi':
        return Colors.blue;
      case 'suresi_doldu':
        return Colors.red;
      default:
        return const Color(0xFF8C8C8C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final durumColor = _getDurumColor();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: durumColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.event_repeat_rounded,
                        size: 32,
                        color: durumColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Telafi Hakkı Detayı',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // İptal Edilen Ders
                _buildDetailSection(
                  context,
                  title: 'İptal Edilen Ders',
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  items: [
                    if (telafi.iptalEdilenDers != null) ...[
                      _DetailRow('Tarih', telafi.iptalEdilenDers!.tarih),
                      _DetailRow('Saat', telafi.iptalEdilenDers!.saat),
                      _DetailRow('Kort', telafi.iptalEdilenDers!.kortAdi),
                      if (telafi.iptalEdilenDers!.antrenorAdi != null)
                        _DetailRow(
                            'Antrenör', telafi.iptalEdilenDers!.antrenorAdi!),
                    ],
                  ],
                ),

                // Yapılan Ders
                if (telafi.yapilanDers != null) ...[
                  const SizedBox(height: 20),
                  _buildDetailSection(
                    context,
                    title: 'Telafi Dersi',
                    icon: Icons.check_circle_outlined,
                    color: Colors.green,
                    items: [
                      _DetailRow('Tarih', telafi.yapilanDers!.tarih),
                      _DetailRow('Saat', telafi.yapilanDers!.saat),
                      _DetailRow('Kort', telafi.yapilanDers!.kortAdi),
                      if (telafi.yapilanDers!.antrenorAdi != null)
                        _DetailRow(
                            'Antrenör', telafi.yapilanDers!.antrenorAdi!),
                    ],
                  ),
                ],
                if (durum == 'aktif' || durum == 'suresi_doldu') ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: durum == 'aktif'
                          ? (telafi.kalanGun <= 7
                              ? Colors.orange.withValues(alpha: 0.1)
                              : colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5))
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: durum == 'aktif'
                            ? (telafi.kalanGun <= 7
                                ? Colors.orange.withValues(alpha: 0.3)
                                : colorScheme.outlineVariant
                                    .withValues(alpha: 0.3))
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          durum == 'aktif'
                              ? Icons.access_time_rounded
                              : Icons.event_busy_rounded,
                          color: durum == 'aktif'
                              ? (telafi.kalanGun <= 7
                                  ? Colors.orange
                                  : colorScheme.primary)
                              : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                durum == 'aktif'
                                    ? 'Son Geçerlilik'
                                    : 'Kullanım Süresi Doldu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(telafi.sonGecerlilikTarihi),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (durum == 'aktif') ...[
                                const SizedBox(height: 4),
                                Text(
                                  telafi.kalanGun > 0
                                      ? '${telafi.kalanGun} gün kaldı'
                                      : 'Bugün son gün!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: telafi.kalanGun <= 7
                                        ? Colors.orange
                                        : colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Açıklamalar
                if (telafi.aciklama != null &&
                    telafi.aciklama!.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'İptal Açıklaması',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          telafi.aciklama!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (telafi.yapilmaAciklama != null &&
                    telafi.yapilmaAciklama!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Telafi Açıklaması',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          telafi.yapilmaAciklama!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Kapat'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<_DetailRow> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              final item = entry.value;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatDate(String sonGecerlilikTarihi) {
    try {
      final date = parseApiTarihOrNow(sonGecerlilikTarihi);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return sonGecerlilikTarihi; // Eğer tarih formatı beklenmedik şekilde gelirse, ham stringi döndür
    }
  }
}

class _DetailRow {
  final String label;
  final String value;

  _DetailRow(this.label, this.value);
}
