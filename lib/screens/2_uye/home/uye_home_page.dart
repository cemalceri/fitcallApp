// lib/screens/2_uye/home/uye_home_page.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/2_uye/home/widgets/duyuru_carousel.dart';
import 'package:fitcall/screens/2_uye/home/widgets/flutter_uye_header.dart';
import 'package:fitcall/screens/2_uye/home/widgets/flutter_uye_menu_grid.dart';
import 'package:fitcall/screens/2_uye/home/widgets/flutter_uye_next_lesson_card.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/duyuru_api_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/core/qr_code_api_service.dart';
import 'package:fitcall/services/etkinlik/etkinlik_service.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:flutter/material.dart';

class UyeHomePage extends StatefulWidget {
  const UyeHomePage({super.key});

  @override
  State<UyeHomePage> createState() => _UyeHomePageState();
}

class _UyeHomePageState extends State<UyeHomePage> {
  // Haftalık ders verileri
  bool _loadingWeek = true;
  EtkinlikModel? _nextLesson;

  // Profil ve kullanıcı
  bool _hasMultipleProfiles = false;
  String _uyeAdi = "";
  int? _userId;

  // Event/Davet
  EventModel? _aktifEvent;

  // Duyurular
  List<DuyuruModel> _duyurular = [];
  bool _loadingDuyurular = true;

  @override
  void initState() {
    super.initState();
    NotificationService.refreshUnreadCount();
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([
      _loadUyeAdi(),
      _checkProfiles(),
      _checkAktifEvent(),
      _fetchWeek(),
      _fetchDuyurular(),
    ]);
  }

  Future<void> _loadUyeAdi() async {
    final uyeModel = await StorageService.uyeBilgileriniGetir();
    if (uyeModel != null && mounted) {
      setState(() => _uyeAdi = uyeModel.adi);
    }
  }

  Future<void> _checkProfiles() async {
    final jsonStr =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    if (jsonStr != null) {
      final profiles = (jsonDecode(jsonStr) as List)
          .map((e) => KullaniciProfilModel.fromJson(e))
          .toList();
      if (profiles.length > 1 && mounted) {
        setState(() => _hasMultipleProfiles = true);
      }
    }
  }

  Future<void> _checkAktifEvent() async {
    try {
      final userId = await StorageService.getUserId();
      if (userId == null || userId <= 0) return;

      _userId = userId;

      final result = await QrCodeApiService.getirEventAktifApi(userId: userId);
      if (mounted && result.data != null) {
        setState(() => _aktifEvent = result.data);
      }
    } catch (_) {
      // Sessizce başarısız ol
    }
  }

  Future<void> _fetchWeek() async {
    try {
      final result = await EtkinlikService.getirHaftalikDersBilgilerim();
      final list = result.data ?? [];

      final now = DateTime.now();
      final filtered =
          list.where((e) => e.baslangicTarihSaat.isAfter(now)).toList();
      final next = filtered.isEmpty
          ? null
          : filtered.reduce((a, b) =>
              a.baslangicTarihSaat.isBefore(b.baslangicTarihSaat) ? a : b);

      if (!mounted) return;
      setState(() {
        _nextLesson = next;
        _loadingWeek = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, e.message);
      setState(() => _loadingWeek = false);
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Hata: $e');
      setState(() => _loadingWeek = false);
    }
  }

  Future<void> _fetchDuyurular() async {
    try {
      final result = await DuyuruService.getAktifDuyurular(
        hedefKitle: 'uyeler',
      );
      if (!mounted) return;
      setState(() {
        _duyurular = result.data ?? [];
        _loadingDuyurular = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDuyurular = false);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _fetchWeek(),
      _fetchDuyurular(),
      _checkAktifEvent(),
    ]);
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
            onRefresh: _onRefresh,
            child: CustomScrollView(
              slivers: [
                // ========== HEADER ==========
                SliverToBoxAdapter(
                  child: UyeHeader(
                    uyeAdi: _uyeAdi,
                    hasMultipleProfiles: _hasMultipleProfiles,
                  ),
                ),

                // ========== MENÜ GRID ==========
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: UyeMenuGrid(
                      aktifEvent: _aktifEvent,
                      userId: _userId,
                      onEventReturn: _checkAktifEvent,
                    ),
                  ),
                ),

                // ========== SONRAKİ DERS ==========
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: UyeNextLessonCard(
                      nextLesson: _nextLesson,
                      isLoading: _loadingWeek,
                    ),
                  ),
                ),

                // ========== DUYURULAR (Haftalık Program yerine) ==========
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Duyurular',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // İçerik
                        if (_loadingDuyurular)
                          _buildDuyuruLoading(colorScheme)
                        else if (_duyurular.isEmpty)
                          _buildDuyuruEmpty(colorScheme)
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: DuyuruCarousel(
                              duyurular: _duyurular,
                              height: 180,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Alt boşluk
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 24),
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Duyuru yüklenirken gösterilecek widget
  Widget _buildDuyuruLoading(ColorScheme colorScheme) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Duyuru yokken gösterilecek bilgilendirme kartı
  Widget _buildDuyuruEmpty(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.08),
            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // İkon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              size: 32,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 16),
          // Metin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş Geldiniz! 🎾',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Güncel duyurular burada görünecek. Haberdar olmak için takipte kalın!',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
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
