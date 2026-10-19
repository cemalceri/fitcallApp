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
//   ekranındaki karekodu okutamaz: birincil eylem "İndir" (galeriye kaydet →
//   banka uygulamasında galeriden oku), yanında "Paylaş".
// - Karekod görseli bir kez indirilip cihazda saklanır, baytlarıyla çizilir;
//   aynı baytlar indirme ve paylaşmada kullanılır. Eskiden CachedNetworkImage'in boş yer
//   tutucusu yükleme takılınca kutuyu bembeyaz bırakıyordu (2026-10-19);
//   artık yüklenirken gösterge, hata olursa "tekrar dene" var.

import 'dart:async';
import 'dart:io';

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/6_muhasebe/banka_hesabi_model.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Karekod görselini çizer. Testte ağ görseli yüklenemediği için yerine
/// sade bir kutu verilir.
typedef KarekodYapici = Widget Function(BuildContext context, String url);

Widget varsayilanKarekodYapici(BuildContext context, String url) =>
    KarekodGorseli(url: url);

final Map<String, Future<Uint8List>> _karekodOnbellegi = {};

/// Karekod görselinin baytları. Önce bellek, sonra cihazdaki kalıcı önbellek,
/// en son ağ: karekod her açılışta kaynaktan çekilmez. Admin karekodu
/// değiştirince adres de değişir (dosya adı yeni uuid), bu yüzden önbellekteki
/// dosya hiç bayatlamaz. Başarısız indirme önbellekte kalmaz, sonraki çağrı
/// yeniden dener.
Future<Uint8List> karekodBaytlari(String url) {
  return _karekodOnbellegi.putIfAbsent(url, () async {
    try {
      final dosya = await _karekodDosyasi(url);
      if (dosya != null && await dosya.exists()) {
        final baytlar = await dosya.readAsBytes();
        if (baytlar.isNotEmpty) return baytlar;
      }
      final cevap =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (cevap.statusCode != 200 || cevap.bodyBytes.isEmpty) {
        throw Exception('Karekod indirilemedi (${cevap.statusCode})');
      }
      if (dosya != null) {
        // Önbelleğe yazılamazsa (disk dolu vb.) görsel yine gösterilir.
        try {
          await dosya.parent.create(recursive: true);
          await dosya.writeAsBytes(cevap.bodyBytes, flush: true);
        } catch (_) {}
      }
      return cevap.bodyBytes;
    } catch (_) {
      _karekodOnbellegi.remove(url);
      rethrow;
    }
  });
}

/// Adresin son parçası (uuid'li dosya adı) önbellek dosyasının adı olur.
Future<File?> _karekodDosyasi(String url) async {
  try {
    final segmentler = Uri.parse(url).pathSegments;
    final ad = (segmentler.isEmpty ? '' : segmentler.last)
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (ad.isEmpty) return null;
    final dizin = await getApplicationSupportDirectory();
    return File('${dizin.path}/karekod/$ad');
  } catch (_) {
    return null;
  }
}

/// Ağdaki karekod görseli: yüklenirken gösterge, hata olursa tekrar dene.
class KarekodGorseli extends StatefulWidget {
  final String url;

  const KarekodGorseli({super.key, required this.url});

  @override
  State<KarekodGorseli> createState() => _KarekodGorseliState();
}

class _KarekodGorseliState extends State<KarekodGorseli> {
  late Future<Uint8List> _baytlar = karekodBaytlari(widget.url);

  @override
  void didUpdateWidget(KarekodGorseli eski) {
    super.didUpdateWidget(eski);
    if (eski.url != widget.url) _baytlar = karekodBaytlari(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    // Karekod kutusu her temada beyaz (Marka.logoZemini): renkler temadan
    // değil, beyaz zemine göre sabit.
    return FutureBuilder<Uint8List>(
      future: _baytlar,
      builder: (context, durum) {
        if (durum.hasData) {
          return Image.memory(
            durum.data!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            semanticLabel: 'Karekod',
          );
        }
        if (durum.hasError) {
          return Center(
            child: IconButton(
              tooltip: 'Karekod yüklenemedi, tekrar dene',
              icon: Icon(Icons.refresh_rounded, color: context.cs.primary),
              onPressed: () =>
                  setState(() => _baytlar = karekodBaytlari(widget.url)),
            ),
          );
        }
        return const Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      },
    );
  }
}

class BankaHesabiKarti extends StatefulWidget {
  final BankaHesabiModel hesap;

  /// Karekod bölümü açık başlasın mı (tek hesap varsa açık gelir).
  final bool karekodAcikBaslasin;
  final KarekodYapici karekodYapici;

  /// Karekodu galeriye kaydeder.
  final ValueChanged<BankaHesabiModel>? onKarekodIndir;
  final ValueChanged<BankaHesabiModel>? onKarekodPaylas;

  const BankaHesabiKarti({
    super.key,
    required this.hesap,
    this.karekodAcikBaslasin = false,
    this.karekodYapici = varsayilanKarekodYapici,
    this.onKarekodIndir,
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
              if (widget.onKarekodIndir != null)
                IconButton(
                  tooltip: 'İndir',
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () => widget.onKarekodIndir!(hesap),
                ),
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
      padding:
          const EdgeInsets.fromLTRB(Bosluk.m, Bosluk.m, Bosluk.s, Bosluk.s),
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
                      style:
                          metin.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _KopyalaButonu(
                ipucu: 'Alıcı adını kopyala',
                kopyalandi: _kopyalanan == 'alici',
                onTap: () =>
                    _kopyala('alici', hesap.aliciAdi, 'Alıcı adı kopyalandı'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dar ekranda (320 px) karekod ile açıklama yan yana sığmadığında
          // açıklama alta iner.
          Wrap(
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
                    Text(
                      'İndir ile karekodu galeriye kaydet, sonra banka '
                      'uygulamanda "galeriden karekod oku"yu seç. Paylaş ile '
                      'başka bir uygulamaya gönderebilirsin.',
                      style: context.metin.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // İndir ve Paylaş kartın tam genişliğinde yan yana.
          if (widget.onKarekodIndir != null || widget.onKarekodPaylas != null)
            Padding(
              padding: const EdgeInsets.only(top: Bosluk.m),
              child: Row(
                children: [
                  if (widget.onKarekodIndir != null)
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => widget.onKarekodIndir!(hesap),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('İndir'),
                      ),
                    ),
                  if (widget.onKarekodIndir != null &&
                      widget.onKarekodPaylas != null)
                    const SizedBox(width: Bosluk.s),
                  if (widget.onKarekodPaylas != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onKarekodPaylas!(hesap),
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: const Text('Paylaş'),
                      ),
                    ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _karekodAcik = false),
              child: const Text('Karekodu gizle'),
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
