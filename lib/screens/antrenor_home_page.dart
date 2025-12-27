// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// EKLENEN importlar
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';

// Mevcut servis
import 'package:fitcall/services/etkinlik/takvim_service.dart';

import '../services/notification/notification_service.dart';

class AntrenorHomePage extends StatefulWidget {
  const AntrenorHomePage({super.key});

  @override
  State<AntrenorHomePage> createState() => _AntrenorHomePageState();
}

class _AntrenorHomePageState extends State<AntrenorHomePage> {
  /* ---------------- Üst Menü ---------------- */
  final List<_MenuItem> menuItems = [
    _MenuItem(
      route: routeEnums[SayfaAdi.antrenorProfil]!,
      icon: Icons.person_outline_rounded,
      text: 'Bilgilerim',
      color: const Color(0xFF6366F1),
    ),
    _MenuItem(
      route: routeEnums[SayfaAdi.antrenorOgrenciler]!,
      icon: Icons.groups_outlined,
      text: 'Öğrencilerim',
      color: const Color(0xFF10B981),
    ),
    _MenuItem(
      route: routeEnums[SayfaAdi.antrenorDersler]!,
      icon: Icons.sports_tennis_rounded,
      text: 'Derslerim',
      color: const Color(0xFFF59E0B),
    ),
    _MenuItem(
      route: routeEnums[SayfaAdi.qrKodKayit]!,
      icon: Icons.qr_code_rounded,
      text: 'QR Giriş',
      color: const Color(0xFF8B5CF6),
    ),
    _MenuItem(
      route: routeEnums[SayfaAdi.yardim]!,
      icon: Icons.help_outline_rounded,
      text: 'Yardım',
      color: const Color(0xFF64748B),
    ),
  ];

  /* ---------------- Haftalık Program State ---------------- */
  final Map<int, List<EtkinlikModel>> _haftalik = {
    for (var k = 1; k <= 7; k++) k: []
  };
  bool _loadingWeek = true;
  EtkinlikModel? _nextLesson;
  bool _hasMultipleProfiles = false;
  String _antrenorAdi = "";

  @override
  void initState() {
    super.initState();
    NotificationService.refreshUnreadCount();
    _checkProfiles();
    _fetchWeek();
    _loadAntrenorAdi();
  }

  Future<void> _loadAntrenorAdi() async {
    var antrenorModel = await StorageService.antrenorBilgileriniGetir();
    if (antrenorModel != null && mounted) {
      setState(() => _antrenorAdi = antrenorModel.adi);
    }
  }

  Future<void> _checkProfiles() async {
    final jsonStr =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    if (jsonStr != null) {
      final profiles = (jsonDecode(jsonStr) as List)
          .map((e) =>
              KullaniciProfilModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (profiles.length > 1 && mounted) {
        setState(() => _hasMultipleProfiles = true);
      }
    }
  }

  Future<void> _fetchWeek() async {
    try {
      final result = await TakvimService.getirAntrenorHaftalikDersBilgileri();
      final list = result.data ?? [];

      final tmp = {for (var k = 1; k <= 7; k++) k: <EtkinlikModel>[]};
      for (final e in list) {
        tmp[e.baslangicTarihSaat.weekday]!.add(e);
      }

      final now = DateTime.now();
      final filtered =
          list.where((e) => e.baslangicTarihSaat.isAfter(now)).toList();
      final next = filtered.isEmpty
          ? null
          : filtered.reduce((a, b) =>
              a.baslangicTarihSaat.isBefore(b.baslangicTarihSaat) ? a : b);

      if (!mounted) return;
      setState(() {
        _haftalik
          ..clear()
          ..addAll(tmp);
        _nextLesson = next;
        _loadingWeek = false;
      });
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Hata: $e');
      setState(() => _loadingWeek = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
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
          child: RefreshIndicator(
            onRefresh: _fetchWeek,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(colorScheme),
                ),

                // Menü Grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildMenuGrid(colorScheme),
                  ),
                ),

                // Sonraki Ders
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildNextLessonCard(colorScheme),
                  ),
                ),

                // Haftalık Program
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: _buildWeeklySchedule(colorScheme),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _antrenorAdi.isNotEmpty ? _antrenorAdi : 'Hoş geldin',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🎾', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ],
            ),
          ),

          // Aksiyonlar
          Row(
            children: [
              const NotificationsBell(),
              if (_hasMultipleProfiles)
                IconButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final jsonStr = await SecureStorageService.getValue<String>(
                        'kullanici_profiller');
                    if (jsonStr == null) return;
                    final profiles = (jsonDecode(jsonStr) as List)
                        .map((e) => KullaniciProfilModel.fromJson(
                            Map<String, dynamic>.from(e)))
                        .toList();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfilSecPage(profiles)),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.switch_account_rounded,
                      size: 22,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  AuthService.logout(context);
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 22,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Hızlı Erişim',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _MenuCard(
              item: item,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, item.route);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNextLessonCard(ColorScheme colorScheme) {
    final tf = DateFormat('HH:mm');
    final df = DateFormat('d MMMM EEEE', 'tr_TR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Sonraki Ders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _nextLesson == null
              ? _buildNoLessonState(colorScheme)
              : _buildLessonInfo(colorScheme, tf, df),
        ),
      ],
    );
  }

  Widget _buildNoLessonState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 28,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planlanmış ders yok',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yaklaşan dersiniz bulunmuyor',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonInfo(
      ColorScheme colorScheme, DateFormat tf, DateFormat df) {
    final lesson = _nextLesson!;
    final now = DateTime.now();
    final diff = lesson.baslangicTarihSaat.difference(now);

    String countdown;
    Color countdownColor;

    if (diff.inDays > 0) {
      countdown = '${diff.inDays} gün sonra';
      countdownColor = Colors.blue;
    } else if (diff.inHours > 0) {
      countdown = '${diff.inHours} saat sonra';
      countdownColor = Colors.orange;
    } else if (diff.inMinutes > 0) {
      countdown = '${diff.inMinutes} dk sonra';
      countdownColor = Colors.green;
    } else {
      countdown = 'Şimdi!';
      countdownColor = Colors.red;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, routeEnums[SayfaAdi.antrenorDersler]!);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  // Tarih Kutusu
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6366F1),
                          const Color(0xFF6366F1).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          lesson.baslangicTarihSaat.day.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          DateFormat('MMM', 'tr_TR')
                              .format(lesson.baslangicTarihSaat)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Ders Bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                df.format(lesson.baslangicTarihSaat),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: countdownColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                countdown,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: countdownColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _InfoPill(
                              icon: Icons.access_time_rounded,
                              text:
                                  '${tf.format(lesson.baslangicTarihSaat)} - ${tf.format(lesson.bitisTarihSaat)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _InfoPill(
                              icon: Icons.location_on_outlined,
                              text: 'Kort ${lesson.kortAdi}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Detay Butonu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Takvime git',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
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

  Widget _buildWeeklySchedule(ColorScheme colorScheme) {
    const gunler = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final tf = DateFormat('HH:mm');
    final today = DateTime.now().weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text(
                'Haftalık Program',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(
                      context, routeEnums[SayfaAdi.antrenorDersler]!);
                },
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const Text('Takvim'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: _loadingWeek
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (_, i) {
                    final dayIdx = i + 1;
                    final dersler = _haftalik[dayIdx] ?? [];
                    final isToday = dayIdx == today;

                    return _DayCard(
                      day: gunler[i],
                      isToday: isToday,
                      lessons: dersler,
                      timeFormat: tf,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Menu Item Model                               */
/* -------------------------------------------------------------------------- */

class _MenuItem {
  final String route;
  final IconData icon;
  final String text;
  final Color color;

  const _MenuItem({
    required this.route,
    required this.icon,
    required this.text,
    required this.color,
  });
}

/* -------------------------------------------------------------------------- */
/*                              Menu Card Widget                              */
/* -------------------------------------------------------------------------- */

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;

  const _MenuCard({required this.item, required this.onTap});

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
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  size: 28,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Info Pill Widget                              */
/* -------------------------------------------------------------------------- */

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Day Card Widget                               */
/* -------------------------------------------------------------------------- */

class _DayCard extends StatelessWidget {
  final String day;
  final bool isToday;
  final List<EtkinlikModel> lessons;
  final DateFormat timeFormat;

  const _DayCard({
    required this.day,
    required this.isToday,
    required this.lessons,
    required this.timeFormat,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasLessons = lessons.isNotEmpty;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFF6366F1).withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? const Color(0xFF6366F1).withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Gün başlığı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFF6366F1)
                    : colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Dersler
            Expanded(
              child: hasLessons
                  ? ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: lessons.length,
                      itemBuilder: (_, i) {
                        final lesson = lessons[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            timeFormat.format(lesson.baslangicTarihSaat),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'Boş',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
