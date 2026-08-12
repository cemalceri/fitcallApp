// lib/screens/7_yonetici/uyeler/uye_detay_page.dart

import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/9_yonetici/uye_detay_models.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_borc_sheet.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class UyeDetayPage extends StatefulWidget {
  final int uyeId;
  final String? baslangicAdSoyad;

  const UyeDetayPage({
    super.key,
    required this.uyeId,
    this.baslangicAdSoyad,
  });

  @override
  State<UyeDetayPage> createState() => _UyeDetayPageState();
}

class _UyeDetayPageState extends State<UyeDetayPage> {
  UyeDetayData? _data;
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
      final result = await YoneticiApiService.getUyeDetay(uyeId: widget.uyeId);
      if (mounted) {
        setState(() {
          _data = result.data;
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
          _errorMessage = 'Üye detayı yüklenirken bir hata oluştu.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _ara(String? telefon) async {
    if (telefon == null || telefon.isEmpty) return;
    HapticFeedback.lightImpact();
    final uri = Uri.parse('tel:0$telefon');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _whatsapp(String? telefon) async {
    if (telefon == null || telefon.isEmpty) return;
    HapticFeedback.lightImpact();
    final uri = Uri.parse('https://wa.me/90$telefon');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _odemeLinki() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ödeme linki için banka entegrasyonu bekleniyor.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _borcDokumuAc() {
    if (_data == null) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UyeBorcSheet(
        adSoyad: _data!.profil.adSoyad,
        bakiye: _data!.bakiye,
        paraHareketleri: _data!.paraHareketleri,
        aylikOzet: _data!.aylikOzet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _data?.profil.adSoyad ?? widget.baslangicAdSoyad ?? 'Üye Detayı'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.06),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.25],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const IskeletKart();
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

    if (_data == null) {
      return const Center(child: Text('Veri bulunamadı'));
    }

    final data = _data!;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _UyeDetayHeader(profil: data.profil),
          const SizedBox(height: 16),
          _hizliAksiyonlar(data.profil),
          const SizedBox(height: 16),
          _bakiyeKarti(data.bakiye),
          const SizedBox(height: 16),
          _iletisimBilgileri(data.profil),
          const SizedBox(height: 16),
          _paketlerBolumu(data.paketler),
          const SizedBox(height: 16),
          _derslerBolumu(
            baslik: 'Yaklaşan Dersler',
            ikon: Icons.event_available,
            renk: Colors.indigo,
            dersler: data.yaklasanDersler,
            bosMesaj: 'Yaklaşan ders yok',
          ),
          const SizedBox(height: 16),
          _derslerBolumu(
            baslik: 'Geçmiş Dersler',
            ikon: Icons.history,
            renk: Colors.blueGrey,
            dersler: data.gecmisDersler,
            bosMesaj: 'Geçmiş ders kaydı yok',
          ),
        ],
      ),
    );
  }

  Widget _hizliAksiyonlar(UyeProfilBilgi profil) {
    final telVar = (profil.telefon != null && profil.telefon!.isNotEmpty);
    return Row(
      children: [
        Expanded(
          child: _AksiyonButonu(
            ikon: Icons.phone,
            etiket: 'Ara',
            renk: Colors.green,
            aktif: telVar,
            onTap: () => _ara(profil.telefon),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AksiyonButonu(
            ikon: Icons.chat,
            etiket: 'WhatsApp',
            renk: const Color(0xFF25D366),
            aktif: telVar,
            onTap: () => _whatsapp(profil.telefon),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AksiyonButonu(
            ikon: Icons.link,
            etiket: 'Ödeme Linki',
            renk: Colors.orange,
            aktif: true,
            onTap: _odemeLinki,
          ),
        ),
      ],
    );
  }

  Widget _bakiyeKarti(double bakiye) {
    final colorScheme = Theme.of(context).colorScheme;
    final borclu = bakiye < 0;
    final renk = borclu ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.account_balance_wallet_outlined,
                color: renk, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Güncel Bakiye',
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  _currency.format(bakiye.abs()),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: renk,
                  ),
                ),
                Text(
                  borclu ? 'Borçlu' : 'Alacaklı / Güncel',
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _borcDokumuAc,
            icon: const Icon(Icons.receipt_long, size: 18),
            label: const Text('Borç Dökümü'),
          ),
        ],
      ),
    );
  }

  Widget _iletisimBilgileri(UyeProfilBilgi profil) {
    final rows = <Widget>[];

    void ekle(String etiket, String? deger) {
      if (deger == null || deger.isEmpty) return;
      rows.add(_InfoRow(etiket: etiket, deger: deger));
    }

    ekle('Telefon', profil.telefon != null ? '0${profil.telefon}' : null);
    ekle('E-posta', profil.email);
    ekle('Yaş', profil.yas != null ? '${profil.yas}' : null);
    ekle('Üye Türü', profil.uyeTuru);
    ekle('Sorumlu Hoca', profil.sorumluHocaAdi);
    ekle('Kayıt Tarihi', profil.kayitTarihi);
    ekle('Meslek', profil.meslek);
    ekle('Adres', profil.adres);
    // Genç / sporcu veli bilgileri
    ekle('Anne', profil.anneAdiSoyadi);
    ekle('Anne Tel.',
        profil.anneTelefon != null ? '0${profil.anneTelefon}' : null);
    ekle('Baba', profil.babaAdiSoyadi);
    ekle('Baba Tel.',
        profil.babaTelefon != null ? '0${profil.babaTelefon}' : null);
    ekle('Okul', profil.okulAdi);
    ekle('Acil Durum', profil.acilDurumKisi);
    ekle('Acil Durum Tel.',
        profil.acilDurumTelefon != null ? '0${profil.acilDurumTelefon}' : null);

    if (rows.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      baslik: 'İletişim & Bilgiler',
      ikon: Icons.contact_page_outlined,
      renk: Colors.blue,
      child: Column(children: rows),
    );
  }

  Widget _paketlerBolumu(List<UyePaketItem> paketler) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      baslik: 'Paketler & Haklar',
      ikon: Icons.card_membership,
      renk: Colors.purple,
      child: paketler.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Tanımlı paket yok',
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
            )
          : Column(
              children: paketler.map((p) {
                final hakVar = p.toplamHak != null && p.kalanHak != null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        p.aktifMi ? Icons.check_circle : Icons.remove_circle,
                        size: 16,
                        color: p.aktifMi
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.urunAdi,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (hakVar)
                              Text(
                                'Kalan hak: ${p.kalanHak!.toStringAsFixed(p.kalanHak! % 1 == 0 ? 0 : 1)} / ${p.toplamHak}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!p.aktifMi)
                        Text(
                          'Pasif',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _derslerBolumu({
    required String baslik,
    required IconData ikon,
    required Color renk,
    required List<UyeDersItem> dersler,
    required String bosMesaj,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      baslik: baslik,
      ikon: ikon,
      renk: renk,
      child: dersler.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(bosMesaj,
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
            )
          : Column(
              children: dersler.map((d) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: renk.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          d.saat,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: renk,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d.tarih}${d.urunAdi != null ? ' • ${d.urunAdi}' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface,
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
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (d.iptalMi)
                        const Text('İptal',
                            style: TextStyle(fontSize: 11, color: Colors.red)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ==================== HEADER ====================

class _UyeDetayHeader extends StatelessWidget {
  final UyeProfilBilgi profil;

  const _UyeDetayHeader({required this.profil});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final basHarfler =
        '${profil.adi.isNotEmpty ? profil.adi[0] : ''}${profil.soyadi.isNotEmpty ? profil.soyadi[0] : ''}'
            .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: profil.seviyeRenkColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: profil.seviyeRenkColor.withValues(alpha: 0.35),
                  width: 2),
            ),
            child: Center(
              child: Text(
                basHarfler,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: profil.seviyeRenkColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profil.adSoyad,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '#${profil.uyeNo}',
                      style: TextStyle(
                          fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: profil.seviyeRenkColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        profil.seviyeRengi,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: profil.seviyeRenkColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (profil.aktifMi ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        profil.aktifMi ? 'Aktif' : 'Pasif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: profil.aktifMi ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ORTAK PARÇALAR ====================

class _AksiyonButonu extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final Color renk;
  final bool aktif;
  final VoidCallback onTap;

  const _AksiyonButonu({
    required this.ikon,
    required this.etiket,
    required this.renk,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final efektifRenk = aktif ? renk : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: aktif ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: efektifRenk.withValues(alpha: aktif ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(ikon, color: efektifRenk, size: 22),
              const SizedBox(height: 6),
              Text(
                etiket,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: efektifRenk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final Color renk;
  final Widget child;

  const _SectionCard({
    required this.baslik,
    required this.ikon,
    required this.renk,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(ikon, size: 18, color: renk),
              ),
              const SizedBox(width: 10),
              Text(
                baslik,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String etiket;
  final String deger;

  const _InfoRow({required this.etiket, required this.deger});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              etiket,
              style:
                  TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              deger,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
