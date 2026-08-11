// lib/screens/5_etkinlik/takvim/widgets/ders_degerlendirme_popup.dart

import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'takvim_constants.dart';

class DersDegerlendirmePopup extends StatefulWidget {
  final EtkinlikModel ders;
  final int userId;
  final VoidCallback onSuccess;

  const DersDegerlendirmePopup({
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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DersDegerlendirmePopup(
        ders: ders,
        userId: userId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<DersDegerlendirmePopup> createState() => _DersDegerlendirmePopupState();
}

class _DersDegerlendirmePopupState extends State<DersDegerlendirmePopup> {
  final _yorumController = TextEditingController();
  int _puan = 0;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _degerlendirmeVar = false;

  @override
  void initState() {
    super.initState();
    // *** İPTAL KONTROLÜ: İptal edilmiş derslerde değerlendirme yüklenmesin ***
    if (!widget.ders.iptalMi) {
      _loadMevcutDegerlendirme();
    } else {
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadMevcutDegerlendirme() async {
    try {
      final res = await TakvimService.getDersDegerlendirme(
        dersId: widget.ders.id,
        userId: widget.userId,
        rol: 'uye',
      );

      if (mounted && res.data != null) {
        final data = res.data!;
        setState(() {
          _puan = data['puan'] ?? 0;
          _yorumController.text = data['yorum'] ?? '';
          _degerlendirmeVar = _puan > 0;
          _isInitialLoading = false;
        });
      } else {
        setState(() => _isInitialLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  @override
  void dispose() {
    _yorumController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_puan == 0) {
      ShowMessage.error(context, 'Lütfen puan verin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await TakvimService.setDersDegerlendirme(
        dersId: widget.ders.id,
        userId: widget.userId,
        rol: 'uye',
        puan: _puan,
        yorum: _yorumController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ShowMessage.success(context, 'Değerlendirmeniz kaydedildi');
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ShowMessage.error(context, 'Bir hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.ders.iptalMi
                        ? Colors.red.withValues(alpha: 0.12)
                        : context.takvim.completed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.ders.iptalMi
                        ? Icons.cancel_rounded
                        : Icons.star_rounded,
                    color: widget.ders.iptalMi
                        ? Colors.red
                        : context.takvim.completed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ders.iptalMi
                            ? 'İptal Edilen Ders'
                            : (_degerlendirmeVar
                                ? 'Değerlendirmeniz'
                                : 'Dersi Değerlendir'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TimeUtils.formatDateFull(
                            widget.ders.baslangicTarihSaat),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // *** İPTAL KONTROLÜ: İptal edilmiş ders uyarısı ***
          if (widget.ders.iptalMi)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.red.shade700, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Bu ders iptal edildiği için değerlendirme yapılamaz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // İptali kimin yaptığı (ad soyad). Sistem/otomatik
                        // iptalde ad gelmez, satır da görünmez.
                        if ((widget.ders.iptalEdenAdi ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'İptal eden: ${widget.ders.iptalEdenAdi}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Kapat',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          // Normal değerlendirme içeriği
          else if (_isInitialLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    if (_degerlendirmeVar) ...[
                      _buildMevcutDegerlendirme(),
                      const SizedBox(height: 20),
                      _buildBilgilendirmeNotu(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                          ),
                          child: const Text('Kapat',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ] else ...[
                      _buildPuanlamaSection(),
                      const SizedBox(height: 20),
                      _buildYorumSection(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant),
                              ),
                              child: const Text('Vazgeç',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed:
                                  _isLoading || _puan == 0 ? null : _kaydet,
                              style: FilledButton.styleFrom(
                                backgroundColor: context.takvim.completed,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Kaydet',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.ders.iptalMi
            ? Theme.of(context).colorScheme.outlineVariant
            : context.takvim.completed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.ders.iptalMi
              ? Theme.of(context).colorScheme.outlineVariant
              : context.takvim.completed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.ders.iptalMi
                  ? Colors.red.withValues(alpha: 0.15)
                  : context.takvim.completed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.ders.iptalMi
                  ? Icons.cancel_rounded
                  : Icons.check_circle_rounded,
              color:
                  widget.ders.iptalMi ? Colors.red : context.takvim.completed,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ders.iptalMi ? 'İptal Edilen Ders' : 'Tamamlanan Ders',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: widget.ders.iptalMi
                        ? Colors.red
                        : context.takvim.completed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(widget.ders.kortAdi,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${TimeUtils.formatTime(widget.ders.baslangicTarihSaat)} - ${TimeUtils.formatTime(widget.ders.bitisTarihSaat)}',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (widget.ders.antrenorAdi != null) ...[
                  const SizedBox(height: 2),
                  Text(widget.ders.antrenorAdi!,
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMevcutDegerlendirme() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.takvim.pending.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: context.takvim.pending.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Puanınız',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < _puan ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 24,
                    color: i < _puan
                        ? context.takvim.pending
                        : Theme.of(context).colorScheme.outlineVariant,
                  );
                }),
              ),
            ],
          ),
          if (_yorumController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Yorumunuz',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Text(_yorumController.text,
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPuanlamaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Puanınız',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              final isSelected = starIndex <= _puan;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _puan = _puan == starIndex ? 0 : starIndex);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 44,
                    color: isSelected
                        ? context.takvim.pending
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildYorumSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Yorumunuz (İsteğe bağlı)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextField(
          controller: _yorumController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Ders hakkında düşüncelerinizi paylaşın...',
            hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: context.takvim.completed, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.10),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildBilgilendirmeNotu() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Değerlendirmeniz kaydedilmiştir. Değişiklik için kulüp ile iletişime geçiniz.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
