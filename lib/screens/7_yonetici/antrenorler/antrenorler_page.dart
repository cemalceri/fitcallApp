// lib/screens/9_yonetici/antrenorler/antrenorler_page.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/antrenorler/widgets/antrenor_istatistik_kartlar.dart';
import 'package:fitcall/screens/7_yonetici/antrenorler/widgets/antrenor_liste_item.dart';
import 'package:fitcall/screens/1_common/hakedis/hakedis_ay_panosu_page.dart';
import 'package:fitcall/screens/1_common/hakedis/hakedis_veri_kaynagi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/common/tema.dart';

class AntrenorlerPage extends StatefulWidget {
  const AntrenorlerPage({super.key});

  @override
  State<AntrenorlerPage> createState() => _AntrenorlerPageState();
}

class _AntrenorlerPageState extends State<AntrenorlerPage> {
  AntrenorlerData? _data;
  bool _loading = true;
  String? _errorMessage;
  String _filtre = 'aktif';

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
      final result = await YoneticiApiService.getAntrenorler(filtre: _filtre);
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

  void _onFiltreChanged(String filtre) {
    setState(() => _filtre = filtre);
    _loadData();
  }

  /// Antrenöre dokununca hakediş saatleri panosu — drawer'daki "Hakediş
  /// Saatleri" ile aynı ekran, antrenör seçim adımı atlanmış hâli.
  void _hakedisAc(AntrenorListeItem antrenor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HakedisAyPanosuPage(
          kaynak: YoneticiHakedisKaynagi(antrenor.id),
          baslik: antrenor.adSoyad,
          baslikVeridenGuncellensin: true,
        ),
      ),
    );
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
                      'Antrenörler',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Antrenör listesi ve performans bilgileri',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFiltreler(colorScheme),
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

  Widget _buildFiltreler(ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Aktif',
            selected: _filtre == 'aktif',
            onSelected: () => _onFiltreChanged('aktif'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Pasif',
            selected: _filtre == 'pasif',
            onSelected: () => _onFiltreChanged('pasif'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Tümü',
            selected: _filtre == 'tumu',
            onSelected: () => _onFiltreChanged('tumu'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const IskeletListe();
    }

    if (_errorMessage != null) {
      return BosDurum(
        ikon: Icons.error_outline_rounded,
        baslik: 'Liste alınamadı',
        aciklama: _errorMessage!,
        ikonRengi: context.renkler.hata,
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: _loadData,
      );
    }

    if (_data == null || _data!.antrenorler.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.1),
            const BosDurum(
              ikon: Icons.sports_tennis_outlined,
              baslik: 'Antrenör yok',
              aciklama: 'Bu filtreye uyan antrenör bulunmuyor.',
            ),
          ],
        ),
      );
    }

    final antrenorler = _data!.antrenorler;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Bosluk.xxl),
        itemCount: antrenorler.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                  Bosluk.l, 0, Bosluk.l, Bosluk.l),
              child: AntrenorIstatistikKartlar(data: _data!.istatistikler),
            );
          }
          final antrenor = antrenorler[index - 1];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 1) const ListeAyraci(),
              AntrenorListeItemWidget(
                antrenor: antrenor,
                onTap: () => _hakedisAc(antrenor),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelected();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color:
                selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
