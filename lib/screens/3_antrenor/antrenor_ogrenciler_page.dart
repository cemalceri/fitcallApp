// lib/screens/5_etkinlik/antrenor_ogrenciler_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/antrenor/antrenor_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AntrenorOgrencilerPage extends StatefulWidget {
  const AntrenorOgrencilerPage({super.key});

  @override
  State<AntrenorOgrencilerPage> createState() => _AntrenorOgrencilerPageState();
}

class _AntrenorOgrencilerPageState extends State<AntrenorOgrencilerPage>
    with SingleTickerProviderStateMixin {
  List<UyeModel> students = [];
  List<UyeModel> filteredStudents = [];
  bool isLoading = false;
  String searchQuery = '';
  String? selectedSeviye;
  late AnimationController _animationController;

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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _yukleOgrenciler();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      _animationController.forward();
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
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Color _getSeviyeColor(String seviye) {
    return seviyeRenkleri[seviye] ?? Colors.grey;
  }

  void _showStudentDetails(UyeModel student) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentDetailSheet(
        student: student,
        seviyeColor: _getSeviyeColor(student.seviyeRengi),
        age: _calculateAge(student.dogumTarihi),
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
                    ? _buildLoadingState()
                    : filteredStudents.isEmpty
                        ? _buildEmptyState(colorScheme)
                        : _buildStudentGrid(),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Öğrenciler yükleniyor...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            searchQuery.isNotEmpty || selectedSeviye != null
                ? 'Sonuç bulunamadı'
                : 'Henüz öğrenci yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty || selectedSeviye != null
                ? 'Farklı filtreler deneyin'
                : 'Sorumlu olduğunuz öğrenciler burada görünecek',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentGrid() {
    return RefreshIndicator(
      onRefresh: _yukleOgrenciler,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: filteredStudents.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final delay = index * 0.1;
              final animValue = Curves.easeOutBack
                  .transform(
                    (_animationController.value - delay).clamp(0.0, 1.0),
                  )
                  .clamp(0.0, 1.0); // Add clamp here
              return Transform.scale(
                scale: 0.5 + (0.5 * animValue),
                child: Opacity(
                  opacity: animValue,
                  child: child,
                ),
              );
            },
            child: _StudentCard(
              student: filteredStudents[index],
              seviyeColor: _getSeviyeColor(filteredStudents[index].seviyeRengi),
              age: _calculateAge(filteredStudents[index].dogumTarihi),
              onTap: () => _showStudentDetails(filteredStudents[index]),
            ),
          );
        },
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final UyeModel student;
  final Color seviyeColor;
  final int age;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.seviyeColor,
    required this.age,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: seviyeColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: seviyeColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Üst gradient bölümü
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      seviyeColor.withValues(alpha: 0.2),
                      seviyeColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Seviye Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: seviyeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          student.seviyeRengi,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Avatar
                    Positioned(
                      bottom: -30,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surface,
                            border: Border.all(
                              color: seviyeColor,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: seviyeColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: student.profilFotografi != null &&
                                    student.profilFotografi!.isNotEmpty
                                ? Image.network(
                                    student.profilFotografi!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildAvatarPlaceholder(colorScheme),
                                  )
                                : _buildAvatarPlaceholder(colorScheme),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // İsim
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${student.adi} ${student.soyadi}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Bilgi satırları
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (age > 0) ...[
                      Icon(
                        Icons.cake_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$age yaş',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Alt buton
              Container(
                margin: const EdgeInsets.all(12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: seviyeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: seviyeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Detaylar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: seviyeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          '${student.adi[0]}${student.soyadi[0]}',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: seviyeColor,
          ),
        ),
      ),
    );
  }
}

class _StudentDetailSheet extends StatelessWidget {
  final UyeModel student;
  final Color seviyeColor;
  final int age;

  const _StudentDetailSheet({
    required this.student,
    required this.seviyeColor,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
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

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Profil Başlığı
                  _buildProfileHeader(colorScheme),

                  const SizedBox(height: 24),

                  // İletişim Bilgileri
                  _buildSection(
                    title: 'İletişim',
                    icon: Icons.contact_phone_outlined,
                    colorScheme: colorScheme,
                    children: [
                      _buildInfoRow(
                        Icons.phone_outlined,
                        'Telefon',
                        student.telefon ?? 'Belirtilmedi',
                        colorScheme,
                      ),
                      _buildInfoRow(
                        Icons.email_outlined,
                        'E-posta',
                        student.email ?? 'Belirtilmedi',
                        colorScheme,
                      ),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        'Adres',
                        student.adres.isNotEmpty
                            ? student.adres
                            : 'Belirtilmedi',
                        colorScheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Kişisel Bilgiler
                  _buildSection(
                    title: 'Kişisel Bilgiler',
                    icon: Icons.person_outline,
                    colorScheme: colorScheme,
                    children: [
                      _buildInfoRow(
                        Icons.badge_outlined,
                        'Üye No',
                        '${student.uyeNo}',
                        colorScheme,
                      ),
                      _buildInfoRow(
                        Icons.cake_outlined,
                        'Yaş',
                        age > 0 ? '$age yaş' : 'Belirtilmedi',
                        colorScheme,
                      ),
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        'Doğum Tarihi',
                        student.dogumTarihi != null
                            ? '${student.dogumTarihi!.day}/${student.dogumTarihi!.month}/${student.dogumTarihi!.year}'
                            : 'Belirtilmedi',
                        colorScheme,
                      ),
                      _buildInfoRow(
                        Icons.wc_outlined,
                        'Cinsiyet',
                        student.cinsiyet.isNotEmpty
                            ? student.cinsiyet
                            : 'Belirtilmedi',
                        colorScheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tenis Bilgileri
                  _buildSection(
                    title: 'Tenis Bilgileri',
                    icon: Icons.sports_tennis_outlined,
                    colorScheme: colorScheme,
                    children: [
                      _buildSeviyeRow(colorScheme),
                      _buildInfoRow(
                        Icons.history_outlined,
                        'Tenis Geçmişi',
                        student.tenisGecmisiVarMi ?? 'Belirtilmedi',
                        colorScheme,
                      ),
                      _buildInfoRow(
                        Icons.category_outlined,
                        'Program Tercihi',
                        student.programTercihi ?? 'Belirtilmedi',
                        colorScheme,
                      ),
                    ],
                  ),

                  // Eğer çocuk ise aile bilgileri
                  if (student.anneAdiSoyadi != null ||
                      student.babaAdiSoyadi != null) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Aile Bilgileri',
                      icon: Icons.family_restroom_outlined,
                      colorScheme: colorScheme,
                      children: [
                        if (student.anneAdiSoyadi != null) ...[
                          _buildInfoRow(
                            Icons.woman_outlined,
                            'Anne',
                            student.anneAdiSoyadi!,
                            colorScheme,
                          ),
                          if (student.anneTelefon != null)
                            _buildInfoRow(
                              Icons.phone_outlined,
                              'Anne Tel',
                              student.anneTelefon!,
                              colorScheme,
                            ),
                        ],
                        if (student.babaAdiSoyadi != null) ...[
                          _buildInfoRow(
                            Icons.man_outlined,
                            'Baba',
                            student.babaAdiSoyadi!,
                            colorScheme,
                          ),
                          if (student.babaTelefon != null)
                            _buildInfoRow(
                              Icons.phone_outlined,
                              'Baba Tel',
                              student.babaTelefon!,
                              colorScheme,
                            ),
                        ],
                      ],
                    ),
                  ],

                  // Acil Durum
                  if (student.acilDurumKisi != null) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Acil Durum',
                      icon: Icons.emergency_outlined,
                      colorScheme: colorScheme,
                      children: [
                        _buildInfoRow(
                          Icons.person_outline,
                          'Kişi',
                          student.acilDurumKisi!,
                          colorScheme,
                        ),
                        if (student.acilDurumTelefon != null)
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'Telefon',
                            student.acilDurumTelefon!,
                            colorScheme,
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: seviyeColor, width: 4),
            boxShadow: [
              BoxShadow(
                color: seviyeColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: student.profilFotografi != null &&
                    student.profilFotografi!.isNotEmpty
                ? Image.network(
                    student.profilFotografi!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Text(
                          '${student.adi[0]}${student.soyadi[0]}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: seviyeColor,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Text(
                        '${student.adi[0]}${student.soyadi[0]}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: seviyeColor,
                        ),
                      ),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // İsim
        Text(
          '${student.adi} ${student.soyadi}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 8),

        // Seviye Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: seviyeColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_tennis, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                '${student.seviyeRengi} Seviye',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: seviyeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: seviyeColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeviyeRow(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.signal_cellular_alt_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seviye',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: seviyeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    student.seviyeRengi,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
