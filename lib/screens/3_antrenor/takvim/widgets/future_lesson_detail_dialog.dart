// lib/screens/3_antrenor/takvim/widgets/future_lesson_detail_dialog.dart

// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lesson_cancel_dialog.dart';
import 'lesson_devir_dialog.dart';
import 'takvim_constants.dart';

class FutureLessonDetailDialog extends StatelessWidget {
  final EtkinlikModel ders;
  final int userId;
  final VoidCallback onSuccess;

  const FutureLessonDetailDialog({
    super.key,
    required this.ders,
    required this.userId,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required EtkinlikModel ders,
    required int userId,
    required VoidCallback onSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => FutureLessonDetailDialog(
        ders: ders,
        userId: userId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 480,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDersBilgisi(),
                    const SizedBox(height: 12),
                    _buildDetaySatirlari(),
                    if (ders.uyeList.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildKatilimDurumlari(),
                    ],
                    if (ders.aktifDevirTalebi != null) ...[
                      const SizedBox(height: 16),
                      _buildDevirTalebiUyari(),
                    ],
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                  HEADER                                    */
  /* -------------------------------------------------------------------------- */

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TakvimColors.primary.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event_note_rounded,
              color: TakvimColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ders Detayı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${TimeUtils.formatDateFull(ders.baslangicTarihSaat)} • ${TimeUtils.formatTime(ders.baslangicTarihSaat)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: TakvimColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: TakvimColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              DERS BİLGİSİ                                  */
  /* -------------------------------------------------------------------------- */

  Widget _buildDersBilgisi() {
    final baslangic = ders.baslangicTarihSaat;
    final bitis = ders.bitisTarihSaat;
    final sure = bitis.difference(baslangic).inMinutes;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TakvimColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sports_tennis_rounded,
                    color: TakvimColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kort',
                        style: TextStyle(
                          fontSize: 11,
                          color: TakvimColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ders.kortAdi.isNotEmpty ? ders.kortAdi : '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TakvimColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
                    color: TakvimColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saat',
                        style: TextStyle(
                          fontSize: 11,
                          color: TakvimColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${TimeUtils.formatTime(baslangic)} ($sure dk)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                            DETAY SATIRLARI                                 */
  /* -------------------------------------------------------------------------- */

  Widget _buildDetaySatirlari() {
    final rows = <Widget>[];

    if (ders.antrenorAdi != null && ders.antrenorAdi!.isNotEmpty) {
      rows.add(_DetaySatir(
        icon: Icons.sports_tennis_rounded,
        label: 'Antrenör',
        value: ders.antrenorAdi!,
      ));
    }

    if (ders.seviye.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(_DetaySatir(
        icon: Icons.star_outline_rounded,
        label: 'Seviye',
        value: ders.seviye,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                          KATILIM DURUMLARI                                 */
  /* -------------------------------------------------------------------------- */

  Widget _buildKatilimDurumlari() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_rounded,
                size: 18, color: TakvimColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Katılımcı Durumları (${ders.uyeList.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TakvimColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ders.uyeList.map((uye) {
                final teyit = ders.getTeyitBilgisi(uye.id);
                return _buildUyeDurumChip(uye, teyit);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUyeDurumChip(UyeLiteModel uye, UyeTeyit? teyit) {
    final katilacakMi = teyit?.katilacakMi;
    final color = katilacakMi == null
        ? const Color(0xFFF59E0B)
        : katilacakMi
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);
    final icon = katilacakMi == null
        ? Icons.help_outline_rounded
        : katilacakMi
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;
    final durum = katilacakMi == null
        ? 'Henüz cevap vermedi'
        : katilacakMi
            ? 'Katılacağını bildirdi'
            : 'Katılmayacağını bildirdi';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              uye.adSoyad,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              durum,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                        DEVIR TALEBI UYARISI                                */
  /* -------------------------------------------------------------------------- */

  Widget _buildDevirTalebiUyari() {
    final talep = ders.aktifDevirTalebi!;
    final benTalepEden = talep.benTalepEdenim;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TakvimColors.pending.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TakvimColors.pending.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TakvimColors.pending.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: TakvimColors.pending,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benTalepEden
                      ? 'Devir talebiniz cevap bekliyor'
                      : 'Size devir teklifi geldi',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TakvimColors.pending,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Detay için "Devret" butonuna dokunun',
                  style: TextStyle(
                    fontSize: 11,
                    color: TakvimColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                ACTIONS                                     */
  /* -------------------------------------------------------------------------- */

  Widget _buildActions(BuildContext context) {
    final devirVar = ders.aktifDevirTalebi != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _devretAc(context),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(
                devirVar ? 'Talebi Gör' : 'Devret',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TakvimColors.primary,
                side: BorderSide(color: TakvimColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _iptalAc(context),
              icon: const Icon(Icons.event_busy_rounded, size: 18),
              label: const Text(
                'Dersi İptal Et',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: TakvimColors.cancelled,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _devretAc(BuildContext context) {
    HapticFeedback.selectionClick();
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    Navigator.pop(context);
    Future.microtask(() {
      LessonDevirDialog.show(
        context: rootContext,
        ders: ders,
        onSuccess: onSuccess,
      );
    });
  }

  void _iptalAc(BuildContext context) {
    HapticFeedback.selectionClick();
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    Navigator.pop(context);
    Future.microtask(() {
      LessonCancelDialog.show(
        context: rootContext,
        ders: ders,
        userId: userId,
        onSuccess: onSuccess,
      );
    });
  }
}

class _DetaySatir extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetaySatir({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: TakvimColors.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: TakvimColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TakvimColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
