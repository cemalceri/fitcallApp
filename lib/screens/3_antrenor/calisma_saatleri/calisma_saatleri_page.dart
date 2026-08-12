// lib/screens/3_antrenor/calisma_saatleri/calisma_saatleri_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/3_antrenor/calisma_saatleri_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/antrenor/antrenor_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bir günün düzenlenebilir çalışma saati durumu
class _GunSatiri {
  final GunModel gun;
  bool aktif;
  TimeOfDay baslangic;
  TimeOfDay bitis;
  bool birdenFazlaAralikVardi;

  _GunSatiri({
    required this.gun,
    required this.aktif,
    required this.baslangic,
    required this.bitis,
    this.birdenFazlaAralikVardi = false,
  });
}

class CalismaSaatleriPage extends StatefulWidget {
  const CalismaSaatleriPage({super.key});

  @override
  State<CalismaSaatleriPage> createState() => _CalismaSaatleriPageState();
}

class _CalismaSaatleriPageState extends State<CalismaSaatleriPage> {
  List<_GunSatiri> _gunler = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  TimeOfDay _parseSaat(String s, TimeOfDay varsayilan) {
    final parcalar = s.split(':');
    if (parcalar.length < 2) return varsayilan;
    final saat = int.tryParse(parcalar[0]);
    final dakika = int.tryParse(parcalar[1]);
    if (saat == null || dakika == null) return varsayilan;
    return TimeOfDay(hour: saat, minute: dakika);
  }

  String _formatSaat(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _yukle() async {
    setState(() {
      _isLoading = true;
      _hata = null;
    });
    try {
      final res = await AntrenorApiService.getCalismaGunleri();
      final data = res.data;
      if (data == null) {
        setState(() {
          _hata = 'Çalışma saatleri alınamadı';
          _isLoading = false;
        });
        return;
      }

      const varsayilanBas = TimeOfDay(hour: 9, minute: 0);
      const varsayilanBit = TimeOfDay(hour: 18, minute: 0);

      final satirlar = <_GunSatiri>[];
      final gunlerSirali = [...data.gunler]
        ..sort((a, b) => a.haftaninGunu.compareTo(b.haftaninGunu));

      for (final gun in gunlerSirali) {
        final kayitlar =
            data.calismaSaatleri.where((k) => k.gunId == gun.gunId).toList();
        if (kayitlar.isEmpty) {
          satirlar.add(_GunSatiri(
            gun: gun,
            aktif: false,
            baslangic: varsayilanBas,
            bitis: varsayilanBit,
          ));
        } else {
          // Birden fazla aralık varsa en erken başlangıç / en geç bitiş alınır
          var bas = _parseSaat(kayitlar.first.baslangicSaat, varsayilanBas);
          var bit = _parseSaat(kayitlar.first.bitisSaat, varsayilanBit);
          for (final k in kayitlar.skip(1)) {
            final kBas = _parseSaat(k.baslangicSaat, bas);
            final kBit = _parseSaat(k.bitisSaat, bit);
            if (_dakika(kBas) < _dakika(bas)) bas = kBas;
            if (_dakika(kBit) > _dakika(bit)) bit = kBit;
          }
          satirlar.add(_GunSatiri(
            gun: gun,
            aktif: true,
            baslangic: bas,
            bitis: bit,
            birdenFazlaAralikVardi: kayitlar.length > 1,
          ));
        }
      }

      if (!mounted) return;
      setState(() {
        _gunler = satirlar;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = 'Çalışma saatleri alınamadı';
        _isLoading = false;
      });
    }
  }

  int _dakika(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _kaydet() async {
    // Doğrulama
    for (final satir in _gunler) {
      if (satir.aktif && _dakika(satir.bitis) <= _dakika(satir.baslangic)) {
        ShowMessage.error(
          context,
          '${satir.gun.gunAdi}: bitiş saati başlangıçtan sonra olmalı',
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final gonderilecek = _gunler
          .where((s) => s.aktif)
          .map((s) => CalismaSaatiModel(
                gunId: s.gun.gunId,
                gunAdi: s.gun.gunAdi,
                haftaninGunu: s.gun.haftaninGunu,
                baslangicSaat: _formatSaat(s.baslangic),
                bitisSaat: _formatSaat(s.bitis),
              ))
          .toList();

      final res = await AntrenorApiService.setCalismaGunleri(gonderilecek);
      if (!mounted) return;
      setState(() => _isSaving = false);
      ShowMessage.success(
        context,
        res.mesaj.isNotEmpty ? res.mesaj : 'Çalışma saatleri güncellendi',
      );
      await _yukle();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ShowMessage.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ShowMessage.error(context, 'Kaydetme sırasında hata oluştu');
    }
  }

  Future<void> _saatSec(_GunSatiri satir, {required bool baslangicMi}) async {
    HapticFeedback.lightImpact();
    final secilen = await showTimePicker(
      context: context,
      initialTime: baslangicMi ? satir.baslangic : satir.bitis,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (secilen == null) return;
    setState(() {
      if (baslangicMi) {
        satir.baslangic = secilen;
      } else {
        satir.bitis = secilen;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalışma Saatlerim'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const IskeletListe(satirSayisi: 7)
          : _hata != null
              ? _hataGorunumu(colorScheme)
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _yukle,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            _bilgiNotu(colorScheme),
                            const SizedBox(height: 16),
                            ..._gunler.map((s) => _gunKarti(colorScheme, s)),
                          ],
                        ),
                      ),
                    ),
                    _kaydetButonu(colorScheme),
                  ],
                ),
    );
  }

  Widget _hataGorunumu(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_hata!, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _yukle, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }

  Widget _bilgiNotu(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Buradaki saatler, üyelerin ders talebi oluştururken gördüğü '
              'uygun saatlerinizi belirler.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gunKarti(ColorScheme colorScheme, _GunSatiri satir) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: satir.aktif
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  satir.gun.gunAdi,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: satir.aktif
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (satir.aktif) ...[
                _saatButonu(colorScheme, _formatSaat(satir.baslangic),
                    () => _saatSec(satir, baslangicMi: true)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('—',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
                _saatButonu(colorScheme, _formatSaat(satir.bitis),
                    () => _saatSec(satir, baslangicMi: false)),
                const SizedBox(width: 8),
              ],
              Switch(
                value: satir.aktif,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => satir.aktif = v);
                },
              ),
            ],
          ),
          if (satir.aktif && satir.birdenFazlaAralikVardi)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bu gün için birden fazla saat aralığı tanımlıydı; '
                      'kaydederseniz tek aralığa dönüşür.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
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

  Widget _saatButonu(
      ColorScheme colorScheme, String metin, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            metin,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _kaydetButonu(ColorScheme colorScheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _kaydet,
            icon: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
