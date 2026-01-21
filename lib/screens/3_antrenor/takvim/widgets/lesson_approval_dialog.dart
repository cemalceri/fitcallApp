// lib/screens/3_antrenor/takvim/widgets/lesson_approval_dialog.dart

import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'takvim_constants.dart';

class LessonApprovalDialog extends StatefulWidget {
  final EtkinlikModel ders;
  final int userId;
  final int? antrenorId; // Yeni parametre
  final VoidCallback onSuccess;

  const LessonApprovalDialog({
    super.key,
    required this.ders,
    required this.userId,
    this.antrenorId,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required EtkinlikModel ders,
    required int userId,
    int? antrenorId,
    required VoidCallback onSuccess,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LessonApprovalDialog(
        ders: ders,
        userId: userId,
        antrenorId: antrenorId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<LessonApprovalDialog> createState() => _LessonApprovalDialogState();
}

class _LessonApprovalDialogState extends State<LessonApprovalDialog> {
  bool _isSaving = false;

  // Mevcut onay bilgisi - artık ders modelinden alınıyor
  AntrenorOnay? get _mevcutOnay => widget.ders.antrenorOnayi;
  bool get _onayVerilmis => _mevcutOnay != null;

  // Yeni onay için
  String? _secilenDurum;
  String? _secilenNeden;
  final _aciklamaCtrl = TextEditingController();

  static const _yapildiNedenleri = [
    {'code': 'YPL_PLAN', 'label': 'Planlanan ders yapıldı'},
    {'code': 'YPL_TELAFI', 'label': 'Telafi dersi yapıldı'},
  ];

  static const _yapilmadiNedenleri = [
    {'code': 'YMD_OGRENCI', 'label': 'Öğrenci gelmedi'},
    {'code': 'YMD_ANTRENOR', 'label': 'Antrenör mazeretli'},
    {'code': 'YMD_HAVA', 'label': 'Hava şartları'},
    {'code': 'YMD_KORT', 'label': 'Kort müsait değil'},
    {'code': 'YMD_DIGER', 'label': 'Diğer'},
  ];

  @override
  void dispose() {
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  String _getNedenLabel(String? code, bool tamamlandi) {
    if (code == null) return '';
    final liste = tamamlandi ? _yapildiNedenleri : _yapilmadiNedenleri;
    final found = liste.where((n) => n['code'] == code).firstOrNull;
    return found?['label'] ?? code;
  }

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
        child: _onayVerilmis ? _buildOnayVerilmisView() : _buildOnayFormu(),
      ),
    );
  }

  /// Onay verilmişse - salt okunur görünüm
  Widget _buildOnayVerilmisView() {
    final onay = _mevcutOnay!;
    final katilimcilar = widget.ders.uyeList.map((u) => u.adSoyad).toList();
    final isYapildi = onay.tamamlandi;
    final statusColor =
        isYapildi ? TakvimColors.completed : TakvimColors.cancelled;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        _buildHeader(statusColor),

        // Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Katılımcılar
                if (katilimcilar.isNotEmpty) ...[
                  _buildKatilimcilar(katilimcilar),
                  const SizedBox(height: 20),
                ],

                // Onay durumu kartı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isYapildi
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: statusColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isYapildi ? 'Ders Yapıldı' : 'Ders Yapılmadı',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                                if (onay.onayRedIptalNedeni != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _getNedenLabel(
                                        onay.onayRedIptalNedeni, isYapildi),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: TakvimColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Açıklama varsa
                      if (onay.aciklama != null &&
                          onay.aciklama!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Açıklama',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: TakvimColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                onay.aciklama!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: TakvimColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Onay tarihi
                      if (onay.onayTarihi != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: TakvimColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Onay tarihi: ${_formatDateTime(onay.onayTarihi!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: TakvimColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Yönetici onay durumu
                _buildYoneticiOnayDurumu(),

                const SizedBox(height: 16),

                // Bilgi mesajı
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
                      Expanded(
                        child: Text(
                          'Onay bilgisi değiştirilemez. Değişiklik için yöneticinizle iletişime geçin.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
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

        // Actions
        _buildOnayVerilmisActions(),
      ],
    );
  }

  Widget _buildYoneticiOnayDurumu() {
    final yoneticiOnayi = widget.ders.yoneticiOnayi;
    final bool yoneticiOnayladi = yoneticiOnayi?.tamamlandi ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yoneticiOnayladi
            ? TakvimColors.completed.withValues(alpha: 0.08)
            : TakvimColors.pending.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: yoneticiOnayladi
              ? TakvimColors.completed.withValues(alpha: 0.3)
              : TakvimColors.pending.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: yoneticiOnayladi
                  ? TakvimColors.completed.withValues(alpha: 0.15)
                  : TakvimColors.pending.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              yoneticiOnayladi
                  ? Icons.verified_rounded
                  : Icons.hourglass_empty_rounded,
              color: yoneticiOnayladi
                  ? TakvimColors.completed
                  : TakvimColors.pending,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yönetici Onayı',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: yoneticiOnayladi
                        ? TakvimColors.completed
                        : TakvimColors.pending,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  yoneticiOnayladi ? 'Onaylandı' : 'Bekliyor',
                  style: TextStyle(
                    fontSize: 12,
                    color: TakvimColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            yoneticiOnayladi ? Icons.check_circle : Icons.schedule,
            color: yoneticiOnayladi
                ? TakvimColors.completed
                : TakvimColors.pending,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildOnayVerilmisActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: TakvimColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Tamam',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Onay formu - henüz onay verilmemişse
  Widget _buildOnayFormu() {
    final katilimcilar = widget.ders.uyeList.map((u) => u.adSoyad).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        _buildHeader(TakvimColors.primary),

        // Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Katılımcılar
                if (katilimcilar.isNotEmpty) ...[
                  _buildKatilimcilar(katilimcilar),
                  const SizedBox(height: 20),
                ],

                // Durum seçimi
                const Text(
                  'Ders durumu',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildDurumSecimi(),

                // Neden seçimi (durum seçiliyse)
                if (_secilenDurum != null) ...[
                  const SizedBox(height: 20),
                  _buildNedenSecimi(),
                ],

                // Açıklama
                if (_secilenDurum != null) ...[
                  const SizedBox(height: 16),
                  _buildAciklamaField(),
                ],
              ],
            ),
          ),
        ),

        // Actions
        _buildActions(),
      ],
    );
  }

  Widget _buildHeader(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.fact_check_rounded,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _onayVerilmis ? 'Ders Onayı' : 'Ders Onayı Ver',
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

  Widget _buildKatilimcilar(List<String> katilimcilar) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TakvimColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Katılımcılar',
            style: TextStyle(
              fontSize: 11,
              color: TakvimColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: katilimcilar
                .map((isim) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
        ],
      ),
    );
  }

  Widget _buildDurumSecimi() {
    return Column(
      children: [
        _DurumSecenegi(
          isSelected: _secilenDurum == 'yapildi',
          icon: Icons.check_circle_rounded,
          color: TakvimColors.completed,
          title: 'Ders yapıldı',
          subtitle: 'Ders planlandığı gibi gerçekleşti',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _secilenDurum = 'yapildi';
              _secilenNeden = 'YPL_PLAN';
            });
          },
        ),
        const SizedBox(height: 10),
        _DurumSecenegi(
          isSelected: _secilenDurum == 'yapilmadi',
          icon: Icons.cancel_rounded,
          color: TakvimColors.cancelled,
          title: 'Ders yapılmadı',
          subtitle: 'Ders gerçekleşmedi',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _secilenDurum = 'yapilmadi';
              _secilenNeden = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNedenSecimi() {
    final aktifListe =
        _secilenDurum == 'yapildi' ? _yapildiNedenleri : _yapilmadiNedenleri;
    final color = _secilenDurum == 'yapildi'
        ? TakvimColors.completed
        : TakvimColors.cancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _secilenDurum == 'yapildi' ? 'Detay' : 'Neden yapılmadı?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: TakvimColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: aktifListe.map((n) {
            final isSelected = _secilenNeden == n['code'];
            return ChoiceChip(
              label: Text(n['label']!),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _secilenNeden = n['code']);
              },
              selectedColor: color.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAciklamaField() {
    return TextField(
      controller: _aciklamaCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Açıklama (isteğe bağlı)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildActions() {
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
                  _secilenDurum == null || _secilenNeden == null || _isSaving
                      ? null
                      : _kaydet,
              style: FilledButton.styleFrom(
                backgroundColor: TakvimColors.primary,
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Kaydet',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _kaydet() async {
    setState(() => _isSaving = true);

    try {
      await TakvimService.setDersOnayBilgisi(
        dersId: widget.ders.id,
        userId: widget.userId,
        rol: 'antrenor',
        tamamlandi: _secilenDurum == 'yapildi',
        aciklama: _aciklamaCtrl.text.trim(),
        onayRedIptalNedeni: _secilenNeden,
      );

      if (mounted) {
        Navigator.pop(context);
        ShowMessage.success(context, 'Ders onayı kaydedildi');
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

class _DurumSecenegi extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DurumSecenegi({
    required this.isSelected,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: TakvimColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
