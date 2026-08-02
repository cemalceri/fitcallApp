// lib/screens/7_yonetici/dersler/dersler_page.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/dersler/widgets/ders_istatistik_kartlar.dart';
import 'package:fitcall/screens/7_yonetici/dersler/widgets/ders_liste_item.dart';
import 'package:intl/intl.dart';
import 'package:fitcall/common/tarih_util.dart';

class DerslerPage extends StatefulWidget {
  const DerslerPage({super.key});

  @override
  State<DerslerPage> createState() => _DerslerPageState();
}

class _DerslerPageState extends State<DerslerPage> {
  DerslerData? _data;
  bool _loading = true;
  String? _errorMessage;

  DateTime _secilenTarih = simdiKulup();
  String _filtre = 'tumu';

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
      final result = await YoneticiApiService.getDersler(
        tarih: _secilenTarih,
        filtre: _filtre,
      );
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _secilenTarih,
      firstDate: simdiKulup().subtract(const Duration(days: 365)),
      lastDate: simdiKulup().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _secilenTarih = picked);
      _loadData();
    }
  }

  void _previousDay() {
    setState(
        () => _secilenTarih = _secilenTarih.subtract(const Duration(days: 1)));
    _loadData();
  }

  void _nextDay() {
    setState(() => _secilenTarih = _secilenTarih.add(const Duration(days: 1)));
    _loadData();
  }

  void _goToToday() {
    setState(() => _secilenTarih = simdiKulup());
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('d MMMM yyyy, EEEE', 'tr_TR');

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
                      'Dersler',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tarih seçici
                    Row(
                      children: [
                        IconButton(
                          onPressed: _previousDay,
                          icon: const Icon(Icons.chevron_left),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    dateFormat.format(_secilenTarih),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _nextDay,
                          icon: const Icon(Icons.chevron_right),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _goToToday,
                          child: const Text('Bugün'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Filtre
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
            label: 'Tümü',
            selected: _filtre == 'tumu',
            onSelected: () => _onFiltreChanged('tumu'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Tamamlandı',
            selected: _filtre == 'tamamlandi',
            onSelected: () => _onFiltreChanged('tamamlandi'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Bekliyor',
            selected: _filtre == 'bekliyor',
            onSelected: () => _onFiltreChanged('bekliyor'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'İptal',
            selected: _filtre == 'iptal',
            onSelected: () => _onFiltreChanged('iptal'),
          ),
        ],
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
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
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

    if (_data == null || _data!.dersler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Bu tarihte ders bulunamadı',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _data!.dersler.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DersIstatistikKartlar(data: _data!.istatistikler),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DersListeItemWidget(ders: _data!.dersler[index - 1]),
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
