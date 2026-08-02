// lib/screens/3_antrenor/home/antrenor_home_page.dart

import 'dart:convert';
import 'package:fitcall/models/3_antrenor/home_card_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/antrenor/antrenor_api_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:flutter/material.dart';

// Widgets
import 'package:fitcall/models/3_antrenor/gunluk_ozet_model.dart';
import 'widgets/home_header.dart';
import 'widgets/gunluk_kokpit_card.dart';
import 'widgets/quick_access_grid.dart';
import 'widgets/next_lesson_card.dart';
import 'widgets/info_cards_carousel.dart';
import 'package:fitcall/common/tarih_util.dart';

class AntrenorHomePage extends StatefulWidget {
  const AntrenorHomePage({super.key});

  @override
  State<AntrenorHomePage> createState() => _AntrenorHomePageState();
}

class _AntrenorHomePageState extends State<AntrenorHomePage> {
  // State
  bool _isLoading = true;
  bool _hasMultipleProfiles = false;
  String _antrenorAdi = "";
  EtkinlikModel? _nextLesson;
  List<HomeCardModel> _infoCards = [];
  GunlukOzetModel? _gunlukOzet;

  @override
  void initState() {
    super.initState();
    NotificationService.refreshUnreadCount();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadAntrenorAdi(),
      _checkProfiles(),
      _fetchNextLesson(),
      _fetchInfoCards(),
      _fetchGunlukOzet(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchGunlukOzet() async {
    try {
      final result = await AntrenorApiService.getAntrenorGunlukOzet();
      if (mounted) {
        setState(() => _gunlukOzet = result.data);
      }
    } catch (_) {
      // Özet alınamazsa kokpit gizlenir; ana sayfa çalışmaya devam eder
      if (mounted) {
        setState(() => _gunlukOzet = null);
      }
    }
  }

  Future<void> _loadAntrenorAdi() async {
    final antrenorModel = await StorageService.antrenorBilgileriniGetir();
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

  Future<void> _fetchNextLesson() async {
    try {
      // YENİ: Ayrı endpoint kullan - 30 gün içindeki ilk dersi getirir
      final result = await AntrenorApiService.getAntrenorSonrakiDers();

      if (mounted) {
        setState(() => _nextLesson = result.data);
      }
    } catch (e) {
      // Hata durumunda eski yöntemi dene (fallback)
      try {
        final result = await TakvimService.getirAntrenorHaftalikDersBilgileri();
        final list = result.data ?? [];

        final now = simdiKulup();
        final filtered = list
            .where((e) => e.baslangicTarihSaat.isAfter(now) && !e.iptalMi)
            .toList();
        final next = filtered.isEmpty
            ? null
            : filtered.reduce((a, b) =>
                a.baslangicTarihSaat.isBefore(b.baslangicTarihSaat) ? a : b);

        if (mounted) {
          setState(() => _nextLesson = next);
        }
      } catch (e2) {
        if (mounted) {
          ShowMessage.error(context, 'Dersler yüklenirken hata: $e2');
        }
      }
    }
  }

  Future<void> _fetchInfoCards() async {
    try {
      final result = await AntrenorApiService.getAntrenorHomeCards();

      if (mounted) {
        setState(() {
          _infoCards = result.data ?? [];
        });
      }
    } catch (e) {
      // Hata durumunda boş liste
      if (mounted) {
        setState(() => _infoCards = []);
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  void _onCardTap(HomeCardModel card) {
    if (card.actionRoute != null) {
      Navigator.pushNamed(
        context,
        card.actionRoute!,
        arguments: card.actionParams,
      );
    }
  }

  Future<void> _onCardDismiss(HomeCardModel card) async {
    // Önce UI'dan kaldır (optimistic update)
    setState(() {
      _infoCards.removeWhere((c) => c.id == card.id);
    });

    // Backend'e bildir
    try {
      await AntrenorApiService.dismissAntrenorHomeCard(card.id);
    } catch (e) {
      // Hata olursa kartı geri ekle
      if (mounted) {
        setState(() {
          _infoCards.add(card);
          _infoCards.sort((a, b) => b.id.compareTo(a.id));
        });
        ShowMessage.error(context, 'Kart kapatılamadı');
      }
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
                // Header
                SliverToBoxAdapter(
                  child: HomeHeader(
                    antrenorAdi: _antrenorAdi,
                    hasMultipleProfiles: _hasMultipleProfiles,
                  ),
                ),

                // Günlük Kokpit
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: GunlukKokpitCard(
                      ozet: _gunlukOzet,
                      isLoading: _isLoading,
                    ),
                  ),
                ),

                // Hızlı Erişim Menüsü
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: QuickAccessGrid(),
                  ),
                ),

                // Bilgi Kartları Carousel
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 0, 0),
                  sliver: SliverToBoxAdapter(
                    child: InfoCardsCarousel(
                      cards: _infoCards,
                      isLoading: _isLoading,
                      onCardTap: _onCardTap,
                      onCardDismiss: _onCardDismiss,
                    ),
                  ),
                ),

                // Sonraki Ders
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: NextLessonCard(
                      nextLesson: _nextLesson,
                      isLoading: _isLoading,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
