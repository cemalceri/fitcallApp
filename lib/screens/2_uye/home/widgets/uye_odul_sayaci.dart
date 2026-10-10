// lib/screens/2_uye/home/widgets/uye_odul_sayaci.dart
//
// Turnike geçiş sayacı: her tesis girişinde fincan biraz daha dolar, eşiğe
// ulaşınca üye ödülünü alır ve kafede kullanacağı kodu görür.
//
// Sayfa API çağrısı yapmadan da pump edilebilsin diye veri dışarıdan verilir
// (taşma testi bu widget'ı doğrudan render eder).

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/uye_odul_model.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fincandaki kahvenin rengi. Gerçek bir nesnenin resmi olduğu için temaya
/// göre değişmez; fincanın çizgisi ve kartın geri kalanı temadan gelir.
const Color _kKahve = Color(0xFFB45309);

/// Ödül tanımındaki `ikon` anahtarının Material karşılığı. Tanımsız anahtarlar
/// genel hediye ikonuna düşer; ödül her zaman kahve olmayabilir.
IconData odulIkonu(String ikon) {
  switch (ikon) {
    case 'kahve':
      return Icons.local_cafe_rounded;
    default:
      return Icons.card_giftcard_rounded;
  }
}

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

  void _kodGoster(
      BuildContext context, OdulKoduModel kod, OdulDurumModel durum) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _OdulKodSheet(kod: kod, odulAdi: durum.odulAdi, ikon: durum.ikon),
    );
  }

  void _bilgiGoster(BuildContext context, OdulDurumModel durum) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OdulBilgiSheet(durum: durum),
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

    // Sayma aşamasında kartın tamamı bilgi sayfasını açar; buton çıktığında
    // karta dokunmak butonla karışmasın diye yalnız ⓘ açar.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hazir ? null : () => _bilgiGoster(context, durum),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          // Ödül hazırken kenarlık ana renkte; kartın kendisi nötr kalır.
          border: Border.all(
            color: hazir
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: hazir ? 1.5 : 1,
          ),
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
                IconButton(
                  onPressed: () => _bilgiGoster(context, durum),
                  tooltip: 'Ödül nasıl kazanılır?',
                  icon: Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                ),
              ],
            ),
            if (durum.talepEdilebilir) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _talepEdiliyor ? null : _odulAl,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _talepEdiliyor
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: ButonYukleniyorGostergesi(),
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
                      _kodGoster(context, durum.bekleyenOdul!, durum),
                  style: FilledButton.styleFrom(
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
          // Motivasyon çubuğu: ikinci takım renginin geçiş şeridiyle dolar.
          builder: (context, deger, _) => GecisCubugu(deger: deger),
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
        painter: _FincanPainter(
          doluluk: deger,
          cizgi: context.cs.onSurfaceVariant,
          bos: context.cs.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _FincanPainter extends CustomPainter {
  final double doluluk;
  final Color cizgi;
  final Color bos;

  _FincanPainter({
    required this.doluluk,
    required this.cizgi,
    required this.bos,
  });

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
    dolgu.color = bos;
    canvas.drawPath(govde, dolgu);

    // Kahve seviyesi
    if (doluluk > 0) {
      final seviye = alt - (alt - ust) * doluluk.clamp(0.0, 1.0);
      canvas.save();
      canvas.clipPath(govde);
      dolgu.color = _kKahve;
      canvas.drawRect(
          Rect.fromLTRB(solUst - 1, seviye, sagUst + 1, alt), dolgu);
      canvas.restore();
    }

    final kalem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..color = cizgi;

    canvas.drawPath(govde, kalem);

    // Kulp
    final kulp = Path()
      ..moveTo(sagUst, ust + (alt - ust) * 0.18)
      ..cubicTo(
        w * 1.02,
        ust + (alt - ust) * 0.18,
        w * 1.02,
        ust + (alt - ust) * 0.62,
        sagUst - daralma * 0.4,
        ust + (alt - ust) * 0.62,
      );
    canvas.drawPath(kulp, kalem);

    // Tabak
    final tabak = RRect.fromLTRBR(
      0,
      h * 0.86,
      w * 0.80,
      h * 0.94,
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(tabak, Paint()..color = cizgi);
  }

  @override
  bool shouldRepaint(covariant _FincanPainter oldDelegate) =>
      oldDelegate.doluluk != doluluk ||
      oldDelegate.cizgi != cizgi ||
      oldDelegate.bos != bos;
}

/// Ödül kodunun kafede gösterildiği alt sayfa.
class _OdulKodSheet extends StatelessWidget {
  final OdulKoduModel kod;
  final String odulAdi;
  final String ikon;

  const _OdulKodSheet({
    required this.kod,
    required this.odulAdi,
    required this.ikon,
  });

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
            Icon(odulIkonu(ikon), size: 34, color: colorScheme.primary),
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
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      kod.kod,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Son kullanma: ${kod.sonKullanmaMetin}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer,
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

/// "Bu ne?" sorusunun cevabı: ödülün nasıl kazanıldığını anlatan alt sayfa.
///
/// Ödüle özgü metinler (ad, açıklama, ikon, eşik, geçerlilik) ödül tanımından
/// gelir; kuralların kendisi (gün sayımı, sıfırlanma) backend'deki
/// odul_service ile aynı olduğu için burada sabit yazılır.
class OdulBilgiSheet extends StatelessWidget {
  final OdulDurumModel durum;

  const OdulBilgiSheet({super.key, required this.durum});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final aciklama = durum.aciklama?.trim() ?? '';

    final adimlar = <String>[
      'Turnikeden tesise giriş yaptığın her gün 1 sayılır. '
          'Aynı gün birden fazla giriş tek sayılır.',
      '${durum.esik} güne ulaşınca "Ödülü al" butonu çıkar; '
          'dokununca sana özel bir kod oluşur.',
      durum.gecerlilikGun > 0
          ? 'Kod ${durum.gecerlilikGun} gün geçerlidir. '
              'Görevliye göstererek kullanırsın.'
          : 'Kodu görevliye göstererek kullanırsın.',
      'Kod kullanılınca sayaç sıfırdan başlar. Süresi dolarsa hakkın '
          'kaybolmaz, yeni kod alabilirsin.',
    ];

    final String durumMetni;
    if (durum.kodHazir) {
      durumMetni = 'Kodun hazır, kullanılmayı bekliyor.';
    } else if (durum.hakEdildi) {
      durumMetni = 'Ödülünü hak ettin, kodunu alabilirsin.';
    } else {
      durumMetni = 'Şu an ${durum.sayac} / ${durum.esik} · '
          '${durum.kalan} gün kaldı';
    }

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(odulIkonu(durum.ikon),
                        size: 22, color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${durum.odulAdi} nasıl kazanılır?',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              if (aciklama.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  aciklama,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              for (var i = 0; i < adimlar.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          adimlar[i],
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  durumMetni,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
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
