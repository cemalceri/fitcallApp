// lib/screens/7_yonetici/program/widgets/ders_iptal_dialog.dart
//
// Ders iptali: sebep + açıklama + mod seçimi.
// Web'deki ders_yonetimi ekranındaki iptal penceresinin karşılığı; aynı
// sebep listesi ve aynı 4 mod kullanılır (backend'de ortak servis işler).

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:flutter/material.dart';

class DersIptalSonucu {
  final String sebep;
  final String aciklama;
  final String mod;

  DersIptalSonucu({
    required this.sebep,
    required this.aciklama,
    required this.mod,
  });
}

class DersIptalDialog extends StatefulWidget {
  final List<SecenekKodAd> sebepler;
  final List<SecenekKodAd> modlar;
  final String dersOzeti;

  const DersIptalDialog({
    super.key,
    required this.sebepler,
    required this.modlar,
    required this.dersOzeti,
  });

  static Future<DersIptalSonucu?> ac(
    BuildContext context, {
    required List<SecenekKodAd> sebepler,
    required List<SecenekKodAd> modlar,
    required String dersOzeti,
  }) {
    return showModalBottomSheet<DersIptalSonucu>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DersIptalDialog(
        sebepler: sebepler,
        modlar: modlar,
        dersOzeti: dersOzeti,
      ),
    );
  }

  @override
  State<DersIptalDialog> createState() => _DersIptalDialogState();
}

class _DersIptalDialogState extends State<DersIptalDialog> {
  String? _sebep;
  String _mod = 'STANDART';
  final _aciklamaCtrl = TextEditingController();

  @override
  void dispose() {
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;

    return Padding(
      // Klavye açıldığında içerik yukarı kaysın, taşma olmasın
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, kaydirmaKontrol) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: renk.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: kaydirmaKontrol,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
                    Text(
                      'Dersi iptal et',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: renk.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.dersOzeti,
                      style:
                          TextStyle(fontSize: 13, color: renk.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    Text('İptal sebebi', style: _baslikStili(renk)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _sebep,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        hintText: 'Seçiniz',
                      ),
                      items: widget.sebepler
                          .map((s) => DropdownMenuItem(
                                value: s.kod,
                                child:
                                    Text(s.ad, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _sebep = v),
                    ),
                    const SizedBox(height: 16),
                    Text('Açıklama (opsiyonel)', style: _baslikStili(renk)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _aciklamaCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('İşlem şekli', style: _baslikStili(renk)),
                    const SizedBox(height: 6),
                    RadioGroup<String>(
                      groupValue: _mod,
                      onChanged: (v) => setState(() => _mod = v ?? 'STANDART'),
                      child: Column(
                        children: widget.modlar
                            .map(
                              (m) => RadioListTile<String>(
                                value: m.kod,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  m.ad,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: m.aciklama.isEmpty
                                    ? null
                                    : Text(m.aciklama,
                                        style: const TextStyle(fontSize: 12)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Vazgeç'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: renk.error,
                            foregroundColor: renk.onError,
                          ),
                          onPressed: _sebep == null
                              ? null
                              : () => Navigator.pop(
                                    context,
                                    DersIptalSonucu(
                                      sebep: _sebep!,
                                      aciklama: _aciklamaCtrl.text.trim(),
                                      mod: _mod,
                                    ),
                                  ),
                          child: const Text('Dersi iptal et'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  TextStyle _baslikStili(ColorScheme renk) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: renk.onSurfaceVariant,
      );
}
