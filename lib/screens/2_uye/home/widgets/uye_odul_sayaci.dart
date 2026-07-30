// lib/screens/2_uye/home/widgets/uye_odul_sayaci.dart
//
// Turnike geçiş sayacı: her tesis girişinde fincan biraz daha dolar, eşiğe
// ulaşınca üye ödülünü alır ve kafede kullanacağı kodu görür.
//
// Sayfa API çağrısı yapmadan da pump edilebilsin diye veri dışarıdan verilir
// (taşma testi bu widget'ı doğrudan render eder).

import 'package:fitcall/models/2_uye/uye_odul_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _kKahveKoyu = Color(0xFF78350F);
const Color _kKahve = Color(0xFFB45309);
const Color _kKahveAcik = Color(0xFFF59E0B);

class UyeOdulSayaci extends StatefulWidget {
  final OdulDurumModel? durum;
  final bool isLoading;

  /// "Ödülü al" butonu. Hata yönetimi çağıran sayfada.
  final Future<void> Function()? onOdulAl;

  const UyeOdulSayaci({
    super.key,
    this.durum,
    this.isLoading = false,
    this.onOdulAl,
  });

  @override
  State<UyeOdulSayaci> createState() => _UyeOdulSayaciState();
}

class _UyeOdulSayaciState extends State<UyeOdulSayaci> {
  bool _talepEdiliyor = false;

  Future<void> _odulAl() async {
    if (_talepEdiliyor || widget.onOdulAl == null) return;
    HapticFeedback.lightImpact();
    setState(() => _talepEdiliyor = true);
    try {
      await widget.onOdulAl!();
    } finally {
      if (mounted) setState(() => _talepEdiliyor = false);
    }
  }

  void _kodGoster(BuildContext context, OdulKoduModel kod, String odulAdi) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OdulKodSheet(kod: kod, odulAdi: odulAdi),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return const _SayacIskelet();

    final durum = widget.durum;
    // Tanımlı ödül yoksa ya da veri gelmediyse kart hiç görünmez.
    if (durum == null || !durum.aktif) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final hazir = durum.kodHazir || durum.talepEdilebilir;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hazir ? _kKahveAcik.withValues(alpha: 0.10) : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hazir
              ? _kKahveAcik.withValues(alpha: 0.35)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _kKahve.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Fincan(doluluk: durum.doluluk),
              const SizedBox(width: 14),
              Expanded(child: _Metinler(durum: durum)),
            ],
          ),
          if (durum.talepEdilebilir) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _talepEdiliyor ? null : _odulAl,
                style: FilledButton.styleFrom(
                  backgroundColor: _kKahve,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _talepEdiliyor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.card_giftcard_rounded, size: 18),
                label: Text(_talepEdiliyor ? 'Alınıyor...' : 'Ödülü al'),
              ),
            ),
          ] else if (durum.kodHazir) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    _kodGoster(context, durum.bekleyenOdul!, durum.odulAdi),
                style: FilledButton.styleFrom(
                  backgroundColor: _kKahve,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                label: const Text('Kodu göster'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kartın sağ tarafı: başlık, alt bilgi ve ilerleme çubuğu.
class _Metinler extends StatelessWidget {
  final OdulDurumModel durum;

  const _Metinler({required this.durum});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final yuzde = (durum.doluluk * 100).round();

    final String baslik;
    final String altBilgi;
    if (durum.kodHazir) {
      baslik = '${durum.odulAdi} kodun hazır';
      altBilgi =
          'Kafede göster · son gün ${durum.bekleyenOdul!.sonKullanmaMetin}';
    } else if (durum.hakEdildi) {
      baslik = '${durum.odulAdi} hakkını kazandın';
      altBilgi = '${durum.esik} giriş tamamlandı';
    } else {
      baslik = 'Fincanın %$yuzde dolu';
      altBilgi =
          '${durum.sayac} giriş · ${durum.kalan} giriş sonra ${durum.odulAdi.toLowerCase()}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          baslik,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          altBilgi,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: durum.doluluk),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, deger, _) => ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: deger,
              minHeight: 6,
              backgroundColor: _kKahveAcik.withValues(alpha: 0.20),
              valueColor: const AlwaysStoppedAnimation<Color>(_kKahve),
            ),
          ),
        ),
      ],
    );
  }
}

/// Doluluk oranına göre dolan kahve fincanı.
class _Fincan extends StatelessWidget {
  final double doluluk;

  const _Fincan({required this.doluluk});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: doluluk),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, deger, _) => CustomPaint(
        size: const Size(58, 64),
        painter: _FincanPainter(doluluk: deger),
      ),
    );
  }
}

class _FincanPainter extends CustomPainter {
  final double doluluk;

  _FincanPainter({required this.doluluk});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final solUst = w * 0.06;
    final sagUst = w * 0.70;
    final ust = h * 0.16;
    final alt = h * 0.76;
    final daralma = w * 0.07;
    final koseYaricap = w * 0.10;

    // Fincan gövdesi (aşağı doğru hafif daralan)
    final govde = Path()
      ..moveTo(solUst, ust)
      ..lineTo(sagUst, ust)
      ..lineTo(sagUst - daralma, alt - koseYaricap)
      ..quadraticBezierTo(
          sagUst - daralma, alt, sagUst - daralma - koseYaricap, alt)
      ..lineTo(solUst + daralma + koseYaricap, alt)
      ..quadraticBezierTo(
          solUst + daralma, alt, solUst + daralma, alt - koseYaricap)
      ..close();

    final dolgu = Paint()..style = PaintingStyle.fill;

    // Boş kısım
    dolgu.color = _kKahveAcik.withValues(alpha: 0.15);
    canvas.drawPath(govde, dolgu);

    // Kahve seviyesi
    if (doluluk > 0) {
      final seviye = alt - (alt - ust) * doluluk.clamp(0.0, 1.0);
      canvas.save();
      canvas.clipPath(govde);
      dolgu.color = _kKahve;
      canvas.drawRect(Rect.fromLTRB(solUst - 1, seviye, sagUst + 1, alt), dolgu);
      canvas.restore();
    }

    final cizgi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..color = _kKahveKoyu;

    canvas.drawPath(govde, cizgi);

    // Kulp
    final kulp = Path()
      ..moveTo(sagUst, ust + (alt - ust) * 0.18)
      ..cubicTo(
        w * 1.02, ust + (alt - ust) * 0.18,
        w * 1.02, ust + (alt - ust) * 0.62,
        sagUst - daralma * 0.4, ust + (alt - ust) * 0.62,
      );
    canvas.drawPath(kulp, cizgi);

    // Tabak
    final tabak = RRect.fromLTRBR(
      0,
      h * 0.86,
      w * 0.80,
      h * 0.94,
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(tabak, Paint()..color = _kKahveKoyu);
  }

  @override
  bool shouldRepaint(covariant _FincanPainter oldDelegate) =>
      oldDelegate.doluluk != doluluk;
}

/// Ödül kodunun kafede gösterildiği alt sayfa.
class _OdulKodSheet extends StatelessWidget {
  final OdulKoduModel kod;
  final String odulAdi;

  const _OdulKodSheet({required this.kod, required this.odulAdi});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Icon(Icons.local_cafe_rounded, size: 34, color: _kKahve),
            const SizedBox(height: 10),
            Text(
              '$odulAdi ikramın hazır',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bu kodu kafede görevliye göster.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: _kKahveAcik.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _kKahveAcik.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      kod.kod,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: _kKahveKoyu,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Son kullanma: ${kod.sonKullanmaMetin}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: kod.kod));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kod kopyalandı')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Kopyala'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(backgroundColor: _kKahve),
                    child: const Text('Tamam'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Veri gelene kadar gösterilen iskelet.
class _SayacIskelet extends StatelessWidget {
  const _SayacIskelet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gri = colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 64,
            decoration: BoxDecoration(
              color: gri,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 140, color: gri),
                const SizedBox(height: 8),
                Container(height: 10, width: 100, color: gri),
                const SizedBox(height: 10),
                Container(height: 6, color: gri),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
