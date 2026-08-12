// lib/screens/5_etkinlik/antrenor_ogrenciler_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/3_antrenor/ogrenci_detay/antrenor_ogrenci_detay_page.dart';
import 'package:fitcall/services/antrenor/antrenor_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';

class AntrenorOgrencilerPage extends StatefulWidget {
  const AntrenorOgrencilerPage({super.key});

  @override
  State<AntrenorOgrencilerPage> createState() => _AntrenorOgrencilerPageState();
}

class _AntrenorOgrencilerPageState extends State<AntrenorOgrencilerPage> {
  List<UyeModel> students = [];
  List<UyeModel> filteredStudents = [];
  bool isLoading = false;
  String searchQuery = '';
  String? selectedSeviye;

  // Seviye renk haritası
  static const Map<String, Color> seviyeRenkleri = {
    'Kirmizi': Color(0xFFE53935),
    'Turuncu': Color(0xFFFF9800),
    'Sari': Color(0xFFFFEB3B),
    'Yesil': Color(0xFF4CAF50),
    'Mavi': Color(0xFF2196F3),
  };

  @override
  void initState() {
    super.initState();
    _yukleOgrenciler();
  }

  Future<void> _yukleOgrenciler() async {
    setState(() => isLoading = true);
    try {
      final res = await AntrenorApiService.getirOgrencilerim();
      final data = res.data;
      if (data == null) {
        ShowMessage.error(context, res.mesaj);
        return;
      }
      if (!mounted) return;
      setState(() {
        students = data;
        filteredStudents = data;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Öğrenciler alınamadı: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterStudents() {
    setState(() {
      filteredStudents = students.where((student) {
        final matchesSearch = searchQuery.isEmpty ||
            '${student.adi} ${student.soyadi}'
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
        final matchesSeviye =
            selectedSeviye == null || student.seviyeRengi == selectedSeviye;
        return matchesSearch && matchesSeviye;
      }).toList();
    });
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final now = simdiKulup();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Color _getSeviyeColor(String seviye) {
    return seviyeRenkleri[seviye] ??
        Theme.of(context).colorScheme.onSurfaceVariant;
  }

  void _showStudentDetails(UyeModel student) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AntrenorOgrenciDetayPage(
          uyeId: student.id,
          adSoyad: '${student.adi} ${student.soyadi}',
          seviyeRenk: _getSeviyeColor(student.seviyeRengi),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.surface,
              colorScheme.secondary.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern AppBar
              _buildAppBar(colorScheme),

              // Arama ve Filtre
              _buildSearchAndFilter(colorScheme),

              // İstatistik Kartları
              if (!isLoading && students.isNotEmpty)
                _buildStatsRow(colorScheme),

              // Öğrenci Listesi
              Expanded(
                child: isLoading
                    ? const IskeletListe()
                    : filteredStudents.isEmpty
                        ? _buildEmptyState()
                        : _buildOgrenciListesi(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri',
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Öğrencilerim',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                if (students.isNotEmpty)
                  Text(
                    '${students.length} öğrenci',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _yukleOgrenciler,
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(ColorScheme colorScheme) {
    final seviyeler = students.map((s) => s.seviyeRengi).toSet().toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Arama Çubuğu
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              onChanged: (value) {
                searchQuery = value;
                _filterStudents();
              },
              decoration: InputDecoration(
                hintText: 'Öğrenci ara...',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Seviye Filtreleri
          if (seviyeler.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip(
                    label: 'Tümü',
                    isSelected: selectedSeviye == null,
                    color: colorScheme.primary,
                    onTap: () {
                      setState(() => selectedSeviye = null);
                      _filterStudents();
                    },
                  ),
                  ...seviyeler.map((seviye) => _buildFilterChip(
                        label: seviye,
                        isSelected: selectedSeviye == seviye,
                        color: _getSeviyeColor(seviye),
                        onTap: () {
                          setState(() => selectedSeviye = seviye);
                          _filterStudents();
                        },
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(ColorScheme colorScheme) {
    final seviyeStats = <String, int>{};
    for (final student in students) {
      seviyeStats[student.seviyeRengi] =
          (seviyeStats[student.seviyeRengi] ?? 0) + 1;
    }

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: seviyeStats.entries.map((entry) {
          return _buildStatCard(
            label: entry.key,
            count: entry.value,
            color: _getSeviyeColor(entry.key),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    final filtreVar = searchQuery.isNotEmpty || selectedSeviye != null;

    return BosDurum(
      ikon: filtreVar
          ? Icons.search_off_rounded
          : Icons.people_outline_rounded,
      baslik: filtreVar ? 'Sonuç yok' : 'Henüz öğrenci yok',
      aciklama: filtreVar
          ? 'Aramanıza ve seçili seviyeye uyan öğrenci bulunamadı.'
          : 'Sorumlu olduğunuz öğrenciler burada görünecek.',
      eylemEtiketi: filtreVar ? 'Filtreleri temizle' : null,
      eylemIkonu: Icons.clear_rounded,
      onEylem: filtreVar
          ? () {
              setState(() {
                searchQuery = '';
                selectedSeviye = null;
              });
              _filterStudents();
            }
          : null,
    );
  }

  Widget _buildOgrenciListesi() {
    return RefreshIndicator(
      onRefresh: _yukleOgrenciler,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Bosluk.xxl),
        itemCount: filteredStudents.length,
        itemBuilder: (context, index) {
          final ogrenci = filteredStudents[index];
          final yas = _calculateAge(ogrenci.dogumTarihi);
          final adSoyad = '${ogrenci.adi} ${ogrenci.soyadi}';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0) const ListeAyraci(),
              ListeSatiri(
                onGorsel: _OgrenciAvatari(
                  adSoyad: adSoyad,
                  fotograf: ogrenci.profilFotografi,
                ),
                baslik: adSoyad,
                altBaslik: [
                  if (ogrenci.seviyeRengi.isNotEmpty)
                    '${ogrenci.seviyeRengi} seviye',
                  if (yas > 0) '$yas yaş',
                ].join(' · '),
                okGoster: true,
                onTap: () => _showStudentDetails(ogrenci),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Öğrenci avatarı — fotoğraf varsa onu, yoksa baş harfleri gösterir.
class _OgrenciAvatari extends StatelessWidget {
  final String adSoyad;
  final String? fotograf;

  const _OgrenciAvatari({required this.adSoyad, this.fotograf});

  @override
  Widget build(BuildContext context) {
    final harfli = ListeAvatari(basHarfler: ListeAvatari.harfler(adSoyad));

    if (fotograf == null || fotograf!.isEmpty) return harfli;

    return ClipOval(
      child: SizedBox(
        width: 44,
        height: 44,
        child: Image(
          image: CachedNetworkImageProvider(fotograf!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => harfli,
        ),
      ),
    );
  }
}
