// lib/screens/7_yonetici/uyeler/uyeler_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_istatistik_kartlar.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_liste_item.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uye_detay_page.dart';
import 'package:fitcall/screens/7_yonetici/widgets/skeleton.dart';

class UyelerPage extends StatefulWidget {
  const UyelerPage({super.key});

  @override
  State<UyelerPage> createState() => _UyelerPageState();
}

class _UyelerPageState extends State<UyelerPage> {
  final TextEditingController _aramaController = TextEditingController();

  // Tüm liste tek seferde çekilir; arama/filtre client-side yapılır (API dövülmez).
  UyeIstatistik? _istatistik;
  List<UyeListeItem> _tumUyeler = [];
  bool _loading = true;
  String? _errorMessage;

  String _filtre = 'tumu'; // 'tumu' | 'aktif' | 'pasif' | 'borclu'

  @override
  void initState() {
    super.initState();
    _loadData();
    _aramaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await YoneticiApiService.getUyeler(hepsi: true);
      if (mounted) {
        setState(() {
          _istatistik = result.data?.istatistikler;
          _tumUyeler = result.data?.uyeler ?? [];
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Veriler yüklenirken bir hata oluştu.';
          _loading = false;
        });
      }
    }
  }

  /// Client-side arama + filtre.
  List<UyeListeItem> get _filtrelenmis {
    var list = _tumUyeler;

    if (_filtre == 'aktif') {
      list = list.where((u) => u.aktifMi).toList();
    } else if (_filtre == 'pasif') {
      list = list.where((u) => !u.aktifMi).toList();
    } else if (_filtre == 'borclu') {
      list = list.where((u) => u.bakiye < 0).toList();
    }

    final q = _aramaController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((u) =>
              u.adSoyad.toLowerCase().contains(q) ||
              (u.telefon ?? '').contains(q) ||
              u.uyeNo.toString().contains(q))
          .toList();
    }

    if (_filtre == 'borclu') {
      // En borçlu (en negatif bakiye) önce
      list = [...list]..sort((a, b) => a.bakiye.compareTo(b.bakiye));
    }

    return list;
  }

  void _onFiltreChanged(String filtre) {
    setState(() => _filtre = filtre);
  }

  void _acUyeDetay(UyeListeItem uye) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UyeDetayPage(
          uyeId: uye.id,
          baslangicAdSoyad: uye.adSoyad,
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Üyeler',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _aramaController,
                      decoration: InputDecoration(
                        hintText: 'İsim, telefon veya üye no ile ara...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _aramaController.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Temizle',
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => _aramaController.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFiltreler(colorScheme),
                  ],
                ),
              ),
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
            label: 'Borçlular',
            selected: _filtre == 'borclu',
            onSelected: () => _onFiltreChanged('borclu'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const UyeListeSkeleton();
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

    final uyeler = _filtrelenmis;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: uyeler.length + 2, // +1 istatistik, +1 boşluk/boş-durum
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _istatistik != null
                  ? UyeIstatistikKartlar(data: _istatistik!)
                  : const SizedBox.shrink(),
            );
          }
          if (index == uyeler.length + 1) {
            if (uyeler.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'Üye bulunamadı',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }
            return const SizedBox(height: 80);
          }
          final uye = uyeler[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: UyeListeItemWidget(
              uye: uye,
              onTap: () => _acUyeDetay(uye),
            ),
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
