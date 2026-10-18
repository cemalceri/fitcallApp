// lib/screens/6_muhasebe/havale/widgets/banka_hesabi_karti.dart
//
// Havale / EFT sayfasındaki tek hesap kartı.
//
// - IBAN 4'lü gruplu, eşit aralıklı rakamlarla ve SEÇİLEBİLİR metin olarak
//   gösterilir; dar ekranda iki satıra sarılır, küçültülmez (1.3 yazı
//   ölçeğinde FittedBox okunmaz hale getiriyordu).
// - Kopyala boşluksuz kopyalar; ikon 2 sn ✓'e döner, snackbar ekran
//   okuyucuya da duyurulur.
// - Karekod kapalıyken IBAN ve kopyala görünür kalır; açılınca yalnız
//   karekod genişler. Üye banka uygulamasını aynı telefonda açtığı için kendi
//   ekranındaki karekodu okutamaz: birincil eylem "Paylaş" (resmi kaydet →
//   banka uygulamasında galeriden oku).

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/6_muhasebe/banka_hesabi_model.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Karekod görselini çizer. Testte ağ görseli yüklenemediği için yerine
/// sade bir kutu verilir.
typedef KarekodYapici = Widget Function(BuildContext context, String url);

Widget varsayilanKarekodYapici(BuildContext context, String url) =>
    CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (c, __, ___) => Icon(
        Icons.qr_code_2_rounded,
        color: c.cs.onSurfaceVariant,
        size: 40,
      ),
    );

class BankaHesabiKarti extends StatefulWidget {
  final BankaHesabiModel hesap;

  /// Karekod bölümü açık başlasın mı (tek hesap varsa açık gelir).
  final bool karekodAcikBaslasin;
  final KarekodYapici karekodYapici;
  final ValueChanged<BankaHesabiModel>? onKarekodPaylas;

  const BankaHesabiKarti({
    super.key,
    required this.hesap,
    this.karekodAcikBaslasin = false,
    this.karekodYapici = varsayilanKarekodYapici,
    this.onKarekodPaylas,
  });

  @override
  State<BankaHesabiKarti> createState() => _BankaHesabiKartiState();
}

class _BankaHesabiKartiState extends State<BankaHesabiKarti> {
  late bool _karekodAcik = widget.karekodAcikBaslasin;
  String? _kopyalanan;
  Timer? _zamanlayici;

  @override
  void dispose() {
    _zamanlayici?.cancel();
    super.dispose();
  }

  Future<void> _kopyala(String anahtar, String deger, String mesaj) async {
    await Clipboard.setData(ClipboardData(text: deger));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _kopyalanan = anahtar);
    _zamanlayici?.cancel();
    _zamanlayici = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _kopyalanan = null);
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mesaj)));
  }

  void _karekoduBuyut() {
    final hesap = widget.hesap;
    showDialog<void>(
      context: context,
      builder: (c) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(hesap.etiket),
            actions: [
              if (widget.onKarekodPaylas != null)
                IconButton(
                  tooltip: 'Paylaş',
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: () => widget.onKarekodPaylas!(hesap),
                ),
            ],
          ),
          body: Container(
            // Karekod okuyucular açık zemin ister: koyu temada da beyaz.
            color: Marka.logoZemini,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(Bosluk.xl),
            child: InteractiveViewer(
              maxScale: 4,
              child: widget.karekodYapici(c, hesap.karekodUrl!),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hesap = widget.hesap;
    final cs = context.cs;
    final metin = context.metin;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Yaricap.l),
      ),
      padding: const EdgeInsets.fromLTRB(Bosluk.m, Bosluk.m, Bosluk.s, Bosluk.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ListeAvatari(
                ikon: Icons.account_balance_outlined,
                ton: ListeTonu.vurgu,
                cap: 40,
              ),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hesap.etiket,
                      style: metin.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${hesap.bankaAdi} · ${hesap.aliciAdi}',
                      style: metin.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _KopyalaButonu(
                ipucu: 'Alıcı adını kopyala',
                kopyalandi: _kopyalanan == 'alici',
                onTap: () => _kopyala('alici', hesap.aliciAdi, 'Alıcı adı kopyalandı'),
              ),
            ],
          ),
          const SizedBox(height: Bosluk.s),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IBAN',
                          style: metin.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      SelectableText(
                        hesap.ibanGruplu,
                        style: metin.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: 0.2,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                _KopyalaButonu(
                  ipucu: 'IBAN kopyala',
                  kopyalandi: _kopyalanan == 'iban',
                  onTap: () => _kopyala('iban', hesap.iban, 'IBAN kopyalandı'),
                ),
              ],
            ),
          ),
          if (hesap.karekodUrl != null) ...[
            if (!_karekodAcik)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: TextButton.icon(
                    onPressed: () => setState(() => _karekodAcik = true),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                    label: const Text('Karekodu göster'),
                  ),
                ),
              )
            else
              _karekodBolumu(context, hesap),
          ],
        ],
      ),
    );
  }

  Widget _karekodBolumu(BuildContext context, BankaHesabiModel hesap) {
    final cs = context.cs;
    return Container(
      margin: const EdgeInsets.only(left: 52, top: Bosluk.s, right: Bosluk.xs),
      padding: const EdgeInsets.only(top: Bosluk.m, bottom: Bosluk.xs),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      // Dar ekranda (320 px) karekod ile açıklama yan yana sığmadığında alta iner.
      child: Wrap(
        spacing: Bosluk.m,
        runSpacing: Bosluk.s,
        children: [
          Semantics(
            label: '${hesap.etiket} karekodu, büyütmek için dokun',
            button: true,
            child: GestureDetector(
              onTap: _karekoduBuyut,
              child: Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(Bosluk.xs),
                decoration: BoxDecoration(
                  color: Marka.logoZemini,
                  borderRadius: BorderRadius.circular(Yaricap.s),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: widget.karekodYapici(context, hesap.karekodUrl!),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onKarekodPaylas != null)
                  OutlinedButton.icon(
                    onPressed: () => widget.onKarekodPaylas!(hesap),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Paylaş'),
                  ),
                const SizedBox(height: Bosluk.xs),
                Text(
                  'Resmi kaydet, sonra banka uygulamanda "galeriden karekod '
                  'oku"yu seç.',
                  style: context.metin.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                TextButton(
                  onPressed: () => setState(() => _karekodAcik = false),
                  child: const Text('Karekodu gizle'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KopyalaButonu extends StatelessWidget {
  final String ipucu;
  final bool kopyalandi;
  final VoidCallback onTap;

  const _KopyalaButonu({
    required this.ipucu,
    required this.kopyalandi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final renk = kopyalandi ? context.renkler.basari : context.cs.primary;
    return IconButton(
      tooltip: kopyalandi ? 'Kopyalandı' : ipucu,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Icon(
          kopyalandi ? Icons.check_rounded : Icons.copy_rounded,
          key: ValueKey(kopyalandi),
          color: renk,
          size: 22,
        ),
      ),
    );
  }
}
