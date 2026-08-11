// lib/screens/7_yonetici/uyeler/borclu_uyeler_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uye_detay_page.dart';
import 'package:fitcall/screens/7_yonetici/widgets/skeleton.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Borçlu üyeler (tahsilat) ekranı — bakiyeye göre sıralı, hızlı iletişim.
class BorcluUyelerPage extends StatefulWidget {
  const BorcluUyelerPage({super.key});

  @override
  State<BorcluUyelerPage> createState() => _BorcluUyelerPageState();
}

class _BorcluUyelerPageState extends State<BorcluUyelerPage> {
  List<UyeListeItem> _uyeler = [];
  bool _loading = true;
  String? _errorMessage;

  final _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await YoneticiApiService.getUyeler(
        hepsi: true,
        sadeceBorclu: true,
        siralama: 'bakiye',
      );
      if (mounted) {
        setState(() {
          _uyeler = result.data?.uyeler ?? [];
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

  double get _toplamBorc =>
      _uyeler.fold(0.0, (t, u) => t + (u.bakiye < 0 ? u.bakiye.abs() : 0));

  Future<void> _ara(String? telefon) async {
    if (telefon == null || telefon.isEmpty) return;
    HapticFeedback.lightImpact();
    await launchUrl(Uri.parse('tel:0$telefon'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _whatsapp(String? telefon) async {
    if (telefon == null || telefon.isEmpty) return;
    HapticFeedback.lightImpact();
    await launchUrl(Uri.parse('https://wa.me/90$telefon'),
        mode: LaunchMode.externalApplication);
  }

  void _acDetay(UyeListeItem uye) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            UyeDetayPage(uyeId: uye.id, baslangicAdSoyad: uye.adSoyad),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borçlu Üyeler')),
      body: _buildContent(),
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

    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _uyeler.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ozetKart(colorScheme);
          }
          if (_uyeler.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text('Borçlu üye bulunmuyor 🎉',
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
            );
          }
          final uye = _uyeler[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BorcluItem(
              uye: uye,
              currency: _currency,
              onTap: () => _acDetay(uye),
              onAra: () => _ara(uye.telefon),
              onWhatsapp: () => _whatsapp(uye.telefon),
            ),
          );
        },
      ),
    );
  }

  Widget _ozetKart(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.request_quote_outlined,
                color: Colors.red, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Toplam Alacak',
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  _currency.format(_toplamBorc),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_uyeler.length} üye',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _BorcluItem extends StatelessWidget {
  final UyeListeItem uye;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback onAra;
  final VoidCallback onWhatsapp;

  const _BorcluItem({
    required this.uye,
    required this.currency,
    required this.onTap,
    required this.onAra,
    required this.onWhatsapp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final telVar = uye.telefon != null && uye.telefon!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: uye.seviyeRenkColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${uye.adi.isNotEmpty ? uye.adi[0] : ''}${uye.soyadi.isNotEmpty ? uye.soyadi[0] : ''}'
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: uye.seviyeRenkColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uye.adSoyad,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(uye.bakiye.abs()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              _MiniAksiyon(
                ikon: Icons.phone,
                renk: Colors.green,
                aktif: telVar,
                onTap: onAra,
              ),
              const SizedBox(width: 8),
              _MiniAksiyon(
                ikon: Icons.chat,
                renk: const Color(0xFF25D366),
                aktif: telVar,
                onTap: onWhatsapp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAksiyon extends StatelessWidget {
  final IconData ikon;
  final Color renk;
  final bool aktif;
  final VoidCallback onTap;

  const _MiniAksiyon({
    required this.ikon,
    required this.renk,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final efektif = aktif ? renk : Theme.of(context).disabledColor;
    return InkWell(
      onTap: aktif ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: efektif.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(ikon, size: 18, color: efektif),
      ),
    );
  }
}
