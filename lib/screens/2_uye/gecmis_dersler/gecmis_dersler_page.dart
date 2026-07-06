// lib/screens/2_uye/gecmis_dersler/gecmis_dersler_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/2_uye/gecmis_ders_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/2_uye/takvim/widgets/ders_degerlendirme_popup.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/uye/uye_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
    final now = DateTime.now();
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
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _dersler.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _dersler.length) {
                          return _dahaEskiButonu(colorScheme);
                        }
                        return _DersKarti(
                          ders: _dersler[index],
                          onDegerlendir: () =>
                              _degerlendirmeAc(_dersler[index]),
                        );
                      },
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

class _DersKarti extends StatelessWidget {
  final GecmisDersModel ders;
  final VoidCallback onDegerlendir;

  const _DersKarti({required this.ders, required this.onDegerlendir});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tarihFmt = DateFormat('d MMMM EEEE', 'tr_TR');
    final saatFmt = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${tarihFmt.format(ders.baslangicTarihSaat)} · '
                  '${saatFmt.format(ders.baslangicTarihSaat)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _durumRozeti(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (ders.kortAdi.isNotEmpty) ders.kortAdi,
              if (ders.antrenorAdi.isNotEmpty) ders.antrenorAdi,
              if (ders.urunAdi.isNotEmpty) ders.urunAdi,
            ].join(' · '),
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (ders.katilim?.notMetni != null &&
              ders.katilim!.notMetni!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sticky_note_2_outlined,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ders.katilim!.notMetni!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!ders.iptalMi) ...[
            const SizedBox(height: 10),
            _degerlendirmeSatiri(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _durumRozeti() {
    final String metin;
    final Color renk;

    if (ders.iptalMi) {
      metin = 'İptal';
      renk = const Color(0xFF94A3B8);
    } else if (ders.katilim != null) {
      if (ders.katilim!.katildi) {
        metin = ders.katilim!.planDisiMi ? 'Katıldı (Plan dışı)' : 'Katıldı';
        renk = const Color(0xFF10B981);
      } else {
        metin = 'Katılmadı';
        renk = const Color(0xFFEF4444);
      }
    } else if (ders.dersYapildi == true) {
      metin = 'Ders yapıldı';
      renk = const Color(0xFF10B981);
    } else if (ders.dersYapildi == false) {
      metin = 'Ders yapılmadı';
      renk = const Color(0xFFF59E0B);
    } else {
      metin = 'Sonuç girilmedi';
      renk = const Color(0xFF94A3B8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        metin,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: renk,
        ),
      ),
    );
  }

  Widget _degerlendirmeSatiri(ColorScheme colorScheme) {
    if (ders.puanim != null) {
      return Row(
        children: [
          ...List.generate(5, (i) {
            return Icon(
              i < ders.puanim!.puan
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 18,
              color: const Color(0xFFF59E0B),
            );
          }),
          if (ders.puanim!.yorum != null &&
              ders.puanim!.yorum!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ders.puanim!.yorum!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onDegerlendir,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.star_outline_rounded, size: 18),
        label: const Text('Değerlendir', style: TextStyle(fontSize: 13)),
      ),
    );
  }
}
