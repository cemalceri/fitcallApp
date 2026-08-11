// lib/screens/1_common/widgets/bos_durum.dart

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

/// Liste ekranlarının "kayıt yok" görünümü.
///
/// Boş ekran, kullanıcının en çok yardıma ihtiyaç duyduğu andır: yalnız
/// "Ders bulunmuyor" yazmak kullanıcıyı çıkmazda bırakır. Bu bileşen ne
/// olduğunu, neden boş olduğunu ve bir sonraki adımı birlikte gösterir.
class BosDurum extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String aciklama;

  /// Birincil eylem — "ne yapayım" sorusunun cevabı. Yoksa yalnız metin çıkar.
  final String? eylemEtiketi;
  final IconData? eylemIkonu;
  final VoidCallback? onEylem;

  /// İkincil eylem (ör. "Yenile").
  final String? ikinciEylemEtiketi;
  final VoidCallback? onIkinciEylem;

  /// Durumun tonu: uyarı/hata bağlamında ikon rengi değişir.
  final Color? ikonRengi;

  const BosDurum({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    this.eylemEtiketi,
    this.eylemIkonu,
    this.onEylem,
    this.ikinciEylemEtiketi,
    this.onIkinciEylem,
    this.ikonRengi,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final renk = ikonRengi ?? cs.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Bosluk.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, size: 40, color: renk),
              ),
              const SizedBox(height: Bosluk.l),
              Text(
                baslik,
                textAlign: TextAlign.center,
                style: context.metin.titleMedium,
              ),
              const SizedBox(height: Bosluk.s),
              Text(
                aciklama,
                textAlign: TextAlign.center,
                style: context.metin.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (onEylem != null && eylemEtiketi != null) ...[
                const SizedBox(height: Bosluk.xl),
                FilledButton.icon(
                  onPressed: onEylem,
                  icon: Icon(eylemIkonu ?? Icons.arrow_forward_rounded),
                  label: Text(eylemEtiketi!),
                ),
              ],
              if (onIkinciEylem != null && ikinciEylemEtiketi != null) ...[
                const SizedBox(height: Bosluk.s),
                TextButton(
                  onPressed: onIkinciEylem,
                  child: Text(ikinciEylemEtiketi!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
