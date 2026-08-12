// lib/screens/3_antrenor/takvim/widgets/yoklama_hizli_secim.dart
//
// Ders yoklamasının açılış ekranı: üç seçenek.
//
// Antrenörün en sık yaşadığı durum "ders oldu, herkes geldi" — o yüzden tek
// dokunuşluk büyük bir kart olarak en üstte duruyor. Sapmalar (eksik/fazla
// katılım, dersin hiç yapılmaması) alttaki iki kartla detay adımına götürüyor.
//
// Üçü de kart: "Ders yapılmadı" eskiden düz bir metin butonuydu ve diğer iki
// seçeneğin yanında ikinci sınıf görünüyordu; oysa yoklamanın üç meşru
// sonucundan biri. Renkler durumun kendisinden geliyor — yeşil yapıldı,
// turuncu düzeltme gerekiyor, kırmızı yapılmadı.
//
// Diyalog initState'te API çağırdığı için doğrudan render edilemiyor; bu
// görünüm veriyle beslenen ayrı bir widget olarak duruyor ki taşma testi
// (test/tasma_ekranlar_test.dart) onu ölçebilsin.

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'takvim_constants.dart';

class YoklamaHizliSecim extends StatelessWidget {
  /// Derste planlı görünen katılımcı sayısı.
  final int planliSayi;

  /// Hızlı onay kaydediliyor mu — kart kilitlenir, ikon yerine spinner döner.
  final bool kaydediliyor;

  /// "Herkes geldi" — tek dokunuşla kaydet.
  final VoidCallback onHepsiGeldi;

  /// Katılımcı listesini düzenlemek için detaya geç.
  final VoidCallback onEksikFazla;

  /// "Ders yapılmadı" — neden seçimi için detaya geç.
  final VoidCallback onYapilmadi;

  const YoklamaHizliSecim({
    super.key,
    required this.planliSayi,
    required this.onHepsiGeldi,
    required this.onEksikFazla,
    required this.onYapilmadi,
    this.kaydediliyor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HerkesGeldiKarti(
            planliSayi: planliSayi,
            kaydediliyor: kaydediliyor,
            onTap: onHepsiGeldi,
          ),
          const SizedBox(height: Bosluk.l),
          const _AyracEtiketi(metin: 'ya da'),
          const SizedBox(height: Bosluk.l),
          _DurumKarti(
            ikon: Icons.groups_rounded,
            renk: context.cs.primary,
            baslik: 'Eksik ya da fazla var',
            altBaslik: 'Katılımcıları tek tek işaretleyin',
            onTap: kaydediliyor ? null : onEksikFazla,
          ),
          const SizedBox(height: Bosluk.s),
          _DurumKarti(
            ikon: Icons.event_busy_rounded,
            renk: context.takvim.cancelled,
            baslik: 'Ders yapılmadı',
            altBaslik: 'Nedenini seçip kaydedin',
            zeminliMi: true,
            onTap: kaydediliyor ? null : onYapilmadi,
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              KARTLAR                                       */
/* -------------------------------------------------------------------------- */

/// Ana seçenek: büyük, ortalanmış, yeşil zeminli tek dokunuş kartı.
class _HerkesGeldiKarti extends StatelessWidget {
  final int planliSayi;
  final bool kaydediliyor;
  final VoidCallback onTap;

  const _HerkesGeldiKarti({
    required this.planliSayi,
    required this.kaydediliyor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final renk = context.takvim.completed;

    return _KartKabugu(
      zemin: renk.withValues(alpha: 0.10),
      kenar: renk.withValues(alpha: 0.45),
      kenarKalinligi: 1.5,
      onTap: kaydediliyor ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Bosluk.l,
          vertical: Bosluk.xl,
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: kaydediliyor
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: renk,
                      ),
                    )
                  : Icon(Icons.check_rounded, color: renk, size: 32),
            ),
            const SizedBox(height: Bosluk.m),
            Text(
              'Ders yapıldı, herkes geldi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: renk,
                height: 1.25,
              ),
            ),
            const SizedBox(height: Bosluk.s),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Bosluk.m,
                vertical: Bosluk.xs,
              ),
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Yaricap.xl),
              ),
              child: Text(
                planliSayi > 0
                    ? '$planliSayi kişi katıldı sayılır'
                    : 'Planlı katılımcı yok',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: renk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// İkincil seçenekler: ikon rozeti + başlık + açıklama + ok.
///
/// [zeminliMi] true ise kart [renk] tonunda bir zemin ve kenarlık alır —
/// "ders yapılmadı" böylece kendi durum rengiyle okunur; false ise nötr
/// yüzeyde durur.
class _DurumKarti extends StatelessWidget {
  final IconData ikon;
  final Color renk;
  final String baslik;
  final String altBaslik;
  final bool zeminliMi;
  final VoidCallback? onTap;

  const _DurumKarti({
    required this.ikon,
    required this.renk,
    required this.baslik,
    required this.altBaslik,
    required this.onTap,
    this.zeminliMi = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return _KartKabugu(
      zemin: zeminliMi ? renk.withValues(alpha: 0.07) : cs.surfaceContainerLow,
      kenar: zeminliMi ? renk.withValues(alpha: 0.35) : cs.outlineVariant,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Bosluk.m,
          vertical: Bosluk.m,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(Yaricap.m),
              ),
              child: Icon(ikon, color: renk, size: 22),
            ),
            const SizedBox(width: Bosluk.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    baslik,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: zeminliMi ? renk : cs.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    altBaslik,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.takvim.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Bosluk.s),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: zeminliMi
                  ? renk.withValues(alpha: 0.7)
                  : context.takvim.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Üç kartın ortak kabuğu: dokunma dalgası doğru köşe yarıçapıyla kırpılsın
/// diye zemin `Material` üzerinde, kenarlık dışta duruyor.
class _KartKabugu extends StatelessWidget {
  final Color zemin;
  final Color kenar;
  final double kenarKalinligi;
  final VoidCallback? onTap;
  final Widget child;

  const _KartKabugu({
    required this.zemin,
    required this.kenar,
    required this.onTap,
    required this.child,
    this.kenarKalinligi = 1,
  });

  @override
  Widget build(BuildContext context) {
    final yaricap = BorderRadius.circular(Yaricap.l);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: yaricap,
        border: Border.all(color: kenar, width: kenarKalinligi),
      ),
      child: Material(
        color: zemin,
        borderRadius: yaricap,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: child,
        ),
      ),
    );
  }
}

/// "ya da" ayracı — ana seçenekle alternatifleri ayırır.
class _AyracEtiketi extends StatelessWidget {
  final String metin;

  const _AyracEtiketi({required this.metin});

  @override
  Widget build(BuildContext context) {
    Widget cizgi() => Expanded(
          child: Divider(color: context.cs.outlineVariant, height: 1),
        );

    return Row(
      children: [
        cizgi(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Bosluk.m),
          child: Text(
            metin,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.takvim.textMuted,
            ),
          ),
        ),
        cizgi(),
      ],
    );
  }
}
