// lib/screens/3_antrenor/ogrenci_detay/antrenor_ogrenci_detay_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/3_antrenor/ogrenci_detay_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/antrenor/antrenor_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fitcall/common/tarih_util.dart';

class AntrenorOgrenciDetayPage extends StatefulWidget {
  final int uyeId;
  final String adSoyad;
  final Color seviyeRenk;

  const AntrenorOgrenciDetayPage({
    super.key,
    required this.uyeId,
    required this.adSoyad,
    required this.seviyeRenk,
  });

  @override
  State<AntrenorOgrenciDetayPage> createState() =>
      _AntrenorOgrenciDetayPageState();
}

class _AntrenorOgrenciDetayPageState extends State<AntrenorOgrenciDetayPage> {
  OgrenciDetayModel? _detay;
  bool _isLoading = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _isLoading = true;
      _hata = null;
    });
    try {
      final res = await AntrenorApiService.getOgrenciDetay(widget.uyeId);
      if (!mounted) return;
      setState(() {
        _detay = res.data;
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
        _hata = 'Öğrenci bilgileri alınamadı';
        _isLoading = false;
      });
    }
  }

  /* ------------------------------ İletişim ------------------------------ */

  String? _normalizeTel(String? tel) {
    if (tel == null) return null;
    final rakamlar = tel.replaceAll(RegExp(r'\D'), '');
    if (rakamlar.length == 10) return '+90$rakamlar';
    if (rakamlar.length == 11 && rakamlar.startsWith('0')) {
      return '+90${rakamlar.substring(1)}';
    }
    if (rakamlar.length >= 12) return '+$rakamlar';
    return null;
  }

  Future<void> _ara(String? tel) async {
    final numara = _normalizeTel(tel);
    if (numara == null) {
      ShowMessage.error(context, 'Geçerli telefon numarası bulunamadı');
      return;
    }
    HapticFeedback.lightImpact();
    final uri = Uri.parse('tel:$numara');
    if (!await launchUrl(uri)) {
      if (mounted) ShowMessage.error(context, 'Arama başlatılamadı');
    }
  }

  Future<void> _whatsapp(String? tel) async {
    final numara = _normalizeTel(tel);
    if (numara == null) {
      ShowMessage.error(context, 'Geçerli telefon numarası bulunamadı');
      return;
    }
    HapticFeedback.lightImpact();
    final uri = Uri.parse('https://wa.me/${numara.replaceAll('+', '')}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ShowMessage.error(context, 'WhatsApp açılamadı');
    }
  }

  /* -------------------------------- Build -------------------------------- */

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.adSoyad),
        centerTitle: true,
      ),
      body: _isLoading
          ? const IskeletKart()
          : _hata != null
              ? _hataGorunumu(colorScheme)
              : RefreshIndicator(
                  onRefresh: _yukle,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _profilKarti(colorScheme),
                      const SizedBox(height: 16),
                      _istatistikKarti(colorScheme),
                      const SizedBox(height: 16),
                      _iletisimKarti(colorScheme),
                      if (_detay!.paketler.isNotEmpty ||
                          _detay!.aktifTelafi > 0) ...[
                        const SizedBox(height: 16),
                        _paketKarti(colorScheme),
                      ],
                      if (_detay!.sonKatilimlar.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _sonKatilimlarKarti(colorScheme),
                      ],
                      if (_detay!.gorusmeNotlari.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _gorusmeNotlariKarti(colorScheme),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _hataGorunumu(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 56, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              _hata!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _yukle, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }

  Widget _kart(ColorScheme colorScheme,
      {required String baslik,
      required IconData ikon,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(ikon, size: 18, color: widget.seviyeRenk),
              const SizedBox(width: 8),
              Text(
                baslik,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _profilKarti(ColorScheme colorScheme) {
    final p = _detay!.profil;
    final yasFmt = p.dogumTarihi != null
        ? '${(simdiKulup().difference(p.dogumTarihi!).inDays / 365.25).floor()} yaş'
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.seviyeRenk.withValues(alpha: 0.15),
            widget.seviyeRenk.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.seviyeRenk.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
              border: Border.all(color: widget.seviyeRenk, width: 2),
            ),
            child: Center(
              child: Text(
                p.adSoyad.isNotEmpty
                    ? p.adSoyad.split(' ').map((k) => k[0]).take(2).join()
                    : '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.seviyeRenk,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.adSoyad,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    'Üye No: ${p.uyeNo}',
                    if (yasFmt != null) yasFmt,
                    p.seviyeRengi,
                    if (p.programTercihi != null) p.programTercihi!,
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (p.sorumluHocasiMiyim) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.seviyeRenk.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sorumlu Hocasısınız',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.seviyeRenk,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _istatistikKarti(ColorScheme colorScheme) {
    final i = _detay!.istatistik;
    final tarihFmt = DateFormat('d MMM', 'tr_TR');

    return _kart(
      colorScheme,
      baslik: 'Katılım (Son ${i.pencereGun} Gün)',
      ikon: Icons.insights_rounded,
      children: [
        Row(
          children: [
            _istatistikDeger(
              colorScheme,
              i.katilimYuzdesi != null ? '%${i.katilimYuzdesi}' : '—',
              'Katılım',
              const Color(0xFF10B981),
            ),
            _istatistikDeger(
              colorScheme,
              '${i.katildigiDers}/${i.yoklamaGirilen}',
              'Katıldı/Yoklama',
              const Color(0xFF6366F1),
            ),
            _istatistikDeger(
              colorScheme,
              '${i.plananlanDers}',
              'Planlanan',
              const Color(0xFFF59E0B),
            ),
          ],
        ),
        if (i.katilimYuzdesi == null) ...[
          const SizedBox(height: 8),
          Text(
            'Bu dönemde yoklama kaydı bulunmadığı için oran hesaplanamadı.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (i.sonKatilimTarihi != null) ...[
          const SizedBox(height: 8),
          Text(
            'Son katılım: ${tarihFmt.format(i.sonKatilimTarihi!)}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _istatistikDeger(
      ColorScheme colorScheme, String deger, String etiket, Color renk) {
    return Expanded(
      child: Column(
        children: [
          Text(
            deger,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiket,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iletisimKarti(ColorScheme colorScheme) {
    final p = _detay!.profil;
    final v = _detay!.veli;

    final satirlar = <Widget>[
      if (p.telefon != null && p.telefon!.isNotEmpty)
        _telefonSatiri(colorScheme, 'Öğrenci', p.telefon!),
      if (v.anneTelefon != null && v.anneTelefon!.isNotEmpty)
        _telefonSatiri(
            colorScheme, 'Anne${_adEki(v.anneAdiSoyadi)}', v.anneTelefon!),
      if (v.babaTelefon != null && v.babaTelefon!.isNotEmpty)
        _telefonSatiri(
            colorScheme, 'Baba${_adEki(v.babaAdiSoyadi)}', v.babaTelefon!),
      if (v.acilDurumTelefon != null && v.acilDurumTelefon!.isNotEmpty)
        _telefonSatiri(
            colorScheme, 'Acil${_adEki(v.acilDurumKisi)}', v.acilDurumTelefon!),
    ];

    return _kart(
      colorScheme,
      baslik: 'İletişim',
      ikon: Icons.contact_phone_outlined,
      children: satirlar.isEmpty
          ? [
              Text(
                'Kayıtlı telefon bulunamadı',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ]
          : satirlar,
    );
  }

  String _adEki(String? ad) =>
      (ad != null && ad.trim().isNotEmpty) ? ' — $ad' : '';

  Widget _telefonSatiri(ColorScheme colorScheme, String etiket, String tel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiket,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _ara(tel),
            icon: const Icon(Icons.call_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF10B981),
            ),
            tooltip: 'Ara',
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _whatsapp(tel),
            icon: const Icon(Icons.chat_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF25D366),
            ),
            tooltip: 'WhatsApp',
          ),
        ],
      ),
    );
  }

  Widget _paketKarti(ColorScheme colorScheme) {
    final tarihFmt = DateFormat('dd.MM.yyyy');
    return _kart(
      colorScheme,
      baslik: 'Paketler & Telafi',
      ikon: Icons.inventory_2_outlined,
      children: [
        ..._detay!.paketler.map((paket) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paket.urunAdi,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (paket.baslangic != null)
                        Text(
                          'Başlangıç: ${tarihFmt.format(paket.baslangic!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (paket.kalanHak != null && paket.toplamHak != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (paket.kalanHak! <= 2
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${paket.kalanHak!.toStringAsFixed(0)}/${paket.toplamHak} hak',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: paket.kalanHak! <= 2
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        if (_detay!.aktifTelafi > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.event_repeat_rounded,
                    size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Text(
                  '${_detay!.aktifTelafi} aktif telafi hakkı',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sonKatilimlarKarti(ColorScheme colorScheme) {
    final tarihFmt = DateFormat('dd.MM.yyyy HH:mm');
    return _kart(
      colorScheme,
      baslik: 'Son Katılımlar',
      ikon: Icons.fact_check_outlined,
      children: _detay!.sonKatilimlar.map((katilim) {
        final renk =
            katilim.katildi ? const Color(0xFF10B981) : const Color(0xFFEF4444);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                katilim.katildi
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 18,
                color: renk,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    if (katilim.tarih != null) tarihFmt.format(katilim.tarih!),
                    if (katilim.kortAdi.isNotEmpty) katilim.kortAdi,
                    if (katilim.planDisiMi) '(Plan dışı)',
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _gorusmeNotlariKarti(ColorScheme colorScheme) {
    final tarihFmt = DateFormat('dd.MM.yyyy');
    return _kart(
      colorScheme,
      baslik: 'Görüşme Notları',
      ikon: Icons.sticky_note_2_outlined,
      children: _detay!.gorusmeNotlari.map((not) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (not.gorusmeTarihi != null)
                    tarihFmt.format(not.gorusmeTarihi!),
                  not.gorusenKisi,
                ].join(' · '),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (not.notu.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  not.notu,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
