// lib/screens/7_yonetici/program/widgets/ders_sil_dialog.dart
//
// Kalıcı silme uyarısı. Silmenin ne yok edeceği backend'den sayıyla gelir
// (yoneticiEtkinlikSilOnizleme), genel bir metin yerine gerçek etki gösterilir.
//
// İptal ile fark: iptalde 24 saat kuralı, telafi üretimi, paket iadesi/düşümü ve
// borç işlemleri çalışır ve kayıt izlenebilir kalır. Silmede ders ve bağlı her
// şey yok olur; bu derse verilmiş telafi hakları da (CASCADE) kaybolur.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:flutter/material.dart';

class DersSilDialog extends StatelessWidget {
  final SilmeEtkisi etki;

  const DersSilDialog({super.key, required this.etki});

  /// Kullanıcı silmeyi onaylarsa true döner.
  static Future<bool> ac(BuildContext context, SilmeEtkisi etki) async {
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (_) => DersSilDialog(etki: etki),
    );
    return sonuc == true;
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final satirlar = etki.uyariSatirlari;

    return AlertDialog(
      icon: Icon(Icons.delete_forever, color: renk.error, size: 32),
      title: const Text('Ders kalıcı olarak silinsin mi?'),
      content: ConstrainedBox(
        // Uzun listelerde dialog ekranı taşırmasın
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${etki.dersTarih} ${etki.dersSaat}'
                '${etki.dersKortAdi.isEmpty ? '' : ' · ${etki.dersKortAdi}'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (satirlar.isEmpty)
                Text(
                  'Bu derse bağlı başka kayıt bulunmuyor.',
                  style: TextStyle(color: renk.onSurfaceVariant),
                )
              else ...[
                Text(
                  'Bu derse bağlı şu kayıtlar da silinecek:',
                  style: TextStyle(color: renk.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                ...satirlar.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5, right: 8),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: renk.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(child: Text(s)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: renk.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: renk.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu işlem geri alınamaz. Dersi kayıt altında tutmak '
                        'için "İptal et" seçeneğini kullanın.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: renk.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: renk.error,
            foregroundColor: renk.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Kalıcı olarak sil'),
        ),
      ],
    );
  }
}
