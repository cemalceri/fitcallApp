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
    _loadMevcutDegerlendirme();
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
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
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
      if (mounted) {
        ShowMessage.error(context, e.message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ShowMessage.error(context, 'Bir hata oluştu: $e');
      }
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
              color: Colors.grey.shade300,
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
                    color: TakvimColors.completed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: TakvimColors.completed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _degerlendirmeVar
                            ? 'Değerlendirmeniz'
                            : 'Dersi Değerlendir',
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

          // İçerik
          if (_isInitialLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ders Bilgileri
                    _buildInfoCard(),

                    const SizedBox(height: 24),

                    // Salt okunur mod (değerlendirme varsa)
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Kapat',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Puanlama
                      _buildPuanlamaSection(),

                      const SizedBox(height: 20),

                      // Yorum
                      _buildYorumSection(),

                      const SizedBox(height: 24),

                      // Butonlar
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: const Text(
                                'Vazgeç',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed:
                                  _isLoading || _puan == 0 ? null : _kaydet,
                              style: FilledButton.styleFrom(
                                backgroundColor: TakvimColors.completed,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Kaydet',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
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
        color: TakvimColors.completed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TakvimColors.completed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TakvimColors.completed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: TakvimColors.completed,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tamamlanan Ders',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: TakvimColors.completed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.ders.kortAdi,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${TimeUtils.formatTime(widget.ders.baslangicTarihSaat)} - ${TimeUtils.formatTime(widget.ders.bitisTarihSaat)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (widget.ders.antrenorAdi != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.ders.antrenorAdi!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
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
        color: TakvimColors.pending.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TakvimColors.pending.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Puanınız',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < _puan ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 24,
                    color:
                        i < _puan ? TakvimColors.pending : Colors.grey.shade300,
                  );
                }),
              ),
            ],
          ),
          if (_yorumController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Yorumunuz',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _yorumController.text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
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
        const Text(
          'Puanınız',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              final isSelected = starIndex <= _puan;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _puan = _puan == starIndex ? 0 : starIndex;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 44,
                    color: isSelected
                        ? TakvimColors.pending
                        : Colors.grey.shade300,
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
        const Text(
          'Yorumunuz (İsteğe bağlı)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _yorumController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Ders hakkında düşüncelerinizi paylaşın...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: TakvimColors.completed,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
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
        color: Colors.blue.shade50,
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
