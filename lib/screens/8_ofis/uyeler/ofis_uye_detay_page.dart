// lib/screens/8_ofis/uyeler/ofis_uye_detay_page.dart
//
// Ofisin üye kartı: kim, nasıl ulaşılır, hangi paketi var, hangi derse geliyor.
//
// Yönetici detayından farkı — bakiye kartı, borç dökümü, ödeme linki, adres,
// meslek, veli ve acil durum bilgileri YOK. Bunlar burada gizlenmiyor,
// `ofisUyeDetay` ucundan hiç gelmiyor (bkz. api/ofis/metots.py).

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_models.dart';
import 'package:fitcall/models/9_yonetici/uye_detay_models.dart'
    show UyeDersItem, UyePaketItem;
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/ofis/ofis_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class OfisUyeDetayPage extends StatefulWidget {
  final int uyeId;

  /// Liste satırından gelen ad; veri inmeden başlıkta durur.
  final String? baslangicAdSoyad;

  const OfisUyeDetayPage({
    super.key,
    required this.uyeId,
    this.baslangicAdSoyad,
  });

  @override
  State<OfisUyeDetayPage> createState() => _OfisUyeDetayPageState();
}

class _OfisUyeDetayPageState extends State<OfisUyeDetayPage> {
  OfisUyeDetayData? _data;
  bool _loading = true;
  String? _errorMessage;

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
      final sonuc = await OfisApiService.uyeDetay(uyeId: widget.uyeId);
      if (!mounted) return;
      setState(() {
        _data = sonuc.data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Veriler yüklenirken bir hata oluştu.';
        _loading = false;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_data?.profil.adSoyad ??
            widget.baslangicAdSoyad ??
            'Üye Detayı'),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) return const IskeletKart();

    if (_errorMessage != null) {
      return BosDurum(
        ikon: Icons.error_outline_rounded,
        baslik: 'Üye bilgisi alınamadı',
        aciklama: _errorMessage!,
        ikonRengi: context.renkler.hata,
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: _loadData,
      );
    }

    final data = _data;
    if (data == null) {
      return const BosDurum(
        ikon: Icons.person_off_rounded,
        baslik: 'Kayıt bulunamadı',
        aciklama: 'Bu üyeye ait bilgi getirilemedi.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.xxl),
        children: [
          _OfisUyeBasligi(profil: data.profil),
          const SizedBox(height: Bosluk.l),
          _hizliAksiyonlar(data.profil),
          const SizedBox(height: Bosluk.l),
          _bilgiler(data.profil),
          const SizedBox(height: Bosluk.l),
          _paketler(data.paketler),
          const SizedBox(height: Bosluk.l),
          _dersler(
            baslik: 'Yaklaşan Dersler',
            ikon: Icons.event_available_rounded,
            dersler: data.yaklasanDersler,
            bosMesaj: 'Yaklaşan ders yok',
          ),
          const SizedBox(height: Bosluk.l),
          _dersler(
            baslik: 'Geçmiş Dersler',
            ikon: Icons.history_rounded,
            dersler: data.gecmisDersler,
            bosMesaj: 'Geçmiş ders kaydı yok',
          ),
        ],
      ),
    );
  }

  Widget _hizliAksiyonlar(OfisUyeProfili profil) {
    final telVar = profil.telefon != null && profil.telefon!.isNotEmpty;
    if (!telVar) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => _ara(profil.telefon),
            icon: const Icon(Icons.phone_rounded, size: 18),
            label: const Text('Ara'),
          ),
        ),
        const SizedBox(width: Bosluk.m),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => _whatsapp(profil.telefon),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: const Text('WhatsApp'),
          ),
        ),
      ],
    );
  }

  Widget _bilgiler(OfisUyeProfili profil) {
    final satirlar = <Widget>[];

    void ekle(String etiket, String? deger) {
      if (deger == null || deger.isEmpty) return;
      satirlar.add(_BilgiSatiri(etiket: etiket, deger: deger));
    }

    ekle('Üye No', '#${profil.uyeNo}');
    ekle('Telefon', profil.telefon != null ? '0${profil.telefon}' : null);
    ekle('E-posta', profil.email);
    ekle('Yaş', profil.yas != null ? '${profil.yas}' : null);
    ekle('Üye Türü', profil.uyeTuru);
    ekle('Seviye', profil.seviyeRengi);
    ekle('Sorumlu Hoca', profil.sorumluHocaAdi);
    ekle('Kayıt Tarihi', profil.kayitTarihi);

    if (satirlar.isEmpty) return const SizedBox.shrink();

    return _BolumKarti(
      baslik: 'İletişim & Bilgiler',
      ikon: Icons.contact_page_outlined,
      child: Column(children: satirlar),
    );
  }

  Widget _paketler(List<UyePaketItem> paketler) {
    final cs = context.cs;

    return _BolumKarti(
      baslik: 'Paketler & Haklar',
      ikon: Icons.card_membership_rounded,
      child: paketler.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: Bosluk.s),
              child: Text('Tanımlı paket yok',
                  style: context.metin.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
            )
          : Column(
              children: paketler.map((p) {
                final hakVar = p.toplamHak != null && p.kalanHak != null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: Bosluk.xs + 2),
                  child: Row(
                    children: [
                      Icon(
                        p.aktifMi
                            ? Icons.check_circle_rounded
                            : Icons.remove_circle_outline_rounded,
                        size: 16,
                        color: p.aktifMi
                            ? context.renkler.basari
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: Bosluk.s + 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.urunAdi, style: context.metin.bodyMedium),
                            if (hakVar)
                              Text(
                                'Kalan hak: '
                                '${p.kalanHak!.toStringAsFixed(p.kalanHak! % 1 == 0 ? 0 : 1)}'
                                ' / ${p.toplamHak}',
                                style: context.metin.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                      if (!p.aktifMi)
                        Text('Pasif',
                            style: context.metin.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _dersler({
    required String baslik,
    required IconData ikon,
    required List<UyeDersItem> dersler,
    required String bosMesaj,
  }) {
    final cs = context.cs;

    return _BolumKarti(
      baslik: baslik,
      ikon: ikon,
      child: dersler.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: Bosluk.s),
              child: Text(bosMesaj,
                  style: context.metin.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
            )
          : Column(
              children: dersler.map((d) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: Bosluk.xs + 2),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        padding:
                            const EdgeInsets.symmetric(vertical: Bosluk.xs),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(Yaricap.s),
                        ),
                        child: Text(
                          d.saat,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: context.metin.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: Bosluk.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d.tarih}${d.urunAdi != null ? ' • ${d.urunAdi}' : ''}',
                              style: context.metin.bodyMedium?.copyWith(
                                decoration: d.iptalMi
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (d.antrenorAdi != null || d.kortAdi != null)
                              Text(
                                [d.antrenorAdi, d.kortAdi]
                                    .where((e) => e != null)
                                    .join(' • '),
                                style: context.metin.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                      if (d.iptalMi)
                        Text('İptal',
                            style: context.metin.labelSmall
                                ?.copyWith(color: context.renkler.hata)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ==================== BAŞLIK ====================

class _OfisUyeBasligi extends StatelessWidget {
  final OfisUyeProfili profil;

  const _OfisUyeBasligi({required this.profil});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Container(
      padding: const EdgeInsets.all(Bosluk.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(Yaricap.l),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: profil.seviyeRenkColor.withValues(alpha: 0.18),
            child: Text(
              _harfler(profil.adSoyad),
              style: context.metin.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: Bosluk.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profil.adSoyad,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${profil.uyeNo} · ${profil.uyeTuru}'
                  '${profil.aktifMi ? '' : ' · Pasif'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _harfler(String adSoyad) {
    final parcalar = adSoyad
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parcalar.isEmpty) return '?';
    if (parcalar.length == 1) return parcalar.first[0].toUpperCase();
    return (parcalar.first[0] + parcalar.last[0]).toUpperCase();
  }
}

// ==================== ORTAK PARÇALAR ====================

class _BolumKarti extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final Widget child;

  const _BolumKarti({
    required this.baslik,
    required this.ikon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Container(
      padding: const EdgeInsets.all(Bosluk.l),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Yaricap.l),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 18, color: cs.primary),
              const SizedBox(width: Bosluk.s),
              Expanded(
                child: Text(
                  baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: Bosluk.m),
          child,
        ],
      ),
    );
  }
}

class _BilgiSatiri extends StatelessWidget {
  final String etiket;
  final String deger;

  const _BilgiSatiri({required this.etiket, required this.deger});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Bosluk.xs + 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              etiket,
              style:
                  context.metin.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: Bosluk.s),
          Expanded(
            child: Text(deger, style: context.metin.bodyMedium),
          ),
        ],
      ),
    );
  }
}
