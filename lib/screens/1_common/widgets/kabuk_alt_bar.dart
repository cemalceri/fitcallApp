// lib/screens/1_common/widgets/kabuk_alt_bar.dart

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Alt sekme barındaki bir sekmenin tanımı.
class KabukSekmesi {
  final IconData ikon;
  final IconData seciliIkon;
  final String etiket;

  const KabukSekmesi({
    required this.ikon,
    required this.seciliIkon,
    required this.etiket,
  });
}

/// Kalıcı sekme kabuğunun alt barı.
///
/// Eski "hızlı erişim barı" her dokunuşta `Navigator.pushNamed` çağırıyordu:
/// bar kayboluyor, üstte geri oku beliriyor ve sekmeler arası geçişte durum
/// sıfırlanıyordu. Burada bar `IndexedStack` üzerindeki aktif sekmeyi
/// değiştirir; hangi sekmede olunduğu ikon + etiket + üstteki çubukla belli
/// olur. İkonlar tek renk: yalnız aktif olan vurgulanır — beş ayrı renk
/// hiyerarşi değil gürültü üretiyordu.
class KabukAltBar extends StatelessWidget {
  /// Kenardaki sekmeler (merkez buton hariç). 4 öğe beklenir: ilk ikisi solda,
  /// son ikisi sağda.
  final List<KabukSekmesi> sekmeler;
  final int aktifIndeks;
  final ValueChanged<int> onSekme;

  /// Merkezdeki vurgulu buton (QR). Sekme değiştirmez, sayfa açar.
  final VoidCallback onMerkez;
  final String merkezEtiket;
  final IconData merkezIkon;

  const KabukAltBar({
    super.key,
    required this.sekmeler,
    required this.aktifIndeks,
    required this.onSekme,
    required this.onMerkez,
    this.merkezEtiket = 'QR Giriş',
    this.merkezIkon = Icons.qr_code_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final sol = sekmeler.take(2).toList();
    final sag = sekmeler.skip(2).toList();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        // Sabit yükseklik yok: 1.3x yazı ölçeğinde etiketler barı taşırıyordu.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < sol.length; i++)
                _Sekme(
                  sekme: sol[i],
                  secili: aktifIndeks == i,
                  onTap: () => _sec(i),
                ),
              _MerkezButon(
                etiket: merkezEtiket,
                ikon: merkezIkon,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onMerkez();
                },
              ),
              for (var i = 0; i < sag.length; i++)
                _Sekme(
                  sekme: sag[i],
                  secili: aktifIndeks == i + sol.length,
                  onTap: () => _sec(i + sol.length),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _sec(int indeks) {
    if (indeks == aktifIndeks) return;
    HapticFeedback.selectionClick();
    onSekme(indeks);
  }
}

class _Sekme extends StatelessWidget {
  final KabukSekmesi sekme;
  final bool secili;
  final VoidCallback onTap;

  const _Sekme({
    required this.sekme,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final renk = secili ? cs.primary : cs.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        button: true,
        selected: secili,
        label: sekme.etiket,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Aktif sekmenin üstündeki kısa çubuk — hangi sekmede olunduğu
                // yalnız renkle değil, biçimle de anlaşılsın (renk körlüğü).
                Container(
                  height: 3,
                  width: 24,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: secili ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(secili ? sekme.seciliIkon : sekme.ikon,
                    size: 22, color: renk),
                const SizedBox(height: 2),
                Text(
                  sekme.etiket,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                    color: renk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MerkezButon extends StatelessWidget {
  final String etiket;
  final IconData ikon;
  final VoidCallback onTap;

  const _MerkezButon({
    required this.etiket,
    required this.ikon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Expanded(
      child: Semantics(
        button: true,
        label: etiket,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: context.renkler.vurgu,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    // Koyu temada turuncu açıldığı için beyaz ikon okunmaz
                    // hâle geliyor; orada koyu ikon kullanılır.
                    child: Icon(
                      ikon,
                      color: context.koyuTema ? cs.onPrimary : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                etiket,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
