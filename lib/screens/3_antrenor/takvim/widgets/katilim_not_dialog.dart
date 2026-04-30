// lib/screens/3_antrenor/takvim/widgets/katilim_not_dialog.dart

import 'package:flutter/material.dart';

/// Plan dışı üye için not girişi.
/// - Pop value: yeni not metni (boş string = notu sil)
/// - Pop value: null = iptal
class KatilimNotDialog extends StatefulWidget {
  final String adSoyad;
  final String? baslangicNot;

  const KatilimNotDialog({
    super.key,
    required this.adSoyad,
    this.baslangicNot,
  });

  @override
  State<KatilimNotDialog> createState() => _KatilimNotDialogState();
}

class _KatilimNotDialogState extends State<KatilimNotDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.baslangicNot ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('${widget.adSoyad} — Not'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: 3,
        maxLength: 255,
        decoration: const InputDecoration(
          hintText: 'Örn. Misafir, telafi, deneme dersi...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // null = iptal
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
