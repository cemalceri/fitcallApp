// lib/screens/7_yonetici/uyeler/borclu_uyeler_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uye_detay_page.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
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
      return const IskeletListe();
    }

    if (_errorMessage != null) {
      return BosDurum(
        ikon: Icons.error_outline_rounded,
        baslik: 'Liste alınamadı',
        aciklama: _errorMessage!,
        ikonRengi: context.renkler.hata,
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: _loadData,
      );
    }

    if (_uyeler.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
            const BosDurum(
              ikon: Icons.verified_outlined,
              baslik: 'Borçlu üye yok',
              aciklama: 'Bütün üyelerin bakiyesi güncel. Tahsil edilecek '
                  'bir alacak görünmüyor.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Bosluk.xxl),
        itemCount: _uyeler.length + 1,
        separatorBuilder: (_, index) =>
            index == 0 ? const SizedBox.shrink() : const ListeAyraci(),
        itemBuilder: (context, index) {
          if (index == 0) return _ozetKart(context);

          final uye = _uyeler[index - 1];
          final telVar = uye.telefon != null && uye.telefon!.isNotEmpty;

          return ListeSatiri(
            onGorsel: ListeAvatari(
              basHarfler: ListeAvatari.harfler(uye.adSoyad),
              ton: ListeTonu.hata,
            ),
            baslik: uye.adSoyad,
            altBaslik: _altBaslik(uye),
            deger: _currency.format(uye.bakiye.abs()),
            degerRengi: context.renkler.hata,
            altDeger: '#${uye.uyeNo}',
            onTap: () => _acDetay(uye),
            eylemler: [
              if (telVar)
                ListeEylemi(
                  etiket: 'Ara',
                  ikon: Icons.phone_rounded,
                  ton: ListeTonu.basari,
                  onSec: () => _ara(uye.telefon),
                ),
              if (telVar)
                ListeEylemi(
                  etiket: 'WhatsApp',
                  ikon: Icons.chat_rounded,
                  ton: ListeTonu.bilgi,
                  onSec: () => _whatsapp(uye.telefon),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Telefon ve üye no aramada zaten eşleşiyor; ikinci satırda üyeyi
  /// hatırlatan bilgi durur.
  String _altBaslik(UyeListeItem uye) {
    final parcalar = <String>[
      if (uye.seviyeRengi.isNotEmpty) '${uye.seviyeRengi} seviye',
      uye.uyeTuru,
      if (uye.yas != null) '${uye.yas} yaş',
    ];
    return parcalar.join(' · ');
  }

  Widget _ozetKart(BuildContext context) {
    final renkler = context.renkler;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.m),
      padding: const EdgeInsets.all(Bosluk.l),
      decoration: BoxDecoration(
        color: renkler.hataZemin,
        borderRadius: BorderRadius.circular(Yaricap.l),
        border: Border.all(color: renkler.hata.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Bosluk.s),
            decoration: BoxDecoration(
              color: renkler.hata.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Yaricap.m),
            ),
            child: Icon(Icons.request_quote_outlined,
                color: renkler.hata, size: 22),
          ),
          const SizedBox(width: Bosluk.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Toplam alacak', style: context.metin.bodySmall),
                const SizedBox(height: 2),
                Text(
                  _currency.format(_toplamBorc),
                  maxLines: 1,
                  style: context.metin.headlineSmall
                      ?.copyWith(color: renkler.hata),
                ),
              ],
            ),
          ),
          const SizedBox(width: Bosluk.s),
          Text('${_uyeler.length} üye', style: context.metin.bodySmall),
        ],
      ),
    );
  }
}

