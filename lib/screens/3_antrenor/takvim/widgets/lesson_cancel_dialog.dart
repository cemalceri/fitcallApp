// lib/screens/3_antrenor/takvim/widgets/lesson_cancel_dialog.dart

import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'takvim_constants.dart';

class LessonCancelDialog extends StatefulWidget {
  final EtkinlikModel ders;
  final int userId;
  final VoidCallback onSuccess;

  const LessonCancelDialog({
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
  }) async {
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Mevcut iptal talebini sorgula
    Map<String, dynamic>? iptalTalebiData;
    try {
      final res = await TakvimService.getDersIptalTalebi(
        dersId: ders.id,
        userId: userId,
      );
      iptalTalebiData = res.data;
    } catch (e) {
      // Hata olursa null kalır
    }

    if (!context.mounted) return;
    Navigator.pop(context); // Loading kapat

    // Dialog göster
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _LessonCancelDialogContent(
        ders: ders,
        userId: userId,
        onSuccess: onSuccess,
        mevcutTalep: iptalTalebiData,
      ),
    );
  }

  @override
  State<LessonCancelDialog> createState() => _LessonCancelDialogState();
}

class _LessonCancelDialogState extends State<LessonCancelDialog> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _LessonCancelDialogContent extends StatefulWidget {
  final EtkinlikModel ders;
  final int userId;
  final VoidCallback onSuccess;
  final Map<String, dynamic>? mevcutTalep;

  const _LessonCancelDialogContent({
    required this.ders,
    required this.userId,
    required this.onSuccess,
    this.mevcutTalep,
  });

  @override
  State<_LessonCancelDialogContent> createState() =>
      _LessonCancelDialogContentState();
}

class _LessonCancelDialogContentState
    extends State<_LessonCancelDialogContent> {
  bool _isSaving = false;
  String? _secilenSebep;
  final _aciklamaCtrl = TextEditingController();

  static const _iptalSebepleri = [
    {
      'code': 'ANTRENOR_MUSAIT_DEGIL',
      'label': 'Müsait değilim',
      'icon': Icons.person_off_rounded
    },
    {
      'code': 'HAVA_KOSULLARI',
      'label': 'Hava koşulları',
      'icon': Icons.cloud_rounded
    },
    {
      'code': 'KORT_SORUNU',
      'label': 'Kort sorunu',
      'icon': Icons.sports_tennis_rounded
    },
    {
      'code': 'KISISEL_MAZERET',
      'label': 'Kişisel mazeret',
      'icon': Icons.person_rounded
    },
    {'code': 'DIGER', 'label': 'Diğer', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void dispose() {
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  bool get _talepVar =>
      widget.mevcutTalep != null && widget.mevcutTalep!['talep_var'] == true;

  Map<String, dynamic>? get _talep => _talepVar
      ? (widget.mevcutTalep!['talep'] as Map?)?.cast<String, dynamic>()
      : null;

  @override
  Widget build(BuildContext context) {
    final katilimcilar = widget.ders.uyeList.map((u) => u.adSoyad).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Content (scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _talepVar
                    ? _buildMevcutTalep()
                    : _buildYeniTalepForm(katilimcilar),
              ),
            ),

            // Actions
            _talepVar ? _buildMevcutTalepActions() : _buildYeniTalepActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (_talepVar ? TakvimColors.pending : TakvimColors.cancelled)
            .withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_talepVar ? TakvimColors.pending : TakvimColors.cancelled)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _talepVar
                  ? Icons.hourglass_empty_rounded
                  : Icons.event_busy_rounded,
              color: _talepVar ? TakvimColors.pending : TakvimColors.cancelled,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _talepVar ? 'İptal Talebi' : 'Ders İptali',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${TimeUtils.formatDateFull(widget.ders.baslangicTarihSaat)} • ${TimeUtils.formatTime(widget.ders.baslangicTarihSaat)}',
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

  Widget _buildMevcutTalep() {
    final talep = _talep!;

    return Column(
      children: [
        const SizedBox(height: 8),

        // Mevcut talep durumu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TakvimColors.pending.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: TakvimColors.pending.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: TakvimColors.pending.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pending_rounded,
                      color: TakvimColors.pending,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Talebiniz Beklemede',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: TakvimColors.pending,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          talep['sebep_display'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: TakvimColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (talep['aciklama'] != null &&
                  (talep['aciklama'] as String).isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    talep['aciklama'],
                    style: TextStyle(
                      fontSize: 13,
                      color: TakvimColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYeniTalepForm(List<String> katilimcilar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Katılımcılar
        if (katilimcilar.isNotEmpty) ...[
          _buildKatilimcilar(katilimcilar),
          const SizedBox(height: 20),
        ],

        // Bilgi
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.blue.shade700),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'İptal talebiniz yönetici onayına gönderilecektir.',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Sebepler
        const Text(
          'İptal Sebebi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _iptalSebepleri.map((s) {
            final isSelected = _secilenSebep == s['code'];
            return ChoiceChip(
              avatar: Icon(
                s['icon'] as IconData,
                size: 18,
                color: isSelected
                    ? TakvimColors.cancelled
                    : TakvimColors.textSecondary,
              ),
              label: Text(s['label'] as String),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _secilenSebep = s['code'] as String);
              },
              selectedColor: TakvimColors.cancelled.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? TakvimColors.cancelled : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Açıklama
        TextField(
          controller: _aciklamaCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Açıklama (isteğe bağlı)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildKatilimcilar(List<String> katilimcilar) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TakvimColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: katilimcilar
            .map((isim) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isim,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMevcutTalepActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Kapat'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _geriCek,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.undo_rounded, size: 18),
              label: const Text(
                'Talebi Geri Çek',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: TakvimColors.pending,
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

  Widget _buildYeniTalepActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Vazgeç'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed:
                  _secilenSebep == null || _isSaving ? null : _talepGonder,
              style: FilledButton.styleFrom(
                backgroundColor: TakvimColors.cancelled,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Talep Gönder',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _talepGonder() async {
    setState(() => _isSaving = true);

    try {
      await TakvimService.createIptalTalebi(
        dersId: widget.ders.id,
        userId: widget.userId,
        sebep: _secilenSebep!,
        aciklama: _aciklamaCtrl.text.trim(),
        rol: 'antrenor',
      );

      if (mounted) {
        Navigator.pop(context);
        ShowMessage.success(context, 'İptal talebi gönderildi');
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ShowMessage.error(context, 'Hata: $e');
    }
  }

  Future<void> _geriCek() async {
    setState(() => _isSaving = true);

    try {
      await TakvimService.iptalTalebiGeriCek(
        talepId: _talep!['id'],
        userId: widget.userId,
      );

      if (mounted) {
        Navigator.pop(context);
        ShowMessage.success(context, 'İptal talebi geri çekildi');
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ShowMessage.error(context, 'Hata: $e');
    }
  }
}
