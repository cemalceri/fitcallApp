// lib/screens/3_antrenor/takvim/widgets/cancelled_lesson_info_dialog.dart

import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/alt_sayfa.dart';
import 'package:flutter/material.dart';
import 'takvim_constants.dart';

class CancelledLessonInfoDialog extends StatelessWidget {
  final EtkinlikModel ders;

  const CancelledLessonInfoDialog({
    super.key,
    required this.ders,
  });

  static Future<void> show({
    required BuildContext context,
    required EtkinlikModel ders,
  }) {
    return altSayfaGoster<void>(
      context,
      cocuk: CancelledLessonInfoDialog(ders: ders),
    );
  }

  @override
  Widget build(BuildContext context) {
    final katilimcilar = ders.uyeList.map((u) => u.adSoyad).toList();

    return SizedBox(
      width: double.infinity,
      child: Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ders bilgileri kartı
                    _buildLessonInfoCard(context),

                    const SizedBox(height: 16),

                    // Katılımcılar
                    if (katilimcilar.isNotEmpty) ...[
                      _buildKatilimcilar(context, katilimcilar),
                      const SizedBox(height: 16),
                    ],

                    // İptal bilgileri kartı
                    _buildCancelInfoCard(context),
                  ],
                ),
              ),
            ),

            // Actions
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.takvim.cancelled.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.takvim.cancelled.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event_busy_rounded,
              color: context.takvim.cancelled,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İptal Edilmiş Ders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${TimeUtils.formatDateFull(ders.baslangicTarihSaat)} • ${TimeUtils.formatTime(ders.baslangicTarihSaat)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.takvim.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kapat',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: context.takvim.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ders Bilgileri',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.takvim.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Saat
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Saat',
            value:
                '${TimeUtils.formatTime(ders.baslangicTarihSaat)} - ${TimeUtils.formatTime(ders.bitisTarihSaat)}',
          ),

          const SizedBox(height: 10),

          // Kort
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Kort',
            value: ders.kortAdi.isNotEmpty ? ders.kortAdi : '-',
          ),

          const SizedBox(height: 10),

          // Seviye
          if (ders.seviye.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.star_outline_rounded,
              label: 'Seviye',
              value: ders.seviye,
            ),
            const SizedBox(height: 10),
          ],

          // Antrenör
          if (ders.antrenorAdi != null && ders.antrenorAdi!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.sports_tennis_rounded,
              label: 'Antrenör',
              value: ders.antrenorAdi!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKatilimcilar(BuildContext context, List<String> katilimcilar) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.takvim.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups_outlined,
                size: 18,
                color: context.takvim.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Katılımcılar (${katilimcilar.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.takvim.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: katilimcilar
                .map((isim) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isim,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.takvim.cancelled.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.takvim.cancelled.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.takvim.cancelled.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.cancel_rounded,
                  color: context.takvim.cancelled,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'İptal Bilgileri',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.takvim.cancelled,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // İptal eden: API'nin `iptal_eden` alanı kullanıcı id'si, ad soyad
          // `iptal_eden_adi`'nda geliyor. Ad gelmiyorsa satırı hiç gösterme
          // (id yazmak kullanıcıya bir şey ifade etmiyor).
          if (ders.iptalEdenAdi != null && ders.iptalEdenAdi!.isNotEmpty) ...[
            _CancelInfoRow(
              label: 'İptal Eden',
              value: ders.iptalEdenAdi!,
            ),
            const SizedBox(height: 10),
          ],

          // İptal tarihi
          if (ders.iptalTarihSaat != null) ...[
            _CancelInfoRow(
              label: 'İptal Tarihi',
              value: _formatDateTime(ders.iptalTarihSaat!),
            ),
            const SizedBox(height: 10),
          ],

          // İptal nedeni (eğer varsa - model'de yoksa eklenebilir)

          // Bilgi mesajı
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: context.takvim.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bu ders iptal edilmiştir.',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.takvim.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: context.takvim.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Kapat',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.takvim.textMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.takvim.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.takvim.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _CancelInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CancelInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.takvim.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.takvim.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
