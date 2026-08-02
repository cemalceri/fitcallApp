// lib/screens/2_uye/gecmis_dersler/gecmis_dersler_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/2_uye/gecmis_ders_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/2_uye/gecmis_dersler/widgets/gecmis_dersler_listesi.dart';
import 'package:fitcall/screens/2_uye/takvim/widgets/ders_degerlendirme_popup.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/uye/uye_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/common/tarih_util.dart';

class GecmisDerslerPage extends StatefulWidget {
  const GecmisDerslerPage({super.key});

  @override
  State<GecmisDerslerPage> createState() => _GecmisDerslerPageState();
}

class _GecmisDerslerPageState extends State<GecmisDerslerPage> {
  final List<GecmisDersModel> _dersler = [];
  DateTime? _enEskiBaslangic; // yüklenen pencerenin başlangıcı
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _dahaEskiVarMi = true;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _ilkYukleme();
  }

  Future<void> _ilkYukleme() async {
    _userId = await SecureStorageService.getValue('user_id') ?? 0;
    await _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _isLoading = true);
    try {
      final res = await UyeApiService.getGecmisDersler();
      if (!mounted) return;
      setState(() {
        _dersler
          ..clear()
          ..addAll(res.data?.dersler ?? const []);
        _enEskiBaslangic = res.data?.baslangic;
        _dahaEskiVarMi = true;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ShowMessage.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ShowMessage.error(context, 'Geçmiş dersler alınamadı');
    }
  }

  Future<void> _dahaEskiYukle() async {
    final mevcutBaslangic = _enEskiBaslangic;
    if (mevcutBaslangic == null || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final res = await UyeApiService.getGecmisDersler(
        baslangic: mevcutBaslangic.subtract(const Duration(days: 30)),
        bitis: mevcutBaslangic,
      );
      if (!mounted) return;
      final yeniler = res.data?.dersler ?? const <GecmisDersModel>[];
      final mevcutIds = _dersler.map((d) => d.id).toSet();
      setState(() {
        _dersler.addAll(yeniler.where((d) => !mevcutIds.contains(d.id)));
        _enEskiBaslangic = res.data?.baslangic;
        _dahaEskiVarMi = yeniler.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ShowMessage.error(context, 'Daha eski dersler yüklenemedi');
    }
  }

  void _degerlendirmeAc(GecmisDersModel ders) {
    HapticFeedback.lightImpact();
    final now = simdiKulup();
    // Popup EtkinlikModel bekliyor; geçmiş ders kaydından asgari model kurulur
    final etkinlik = EtkinlikModel(
      id: ders.id,
      uyeList: const [],
      kortId: 0,
      kortAdi: ders.kortAdi,
      baslangicTarihSaat: ders.baslangicTarihSaat,
      bitisTarihSaat: ders.bitisTarihSaat,
      seviye: ders.seviye,
      iptalMi: ders.iptalMi,
      isActive: true,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
      antrenorAdi: ders.antrenorAdi,
      urunAdi: ders.urunAdi,
      iptalEdenAdi: ders.iptalEdenAdi.isEmpty ? null : ders.iptalEdenAdi,
    );
    DersDegerlendirmePopup.show(
      context: context,
      ders: etkinlik,
      userId: _userId,
      onSuccess: _yukle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Derslerim'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _yukle,
              child: _dersler.isEmpty
                  ? _bosDurum(colorScheme)
                  : GecmisDerslerListesi(
                      dersler: _dersler,
                      onDegerlendir: _degerlendirmeAc,
                      footer: _dahaEskiButonu(colorScheme),
                    ),
            ),
    );
  }

  Widget _bosDurum(ColorScheme colorScheme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.history_rounded,
            size: 64, color: colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Son 30 günde ders kaydınız yok',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: _dahaEskiButonu(colorScheme)),
      ],
    );
  }

  Widget _dahaEskiButonu(ColorScheme colorScheme) {
    if (!_dahaEskiVarMi) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Daha eski kayıt bulunamadı',
            style:
                TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : OutlinedButton.icon(
                onPressed: _dahaEskiYukle,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Daha eski dersleri göster'),
              ),
      ),
    );
  }
}
