// lib/screens/3_antrenor/takvim/widgets/misafir_ekle_sheet.dart

import 'package:fitcall/models/5_etkinlik/misafir_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'takvim_constants.dart';

/// Üye olmayan bir kişiyi derse eklemek için küçük form.
///
/// Yalnız ad soyad zorunlu — antrenör kortta, telefonuyla, ders biter bitmez
/// dolduruyor. Telefon ve diğer bilgiler serbest not alanına yazılır; yönetici
/// kişi sonradan üye olduğunda o notu görerek eşleştirme yapar.
///
/// [mevcut] doluysa düzenleme modunda açılır.
class MisafirEkleSheet extends StatefulWidget {
  final MisafirModel? mevcut;

  const MisafirEkleSheet({super.key, this.mevcut});

  static Future<MisafirModel?> goster(
    BuildContext context, {
    MisafirModel? mevcut,
  }) {
    return showModalBottomSheet<MisafirModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MisafirEkleSheet(mevcut: mevcut),
    );
  }

  @override
  State<MisafirEkleSheet> createState() => _MisafirEkleSheetState();
}

class _MisafirEkleSheetState extends State<MisafirEkleSheet> {
  late final TextEditingController _adCtrl;
  late final TextEditingController _notCtrl;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _adCtrl = TextEditingController(text: widget.mevcut?.adSoyad ?? '');
    _notCtrl = TextEditingController(text: widget.mevcut?.notMetni ?? '');
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _notCtrl.dispose();
    super.dispose();
  }

  void _kaydet() {
    final ad = _adCtrl.text.trim();
    if (ad.isEmpty) {
      setState(() => _hata = 'Ad soyad zorunludur');
      return;
    }
    HapticFeedback.lightImpact();
    Navigator.pop(
      context,
      MisafirModel(
        id: widget.mevcut?.id,
        adSoyad: ad,
        notMetni: _notCtrl.text.trim().isEmpty ? null : _notCtrl.text.trim(),
        kararVerildiMi: widget.mevcut?.kararVerildiMi ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duzenleme = widget.mevcut != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              duzenleme ? 'Misafiri düzenle' : 'Misafir ekle',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Sisteme kayıtlı olmayan kişi',
              style: TextStyle(
                fontSize: 13,
                color: context.takvim.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _adCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Ad soyad',
                hintText: 'Örn. Mehmet Kaya',
                errorText: _hata,
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                if (_hata != null) setState(() => _hata = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                hintText: 'Telefon, kimin misafiri olduğu...',
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
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
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _kaydet,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.takvim.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(duzenleme ? 'Güncelle' : 'Ekle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
