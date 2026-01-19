// lib/screens/7_yonetici/uyeler/uyeler_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_istatistik_kartlar.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_liste_item.dart';

class UyelerPage extends StatefulWidget {
  const UyelerPage({super.key});

  @override
  State<UyelerPage> createState() => _UyelerPageState();
}

class _UyelerPageState extends State<UyelerPage> {
  final TextEditingController _aramaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  UyelerData? _data;
  bool _loading = true;
  bool _loadingMore = false;
  String? _errorMessage;

  String _filtre = 'tumu'; // 'aktif', 'pasif', 'tumu'
  int _sayfa = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _aramaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _data != null &&
        _sayfa < _data!.toplamSayfa) {
      _loadMore();
    }
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      _sayfa = 1;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await YoneticiApiService.getUyeler(
        sayfa: _sayfa,
        arama: _aramaController.text,
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

  Future<void> _loadMore() async {
    if (_loadingMore || _data == null || _sayfa >= _data!.toplamSayfa) return;

    setState(() => _loadingMore = true);

    try {
      final result = await YoneticiApiService.getUyeler(
        sayfa: _sayfa + 1,
        arama: _aramaController.text,
        filtre: _filtre,
      );
      if (mounted && result.data != null) {
        setState(() {
          _sayfa++;
          _data = UyelerData(
            istatistikler: result.data!.istatistikler,
            uyeler: [..._data!.uyeler, ...result.data!.uyeler],
            toplamSayfa: result.data!.toplamSayfa,
            mevcutSayfa: result.data!.mevcutSayfa,
          );
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onFiltreChanged(String filtre) {
    setState(() => _filtre = filtre);
    _loadData(refresh: true);
  }

  void _onArama(String value) {
    _loadData(refresh: true);
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
                      'Üyeler',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Arama
                    TextField(
                      controller: _aramaController,
                      onChanged: _onArama,
                      decoration: InputDecoration(
                        hintText: 'İsim, telefon veya üye no ile ara...',
                        prefixIcon: const Icon(Icons.search, size: 20),
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
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _data == null) {
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
                onPressed: () => _loadData(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_data == null || _data!.uyeler.isEmpty) {
      return Center(
        child: Text(
          'Üye bulunamadı',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _data!.uyeler.length + 2, // +1 istatistikler, +1 loading
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: UyeIstatistikKartlar(data: _data!.istatistikler),
            );
          }
          if (index == _data!.uyeler.length + 1) {
            return _loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox(height: 80);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: UyeListeItemWidget(uye: _data!.uyeler[index - 1]),
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
