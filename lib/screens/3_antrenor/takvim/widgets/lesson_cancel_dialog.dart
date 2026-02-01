// lib/screens/3_antrenor/takvim/widgets/lesson_cancel_dialog.dart

import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:flutter/material.dart';
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
  final _aciklamaCtrl = TextEditingController();

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: _talepVar ? _buildMevcutTalep() : _buildYeniTalepForm(),
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
        color: TakvimColors.primaryLight.withValues(alpha: 0.3),
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
        // Kort ve Saat Bilgisi
        _buildDersBilgisi(),
        const SizedBox(height: 16),

        // Katılımcı durumları
        if (widget.ders.uyeList.isNotEmpty) ...[
          _buildKatilimDurumlari(),
          const SizedBox(height: 20),
          // Ayırıcı çizgi
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 20),
        ],

        // Mevcut iptal talebi
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İptal Talebi Beklemede',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: TakvimColors.pending,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Yönetici onayı bekleniyor',
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

  Widget _buildYeniTalepForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kort ve Saat Bilgisi
        _buildDersBilgisi(),
        const SizedBox(height: 16),

        // Katılımcı durumları
        if (widget.ders.uyeList.isNotEmpty) ...[
          _buildKatilimDurumlari(),
          const SizedBox(height: 20),
          // Ayırıcı çizgi
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 20),
        ],

        // İptal Talebi Başlığı
        Row(
          children: [
            Icon(Icons.event_busy_rounded,
                size: 20, color: TakvimColors.cancelled),
            const SizedBox(width: 8),
            const Text(
              'İptal Talebi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),

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
              Icon(Icons.info_outline_rounded,
                  color: Colors.blue.shade700, size: 20),
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

        const SizedBox(height: 16),

        // Açıklama
        const Text(
          'İptal Nedeni',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _aciklamaCtrl,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'İptal nedeninizi açıklayın...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildDersBilgisi() {
    final baslangic = widget.ders.baslangicTarihSaat;
    final bitis = widget.ders.bitisTarihSaat;
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
          // Kort
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
                        widget.ders.kortAdi,
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

          // Dikey ayırıcı
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Saat
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
              'Katılımcı Durumları (${widget.ders.uyeList.length})',
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
          constraints:
              const BoxConstraints(maxHeight: 250), // 200'den 250'ye çıkardık
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
              children: widget.ders.uyeList.map((uye) {
                final teyit = widget.ders.getTeyitBilgisi(uye.id);
                return _buildUyeDurumChip(uye, teyit);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUyeDurumChip(UyeLiteModel uye, UyeTeyit? teyit) {
    // katilacakMi: null veya true → Katılması planlanıyor (yeşil)
    // katilacakMi: false → Katılmayacağını bildirdi (kırmızı)
    final katilacak = teyit?.katilacakMi ?? true;
    final color = katilacak ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = katilacak ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final durum =
        katilacak ? 'Katılması planlanıyor' : 'Katılmayacağını bildirdi';

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
                'İptal Talebini Geri Çek',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
    final hasText = _aciklamaCtrl.text.trim().isNotEmpty;

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
              onPressed: !hasText || _isSaving ? null : _talepGonder,
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
                      'İptal Talebi Gönder',
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
        sebep: 'ANTRENOR_IPTAL',
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
